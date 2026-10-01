"""
Django Channels WebSocket Consumer for Skribbl Clone.
Implements the real-time event contract, room channels, and drawing synchronization.
"""
import json
import asyncio
import logging
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from game.game_manager import game_manager, GamePhase

logger = logging.getLogger(__name__)

class GameConsumer(AsyncJsonWebsocketConsumer):
    # Active timer tasks per room
    room_timers = {}

    async def connect(self):
        self.room_code = self.scope['url_route']['kwargs'].get('room_code', '').upper()
        self.player_id = None
        self.player_name = None
        self.room_group_name = None

        await self.accept()

    async def disconnect(self, close_code):
        if self.room_group_name and self.room_code:
            room = game_manager.get_room(self.room_code)
            if room and self.player_id:
                new_host_id = room.remove_player(self.player_id)
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "broadcast_event",
                        "event": {
                            "type": "player_left",
                            "roomId": self.room_code,
                            "payload": {
                                "playerId": self.player_id,
                                "playerName": self.player_name,
                                "newHostId": new_host_id,
                                "players": [p.to_dict() for p in room.players.values()]
                            }
                        }
                    }
                )
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive_json(self, content):
        event_type = content.get("type")
        payload = content.get("payload", {})
        room_code = content.get("roomId", self.room_code).upper()

        if not self.room_code and room_code:
            self.room_code = room_code

        # Dispatch
        handler = getattr(self, f"handle_{event_type}", None)
        if handler:
            await handler(payload)
        else:
            await self.send_json({
                "type": "error",
                "message": f"Unknown event type: {event_type}"
            })

    async def handle_join_room(self, payload):
        self.room_code = payload.get("roomCode", self.room_code).upper()
        self.player_id = payload.get("playerId")
        self.player_name = payload.get("playerName", "Guest")
        avatar = payload.get("avatar", "🎨")

        room = game_manager.get_room(self.room_code)
        if not room:
            await self.send_json({"type": "error", "message": "Room not found"})
            return

        self.room_group_name = f"room_{self.room_code}"
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)

        player = room.add_player(self.player_id, self.player_name, avatar=avatar)

        # Notify room
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "broadcast_event",
                "event": {
                    "type": "player_joined",
                    "roomId": self.room_code,
                    "payload": {
                        "player": player.to_dict(),
                        "players": [p.to_dict() for p in room.players.values()]
                    }
                }
            }
        )

        # Send full initial state to this specific player
        await self.send_json({
            "type": "game_state",
            "roomId": self.room_code,
            "payload": room.get_public_state(for_player_id=self.player_id)
        })

    async def handle_start_game(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room:
            return
        if self.player_id != room.host_id:
            await self.send_json({"type": "error", "message": "Only the host can start the game"})
            return

        success = room.start_game(self.player_id)
        if not success:
            await self.send_json({"type": "error", "message": "Need at least 2 players to start"})
            return

        # Start room timer loop if not already running
        if self.room_code not in GameConsumer.room_timers:
            GameConsumer.room_timers[self.room_code] = asyncio.create_task(
                self.run_room_timer(self.room_code, self.room_group_name)
            )

        await self.broadcast_game_state(room)

    async def handle_word_chosen(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room:
            return
        chosen_word = payload.get("word")
        if room.select_word(self.player_id, chosen_word):
            await self.broadcast_game_state(room)

    async def handle_draw_start(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room or self.player_id != room.current_drawer_id or room.phase != GamePhase.DRAWING:
            return

        event_data = {
            "type": "draw_start",
            "x": payload.get("x"),
            "y": payload.get("y"),
            "color": payload.get("color", "#000000"),
            "size": payload.get("size", 4)
        }
        room.add_stroke(self.player_id, event_data)

        # Broadcast to room (including drawer for consistency)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "broadcast_event",
                "event": {
                    "type": "draw_start",
                    "roomId": self.room_code,
                    "payload": event_data
                }
            }
        )

    async def handle_draw_move(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room or self.player_id != room.current_drawer_id or room.phase != GamePhase.DRAWING:
            return

        event_data = {
            "type": "draw_move",
            "x": payload.get("x"),
            "y": payload.get("y")
        }
        room.add_stroke(self.player_id, event_data)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "broadcast_event",
                "event": {
                    "type": "draw_move",
                    "roomId": self.room_code,
                    "payload": event_data
                }
            }
        )

    async def handle_draw_end(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room or self.player_id != room.current_drawer_id or room.phase != GamePhase.DRAWING:
            return

        event_data = {"type": "draw_end"}
        room.add_stroke(self.player_id, event_data)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "broadcast_event",
                "event": {
                    "type": "draw_end",
                    "roomId": self.room_code,
                    "payload": event_data
                }
            }
        )

    async def handle_canvas_clear(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room or self.player_id != room.current_drawer_id:
            return
        if room.clear_canvas(self.player_id):
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "broadcast_event",
                    "event": {
                        "type": "canvas_clear",
                        "roomId": self.room_code,
                        "payload": {}
                    }
                }
            )

    async def handle_draw_undo(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room or self.player_id != room.current_drawer_id:
            return
        if room.undo_stroke(self.player_id):
            # Send updated full stroke history for clean redraw
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "broadcast_event",
                    "event": {
                        "type": "draw_undo",
                        "roomId": self.room_code,
                        "payload": {"strokes": room.strokes}
                    }
                }
            )

    async def handle_guess(self, payload):
        room = game_manager.get_room(self.room_code)
        if not room:
            return
        guess_text = payload.get("text", "")
        res = room.process_guess(self.player_id, guess_text)

        status = res.get("status")
        if status == "correct":
            # Correct guess
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "broadcast_event",
                    "event": {
                        "type": "guess_result",
                        "roomId": self.room_code,
                        "payload": {
                            "status": "correct",
                            "playerId": self.player_id,
                            "playerName": self.player_name,
                            "points": res.get("points"),
                            "players": [p.to_dict() for p in room.get_ranked_players()]
                        }
                    }
                }
            )
            # If all guessed or round finished
            if res.get("allGuessed"):
                room.end_turn()
                await self.broadcast_game_state(room)

        elif status == "close":
            # Send private hint to this player only
            await self.send_json({
                "type": "guess_result",
                "roomId": self.room_code,
                "payload": {
                    "status": "close",
                    "message": f"'{guess_text}' is very close!"
                }
            })
            # Also broadcast as a chat message so everyone sees what they guessed
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "broadcast_event",
                    "event": {
                        "type": "chat_message",
                        "roomId": self.room_code,
                        "payload": {
                            "playerId": self.player_id,
                            "playerName": self.player_name,
                            "text": guess_text
                        }
                    }
                }
            )
        elif status == "wrong":
            # Normal incorrect guess -> broadcast to chat
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "broadcast_event",
                    "event": {
                        "type": "chat_message",
                        "roomId": self.room_code,
                        "payload": {
                            "playerId": self.player_id,
                            "playerName": self.player_name,
                            "text": guess_text
                        }
                    }
                }
            )

    async def handle_chat_message(self, payload):
        text = payload.get("text", "").strip()
        if not text:
            return
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "broadcast_event",
                "event": {
                    "type": "chat_message",
                    "roomId": self.room_code,
                    "payload": {
                        "playerId": self.player_id,
                        "playerName": self.player_name,
                        "text": text
                    }
                }
            }
        )

    async def broadcast_event(self, event):
        # Raw event passing through group
        await self.send_json(event["event"])

    async def broadcast_game_state(self, room):
        # Send personalized state (masked vs secret word)
        for pid in room.players.keys():
            # For Channels, we send general state
            pass
        # Send general state to group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "send_individual_state",
                "roomId": room.code
            }
        )

    async def send_individual_state(self, event):
        room = game_manager.get_room(event["roomId"])
        if room:
            await self.send_json({
                "type": "game_state",
                "roomId": room.code,
                "payload": room.get_public_state(for_player_id=self.player_id)
            })

    async def run_room_timer(self, room_code: str, group_name: str):
        """
        Background loop ticking every 1 second while room is active.
        """
        try:
            while True:
                await asyncio.sleep(1.0)
                room = game_manager.get_room(room_code)
                if not room:
                    break

                if room.phase in (GamePhase.WORD_CHOICE, GamePhase.DRAWING):
                    updates = room.tick()
                    if updates:
                        # Broadcast timer tick or phase change
                        await self.channel_layer.group_send(
                            group_name,
                            {
                                "type": "broadcast_event",
                                "event": {
                                    "type": "timer_tick",
                                    "roomId": room_code,
                                    "payload": {
                                        "remainingTime": room.remaining_time,
                                        "choiceTimeRemaining": room.choice_time_remaining,
                                        "maskedWord": room.get_masked_word(),
                                        "phase": room.phase
                                    }
                                }
                            }
                        )

                        if updates.get("turn_ended") or updates.get("word_chosen"):
                            await self.channel_layer.group_send(
                                group_name,
                                {
                                    "type": "send_individual_state",
                                    "roomId": room.code
                                }
                            )

                elif room.phase == GamePhase.ROUND_RESULT:
                    # Hold round result for 5 seconds, then advance to next turn
                    await asyncio.sleep(5.0)
                    room = game_manager.get_room(room_code)
                    if room and room.phase == GamePhase.ROUND_RESULT:
                        room.start_next_turn()
                        await self.channel_layer.group_send(
                            group_name,
                            {
                                "type": "send_individual_state",
                                "roomId": room.code
                            }
                        )
                elif room.phase == GamePhase.GAME_OVER:
                    # Game finished
                    break
        except asyncio.CancelledError:
            pass
        finally:
            GameConsumer.room_timers.pop(room_code, None)
