"""
Scoring Manager for Skribbl Clone.
Computes authoritative points for guessers and drawers based on elapsed time and round settings.
"""
from typing import Dict, Any

class ScoringManager:
    BASE_POINTS = 100
    MAX_SPEED_BONUS = 400
    DRAWER_BONUS_PER_GUESS = 50

    @classmethod
    def calculate_guesser_score(cls, remaining_seconds: int, total_seconds: int, guess_rank: int) -> int:
        """
        Calculates points awarded to a guesser.
        Higher points for faster guesses.
        """
        if total_seconds <= 0:
            return cls.BASE_POINTS

        time_ratio = max(0.0, min(1.0, remaining_seconds / float(total_seconds)))
        speed_bonus = int(cls.MAX_SPEED_BONUS * time_ratio)
        
        # Rank bonus (1st guesser gets extra, 2nd gets slightly less)
        rank_bonus = max(0, 50 - (guess_rank - 1) * 15)
        
        total = cls.BASE_POINTS + speed_bonus + rank_bonus
        return max(50, total)

    @classmethod
    def calculate_drawer_score(cls, correct_guess_count: int, total_eligible_guessers: int) -> int:
        """
        Calculates bonus score awarded to the drawer at the end of the round.
        """
        if total_eligible_guessers <= 0:
            return 0
        ratio = correct_guess_count / float(total_eligible_guessers)
        base = correct_guess_count * cls.DRAWER_BONUS_PER_GUESS
        completion_bonus = 100 if ratio == 1.0 else 0
        return base + completion_bonus
