"""
Authoritative Game Engine for Skribbl Clone.
Encapsulates state transitions, turn rotations, word guessing, timers, and scoring.
"""
import time
import math
from typing import Dict, List, Optional, Any, Set
from .word_manager import WordManager
from .scoring import ScoringManager
from .db_service import db_service

class Player:
    def __init__(self, player_id: str, name: str, is_host: bool = False, avatar: str = "🦊"):
        self.id = player_id
        self.name = name
        self.score = 0
        self.round_score = 0
        self.is_host = is_host
        self.is_connected = True
        self.is_ready = True
        self.has_guessed = False
        self.avatar = avatar
        self.joined_at = time.time()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "score": self.score,
            "roundScore": self.round_score,
            "isHost": self.is_host,
            "isConnected": self.is_connected,
            "isReady": self.is_ready,
            "hasGuessed": self.has_guessed,
            "avatar": self.avatar
        }

class GamePhase:
    LOBBY = "lobby"
    WORD_CHOICE = "word_choice"
    DRAWING = "drawing"
    ROUND_RESULT = "round_result"
    GAME_OVER = "game_over"

class RoomSettings:
    def __init__(self, data: Optional[Dict[str, Any]] = None):
        data = data or {}
        self.max_players = max(2, min(20, int(data.get("maxPlayers", 8))))
        self.total_rounds = max(2, min(10, int(data.get("rounds", 3))))
        self.draw_time = max(15, min(240, int(data.get("drawTime", 60))))
        self.word_choices_count = max(1, min(5, int(data.get("wordChoices", 3))))
        self.hints_enabled = bool(data.get("hintsEnabled", True))
        self.is_private = bool(data.get("isPrivate", False))
        self.custom_words = [w.strip() for w in data.get("customWords", []) if w.strip()]
        self.category = data.get("category", "all")

    def to_dict(self) -> Dict[str, Any]:
        return {
            "maxPlayers": self.max_players,
            "rounds": self.total_rounds,
            "drawTime": self.draw_time,
            "wordChoices": self.word_choices_count,
            "hintsEnabled": self.hints_enabled,
            "isPrivate": self.is_private,
            "customWords": self.custom_words,
            "category": self.category
        }

