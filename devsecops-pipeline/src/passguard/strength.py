"""Password strength scoring and generation.

Pure Python, no network calls: the password never leaves the process and is
never logged or stored.
"""

import math
import secrets
import string

# A small slice of the most-used passwords from public breach lists
COMMON_PASSWORDS = frozenset(
    {
        "123456", "123456789", "12345678", "12345", "1234567", "1234567890",
        "password", "password1", "password123", "passw0rd", "qwerty", "qwerty123",
        "qwertyuiop", "abc123", "111111", "000000", "123123", "1q2w3e4r",
        "iloveyou", "admin", "admin123", "welcome", "welcome1", "letmein",
        "monkey", "dragon", "football", "baseball", "sunshine", "princess",
        "superman", "trustno1", "master", "shadow", "login", "starwars",
        "india123", "changeme", "secret", "zaq12wsx",
    }
)  # fmt: skip

SEQUENCES = ("abcdefghijklmnopqrstuvwxyz", "0123456789", "qwertyuiop", "asdfghjkl", "zxcvbnm")
LABELS = ("very weak", "weak", "fair", "strong", "very strong")
MAX_LENGTH = 128
SYMBOLS = "!@#$%^&*-_=+?"


class PasswordError(ValueError):
    """Raised for input that cannot be assessed."""


def _classes(password):
    return {
        "lower": any(c in string.ascii_lowercase for c in password),
        "upper": any(c in string.ascii_uppercase for c in password),
        "digit": any(c in string.digits for c in password),
        "symbol": any(not c.isalnum() for c in password),
    }


def entropy_bits(password):
    """Upper bound on guessing entropy: length x log2(size of the character pool)."""
    sizes = {"lower": 26, "upper": 26, "digit": 10, "symbol": 33}
    pool = sum(sizes[name] for name, present in _classes(password).items() if present)
    return len(password) * math.log2(pool) if pool else 0.0


def _has_sequence(password, run=4):
    lowered = password.lower()
    for seq in SEQUENCES:
        for chain in (seq, seq[::-1]):
            for i in range(len(chain) - run + 1):
                if chain[i : i + run] in lowered:
                    return True
    return False


def _has_repeat(password, run=3):
    return any(password[i] * run == password[i : i + run] for i in range(len(password) - run + 1))


def assess(password):
    if not isinstance(password, str):
        raise PasswordError("password must be a string")
    if not password:
        raise PasswordError("password must not be empty")
    if len(password) > MAX_LENGTH:
        raise PasswordError(f"password must be at most {MAX_LENGTH} characters")

    bits = entropy_bits(password)
    score = 0 if bits < 28 else 1 if bits < 36 else 2 if bits < 60 else 3 if bits < 80 else 4
    feedback = []

    if len(password) < 12:
        feedback.append("Use at least 12 characters.")
    if sum(_classes(password).values()) < 3:
        feedback.append("Mix upper case, lower case, digits and symbols.")
    if _has_sequence(password):
        feedback.append("Avoid keyboard or alphabet sequences like 'abcd' or 'qwer'.")
        score = max(score - 1, 0)
    if _has_repeat(password):
        feedback.append("Avoid repeating the same character.")
        score = max(score - 1, 0)
    if password.lower() in COMMON_PASSWORDS:
        feedback = ["This is one of the most common passwords - it is guessed instantly."]
        score = 0

    return {
        "score": score,
        "label": LABELS[score],
        "entropy_bits": round(bits, 1),
        "length": len(password),
        "feedback": feedback,
    }


def generate(length=16):
    if isinstance(length, bool) or not isinstance(length, int):
        raise PasswordError("length must be a whole number")
    if not 12 <= length <= 64:
        raise PasswordError("length must be between 12 and 64")
    alphabet = string.ascii_letters + string.digits + SYMBOLS
    while True:
        candidate = "".join(secrets.choice(alphabet) for _ in range(length))
        if all(_classes(candidate).values()):
            return candidate
