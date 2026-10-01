"""
Word Manager for Skribbl Clone.
Provides categorized word pools, masked hints, and fuzzy close-guess detection.
"""
import random
from typing import List, Dict, Optional

WORD_BANKS: Dict[str, List[str]] = {
    "animals": [
        "cat", "dog", "elephant", "giraffe", "monkey", "lion", "tiger", "zebra",
        "penguin", "dolphin", "whale", "kangaroo", "rabbit", "panda", "koala",
        "snake", "octopus", "parrot", "frog", "bear", "eagle", "shark", "camel"
    ],
    "food": [
        "pizza", "burger", "banana", "apple", "ice cream", "cookie", "sushi",
        "taco", "sandwich", "spaghetti", "pancake", "donut", "cheese", "hotdog",
        "strawberry", "watermelon", "chocolate", "popcorn", "avocado", "muffin"
    ],
    "objects": [
        "chair", "table", "clock", "lamp", "computer", "pencil", "backpack",
        "umbrella", "guitar", "camera", "glasses", "scissors", "telephone",
        "candle", "mirror", "toothbrush", "pillow", "balloon", "key", "door"
    ],
    "places": [
        "beach", "castle", "hospital", "school", "library", "mountain", "island",
        "airport", "park", "museum", "desert", "cinema", "hotel", "bridge", "forest"
    ],
    "technology": [
        "robot", "rocket", "satellite", "laptop", "drone", "gamepad", "printer",
        "headphones", "battery", "telescope", "microscope", "antenna", "keyboard"
    ],
    "actions": [
        "running", "swimming", "sleeping", "dancing", "cooking", "flying",
        "singing", "jumping", "painting", "laughing", "climbing", "fishing"
    ]
}

ALL_WORDS: List[str] = [w for words in WORD_BANKS.values() for w in words]

class WordManager:
    @staticmethod
    def get_word_choices(count: int = 3, category: Optional[str] = None, custom_words: Optional[List[str]] = None) -> List[str]:
        pool = []
        if custom_words and len(custom_words) >= count:
            pool = [w.strip() for w in custom_words if w.strip()]
        elif category and category in WORD_BANKS:
            pool = list(WORD_BANKS[category])
        else:
            pool = list(ALL_WORDS)

        if len(pool) < count:
            pool = list(ALL_WORDS)

        return random.sample(pool, min(count, len(pool)))

    @staticmethod
    def mask_word(word: str, revealed_indices: Optional[set] = None) -> str:
        """
        Returns display string with blanks.
        For example: 'cat' -> '_ _ _'
        If index 1 is revealed -> '_ a _'
        Spaces remain visible spaces.
        """
        if not word:
            return ""
        revealed_indices = revealed_indices or set()
        chars = []
        for i, ch in enumerate(word):
            if ch == " ":
                chars.append(" ")
            elif i in revealed_indices:
                chars.append(ch.upper())
            else:
                chars.append("_")
        return " ".join(chars)

    @staticmethod
    def get_next_hint(word: str, current_revealed: set, max_reveal_ratio: float = 0.5) -> Optional[int]:
        """
        Chooses an unrevealed character index to reveal, up to max_reveal_ratio.
        """
        eligible = [
            i for i, ch in enumerate(word)
            if ch != " " and i not in current_revealed
        ]
        max_allowed = max(1, int(len(word.replace(" ", "")) * max_reveal_ratio))
        if len(current_revealed) >= max_allowed or not eligible:
            return None
        return random.choice(eligible)

    @staticmethod
    def is_close_guess(guess: str, target: str) -> bool:
        """
        Checks if guess is very close (Levenshtein distance <= 1 or 2 depending on length).
        """
        g = guess.strip().lower()
        t = target.strip().lower()
        if g == t:
            return False
        
        # Levenshtein distance
        dp = [[0] * (len(t) + 1) for _ in range(len(g) + 1)]
        for i in range(len(g) + 1):
            dp[i][0] = i
        for j in range(len(t) + 1):
            dp[0][j] = j
        for i in range(1, len(g) + 1):
            for j in range(1, len(t) + 1):
                cost = 0 if g[i - 1] == t[j - 1] else 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1,      # deletion
                    dp[i][j - 1] + 1,      # insertion
                    dp[i - 1][j - 1] + cost # substitution
                )
        dist = dp[len(g)][len(t)]
        return dist == 1 and len(t) > 3