class GameRoom:
    def __init__(self, room_code: str, host_id: str, host_name: str, settings: Optional[RoomSettings] = None):
        self.code = room_code.upper()
        self.host_id = host_id
        self.settings = settings or RoomSettings()
        self.players: Dict[str, Player] = {}
        self.phase = GamePhase.LOBBY
        self.current_round = 1
        self.turn_order: List[str] = []
        self.current_turn_index = 0
        self.current_drawer_id: Optional[str] = None
        self.current_word: str = ""
        self.word_choices: List[str] = []
        self.revealed_indices: Set[int] = set()
        self.remaining_time = self.settings.draw_time
        self.choice_time_remaining = 15
        self.strokes: List[Dict[str, Any]] = []
        self.correct_guesser_ids: List[str] = []
        self.created_at = time.time()
        self.last_activity = time.time()

        # Add initial host player
        self.add_player(host_id, host_name, is_host=True)

    def add_player(self, player_id: str, name: str, is_host: bool = False, avatar: str = "🎨") -> Optional[Player]:
        if len(self.players) >= self.settings.max_players and player_id not in self.players:
            return None
        
        if player_id in self.players:
            p = self.players[player_id]
            p.name = name
            p.is_connected = True
            return p

        p = Player(player_id, name, is_host=is_host, avatar=avatar)
        self.players[player_id] = p
        self.last_activity = time.time()
        return p

    def remove_player(self, player_id: str) -> Optional[str]:
        """
        Marks player disconnected or removes from turn order.
        If host left, transfers host role to the next active player.
        """
        if player_id not in self.players:
            return None
        
        self.players[player_id].is_connected = False
        new_host_id = None
        if player_id == self.host_id:
            # Transfer host
            active_players = [pid for pid, p in self.players.items() if p.is_connected and pid != player_id]
            if active_players:
                self.host_id = active_players[0]
                self.players[self.host_id].is_host = True
                new_host_id = self.host_id

        # If drawer disconnected during drawing, skip to next turn
        if self.current_drawer_id == player_id and self.phase in (GamePhase.WORD_CHOICE, GamePhase.DRAWING):
            self.end_turn()

        return new_host_id

    def start_game(self, requester_id: str) -> bool:
        if requester_id != self.host_id:
            return False
        active_players = [p for p in self.players.values() if p.is_connected]
        if len(active_players) < 2:
            return False
        
        # Reset game variables
        for p in self.players.values():
            p.score = 0
            p.round_score = 0
            p.has_guessed = False

        self.current_round = 1
        self.turn_order = [p.id for p in active_players]
        self.current_turn_index = 0
        self.start_next_turn()
        return True

    def start_next_turn(self):
        """
        Rotates to next drawer and presents word choices.
        """
        if self.current_turn_index >= len(self.turn_order):
            # Advance round
            self.current_round += 1
            if self.current_round > self.settings.total_rounds:
                self.finish_game()
                return
            self.current_turn_index = 0

        self.current_drawer_id = self.turn_order[self.current_turn_index]
        drawer = self.players.get(self.current_drawer_id)
        if not drawer or not drawer.is_connected:
            # Skip disconnected player
            self.current_turn_index += 1
            self.start_next_turn()
            return

        self.phase = GamePhase.WORD_CHOICE
        self.strokes = []
        self.correct_guesser_ids = []
        self.revealed_indices = set()
        self.choice_time_remaining = 15
        for p in self.players.values():
            p.has_guessed = False
            p.round_score = 0

        # Generate word options
        self.word_choices = WordManager.get_word_choices(
            count=self.settings.word_choices_count,
            category=self.settings.category,
            custom_words=self.settings.custom_words
        )

    def select_word(self, drawer_id: str, chosen_word: str) -> bool:
        if self.phase != GamePhase.WORD_CHOICE or drawer_id != self.current_drawer_id:
            return False
        if chosen_word not in self.word_choices and self.word_choices:
            chosen_word = self.word_choices[0]

        self.current_word = chosen_word.strip().lower()
        self.phase = GamePhase.DRAWING
        self.remaining_time = self.settings.draw_time
        self.revealed_indices = set()
        return True

    def auto_select_word(self):
        """Called if drawer does not select in time."""
        if self.word_choices:
            self.select_word(self.current_drawer_id, self.word_choices[0])

    def add_stroke(self, drawer_id: str, stroke: Dict[str, Any]) -> bool:
        if self.phase != GamePhase.DRAWING or drawer_id != self.current_drawer_id:
            return False
        self.strokes.append(stroke)
        return True

    def undo_stroke(self, drawer_id: str) -> bool:
        if self.phase != GamePhase.DRAWING or drawer_id != self.current_drawer_id:
            return False
        # Remove strokes up to the last stroke start
        if not self.strokes:
            return False
        
        # Pop back to previous draw_start
        while self.strokes:
            popped = self.strokes.pop()
            if popped.get("type") == "draw_start" or popped.get("isStart"):
                break
        return True

    def clear_canvas(self, drawer_id: str) -> bool:
        if self.phase != GamePhase.DRAWING or drawer_id != self.current_drawer_id:
            return False
        self.strokes = []
        return True

    def process_guess(self, player_id: str, guess_text: str) -> Dict[str, Any]:
        """
        Validates guess against current_word.
        Returns dict with status: 'correct', 'close', or 'wrong'.
        """
        if self.phase != GamePhase.DRAWING:
            return {"status": "ignored"}
        if player_id == self.current_drawer_id:
            return {"status": "drawer_cannot_guess"}
        
        player = self.players.get(player_id)
        if not player or player.has_guessed:
            return {"status": "already_guessed"}

        normalized_guess = guess_text.strip().lower()
        if not normalized_guess:
            return {"status": "empty"}

        if normalized_guess == self.current_word:
            # Correct!
            player.has_guessed = True
            self.correct_guesser_ids.append(player_id)
            rank = len(self.correct_guesser_ids)
            points = ScoringManager.calculate_guesser_score(
                remaining_seconds=self.remaining_time,
                total_seconds=self.settings.draw_time,
                guess_rank=rank
            )
            player.score += points
            player.round_score = points

            # Check if all eligible guessers have guessed
            eligible_count = len([p for p in self.players.values() if p.is_connected and p.id != self.current_drawer_id])
            all_guessed = len(self.correct_guesser_ids) >= eligible_count

            return {
                "status": "correct",
                "points": points,
                "player": player.to_dict(),
                "allGuessed": all_guessed
            }

        if WordManager.is_close_guess(normalized_guess, self.current_word):
            return {
                "status": "close",
                "text": guess_text
            }

        return {
            "status": "wrong",
            "text": guess_text
        }

    def tick(self) -> Dict[str, Any]:
        """
        Advances timer by 1 second.
        Returns events/updates to broadcast.
        """
        updates = {}
        if self.phase == GamePhase.WORD_CHOICE:
            self.choice_time_remaining -= 1
            if self.choice_time_remaining <= 0:
                self.auto_select_word()
                updates["word_chosen"] = True
            updates["choice_time"] = self.choice_time_remaining

        elif self.phase == GamePhase.DRAWING:
            self.remaining_time -= 1
            updates["timer"] = self.remaining_time

            # Progressive hint reveal
            if self.settings.hints_enabled and len(self.current_word) > 2:
                time_ratio = self.remaining_time / float(self.settings.draw_time)
                # Reveal first hint at 60% time, second hint at 30% time
                if time_ratio <= 0.60 and len(self.revealed_indices) == 0:
                    new_idx = WordManager.get_next_hint(self.current_word, self.revealed_indices)
                    if new_idx is not None:
                        self.revealed_indices.add(new_idx)
                        updates["hint_revealed"] = True
                elif time_ratio <= 0.30 and len(self.revealed_indices) == 1:
                    new_idx = WordManager.get_next_hint(self.current_word, self.revealed_indices)
                    if new_idx is not None:
                        self.revealed_indices.add(new_idx)
                        updates["hint_revealed"] = True

            # If time is up or all eligible players guessed, end turn
            eligible_count = len([p for p in self.players.values() if p.is_connected and p.id != self.current_drawer_id])
            if self.remaining_time <= 0 or (eligible_count > 0 and len(self.correct_guesser_ids) >= eligible_count):
                self.end_turn()
                updates["turn_ended"] = True

        return updates

    def end_turn(self):
        """
        Calculates drawer score and transitions to ROUND_RESULT.
        """
        self.phase = GamePhase.ROUND_RESULT
        eligible_count = len([p for p in self.players.values() if p.is_connected and p.id != self.current_drawer_id])
        drawer_points = ScoringManager.calculate_drawer_score(
            correct_guess_count=len(self.correct_guesser_ids),
            total_eligible_guessers=eligible_count
        )
        if self.current_drawer_id and self.current_drawer_id in self.players:
            self.players[self.current_drawer_id].score += drawer_points
            self.players[self.current_drawer_id].round_score = drawer_points

        # Advance turn index
        self.current_turn_index += 1

    def finish_game(self):
        self.phase = GamePhase.GAME_OVER
        # Save session to SQLite
        session_data = {
            "room_code": self.code,
            "total_rounds": self.settings.total_rounds,
            "final_scores": [p.to_dict() for p in self.get_ranked_players()],
            "winner": self.get_ranked_players()[0].to_dict() if self.players else None
        }
        db_service.record_game_session(session_data)

    def get_ranked_players(self) -> List[Player]:
        return sorted(self.players.values(), key=lambda p: p.score, reverse=True)

    def get_masked_word(self) -> str:
        if not self.current_word:
            return ""
        return WordManager.mask_word(self.current_word, self.revealed_indices)

    def get_public_state(self, for_player_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Security: Never reveal the current_word to non-drawers unless round_result or game_over!
        """
        is_drawer = (for_player_id == self.current_drawer_id)
        word_display = self.get_masked_word()

        if self.phase in (GamePhase.ROUND_RESULT, GamePhase.GAME_OVER) or is_drawer:
            revealed_word = self.current_word
        else:
            revealed_word = None

        state = {
            "roomId": self.code,
            "phase": self.phase,
            "hostId": self.host_id,
            "round": self.current_round,
            "totalRounds": self.settings.total_rounds,
            "currentDrawerId": self.current_drawer_id,
            "currentDrawerName": self.players[self.current_drawer_id].name if self.current_drawer_id and self.current_drawer_id in self.players else None,
            "remainingTime": self.remaining_time,
            "choiceTimeRemaining": self.choice_time_remaining,
            "maskedWord": word_display,
            "revealedWord": revealed_word,
            "settings": self.settings.to_dict(),
            "players": [p.to_dict() for p in self.get_ranked_players()],
            "correctGuessers": self.correct_guesser_ids,
            "strokesCount": len(self.strokes)
        }

        # Send word choices ONLY if the requester is the drawer in WORD_CHOICE phase
        if is_drawer and self.phase == GamePhase.WORD_CHOICE:
            state["wordChoices"] = self.word_choices

        return state

class GameManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(GameManager, cls).__new__(cls)
            cls._instance.rooms = {}
        return cls._instance

    def create_room(self, host_id: str, host_name: str, settings_dict: Optional[Dict[str, Any]] = None, room_code: Optional[str] = None) -> GameRoom:
        import string
        import random
        if not room_code:
            chars = string.ascii_uppercase + string.digits
            room_code = "".join(random.choices(chars, k=6))
        
        settings = RoomSettings(settings_dict)
        room = GameRoom(room_code=room_code, host_id=host_id, host_name=host_name, settings=settings)
        self.rooms[room.code] = room
        db_service.save_room({"code": room.code, "host": host_name, "settings": settings.to_dict()})
        return room

    def get_room(self, room_code: str) -> Optional[GameRoom]:
        return self.rooms.get(room_code.upper())

    def delete_room(self, room_code: str):
        self.rooms.pop(room_code.upper(), None)
        db_service.delete_room(room_code.upper())

game_manager = GameManager()
