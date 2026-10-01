from django.db import models

class Room(models.Model):
    """
    Authoritative Room persistence model in SQLite via Django ORM.
    """
    code = models.CharField(max_length=10, unique=True, db_index=True)
    host_id = models.CharField(max_length=64)
    host_name = models.CharField(max_length=50)
    max_players = models.IntegerField(default=8)
    rounds = models.IntegerField(default=3)
    draw_time = models.IntegerField(default=60)
    word_choices = models.IntegerField(default=3)
    hints_enabled = models.BooleanField(default=True)
    is_private = models.BooleanField(default=False)
    category = models.CharField(max_length=50, default="all")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"Room {self.code} (Host: {self.host_name})"

class GameSession(models.Model):
    """
    Completed game session history persisted in SQLite.
    """
    room_code = models.CharField(max_length=10, db_index=True)
    total_rounds = models.IntegerField(default=3)
    winner_name = models.CharField(max_length=50, blank=True, null=True)
    winner_score = models.IntegerField(default=0)
    winner_avatar = models.CharField(max_length=20, default="🎨")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"GameSession {self.room_code} (Winner: {self.winner_name})"

class SessionScore(models.Model):
    """
    Individual player score records per session in SQLite.
    """
    session = models.ForeignKey(GameSession, on_delete=models.CASCADE, related_name="scores")
    player_id = models.CharField(max_length=64)
    player_name = models.CharField(max_length=50)
    score = models.IntegerField(default=0)
    avatar = models.CharField(max_length=20, default="🎨")
    rank = models.IntegerField(default=1)

    def __str__(self):
        return f"{self.player_name}: {self.score} pts (Rank #{self.rank})"
