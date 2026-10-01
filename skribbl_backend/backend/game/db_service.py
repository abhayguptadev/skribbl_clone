"""
SQLite Data Access Layer for Skribbl Clone using Django ORM.
Persists rooms, game sessions, word banks, and leaderboard history into SQLite.
"""
import logging
from typing import Dict, Any, Optional, List

logger = logging.getLogger(__name__)

class SQLiteService:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(SQLiteService, cls).__new__(cls)
            cls._instance._init_service()
        return cls._instance

    def _init_service(self):
        self._memory_rooms = {}
        self._memory_games = []

    # Room operations via Django ORM
    def save_room(self, room_data: Dict[str, Any]) -> bool:
        code = room_data.get("code")
        if not code:
            return False

        try:
            from rooms.models import Room
            settings = room_data.get("settings", {})
            Room.objects.update_or_create(
                code=code,
                defaults={
                    "host_id": room_data.get("host_id", ""),
                    "host_name": room_data.get("host", ""),
                    "max_players": settings.get("maxPlayers", 8),
                    "rounds": settings.get("rounds", 3),
                    "draw_time": settings.get("drawTime", 60),
                    "word_choices": settings.get("wordChoices", 3),
                    "hints_enabled": settings.get("hintsEnabled", True),
                    "is_private": settings.get("isPrivate", False),
                    "category": settings.get("category", "all"),
                    "is_active": True,
                }
            )
            return True
        except Exception as e:
            logger.warning(f"Django ORM save room fallback to memory ({e})")
            self._memory_rooms[code] = dict(room_data)
            return True

    def get_room(self, code: str) -> Optional[Dict[str, Any]]:
        code = code.upper()
        try:
            from rooms.models import Room
            room = Room.objects.filter(code=code, is_active=True).first()
            if room:
                return {
                    "code": room.code,
                    "host_id": room.host_id,
                    "host": room.host_name,
                    "settings": {
                        "maxPlayers": room.max_players,
                        "rounds": room.rounds,
                        "drawTime": room.draw_time,
                        "wordChoices": room.word_choices,
                        "hintsEnabled": room.hints_enabled,
                        "isPrivate": room.is_private,
                        "category": room.category,
                    },
                    "created_at": room.created_at.isoformat(),
                }
        except Exception as e:
            logger.warning(f"Django ORM get room fallback to memory ({e})")
        return self._memory_rooms.get(code)

    def delete_room(self, code: str) -> bool:
        code = code.upper()
        try:
            from rooms.models import Room
            Room.objects.filter(code=code).update(is_active=False)
        except Exception as e:
            logger.warning(f"Django ORM delete room fallback to memory ({e})")
        self._memory_rooms.pop(code, None)
        return True

    # Game Session History via Django ORM
    def record_game_session(self, session_data: Dict[str, Any]) -> bool:
        try:
            from rooms.models import GameSession, SessionScore
            winner = session_data.get("winner") or {}
            session = GameSession.objects.create(
                room_code=session_data.get("room_code", ""),
                total_rounds=session_data.get("total_rounds", 3),
                winner_name=winner.get("name", "Unknown"),
                winner_score=winner.get("score", 0),
                winner_avatar=winner.get("avatar", "🎨"),
            )
            for idx, p in enumerate(session_data.get("final_scores", [])):
                SessionScore.objects.create(
                    session=session,
                    player_id=p.get("id", ""),
                    player_name=p.get("name", "Player"),
                    score=p.get("score", 0),
                    avatar=p.get("avatar", "🎨"),
                    rank=idx + 1,
                )
            return True
        except Exception as e:
            logger.warning(f"Django ORM record session fallback to memory ({e})")
            self._memory_games.append(session_data)
            return True

    def get_recent_games(self, limit: int = 10) -> List[Dict[str, Any]]:
        try:
            from rooms.models import GameSession
            sessions = GameSession.objects.order_by("-created_at")[:limit]
            results = []
            for s in sessions:
                scores = [
                    {"name": sc.player_name, "score": sc.score, "rank": sc.rank, "avatar": sc.avatar}
                    for sc in s.scores.all()
                ]
                results.append({
                    "room_code": s.room_code,
                    "total_rounds": s.total_rounds,
                    "winner_name": s.winner_name,
                    "winner_score": s.winner_score,
                    "created_at": s.created_at.isoformat(),
                    "scores": scores,
                })
            return results
        except Exception as e:
            logger.warning(f"Django ORM get games fallback to memory ({e})")
            return list(reversed(self._memory_games[-limit:]))

db_service = SQLiteService()
