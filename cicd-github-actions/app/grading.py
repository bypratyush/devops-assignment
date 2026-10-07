"""Grading rules for a 10-point scale (the scheme most Indian universities use).

Kept free of Flask so it can be unit tested on its own.
"""

# (minimum score, letter grade, grade points) - checked top to bottom
GRADE_BANDS = [
    (90, "O", 10),
    (80, "A+", 9),
    (70, "A", 8),
    (60, "B+", 7),
    (50, "B", 6),
    (45, "C", 5),
    (40, "P", 4),
    (0, "F", 0),
]

MAX_CREDITS = 10


class GradingError(ValueError):
    """Raised for input the calculator refuses to grade."""


def _as_number(value, field):
    # bool is a subclass of int, but True is not a score
    if isinstance(value, bool):
        raise GradingError(f"{field} must be a number")
    try:
        return float(value)
    except (TypeError, ValueError):
        raise GradingError(f"{field} must be a number") from None


def grade_for(score):
    """Return (letter, points) for a score between 0 and 100."""
    score = _as_number(score, "score")
    if not 0 <= score <= 100:
        raise GradingError("score must be between 0 and 100")
    for minimum, letter, points in GRADE_BANDS:
        if score >= minimum:
            return letter, points
    raise GradingError("unreachable")  # pragma: no cover


def sgpa(courses):
    """Credit-weighted grade point average for one semester.

    courses: list of {"name": str, "credits": int, "score": number}
    Returns a dict with the SGPA, total credits and the per-course breakdown.
    """
    if not isinstance(courses, list) or not courses:
        raise GradingError("courses must be a non-empty list")

    breakdown = []
    weighted = 0
    total_credits = 0
    for i, course in enumerate(courses):
        if not isinstance(course, dict):
            raise GradingError(f"course {i} must be an object")
        credits = course.get("credits")
        if isinstance(credits, bool) or not isinstance(credits, int):
            raise GradingError(f"course {i}: credits must be a whole number")
        if not 1 <= credits <= MAX_CREDITS:
            raise GradingError(f"course {i}: credits must be between 1 and {MAX_CREDITS}")
        letter, points = grade_for(course.get("score"))
        weighted += credits * points
        total_credits += credits
        breakdown.append(
            {
                "name": str(course.get("name", f"course-{i + 1}")),
                "credits": credits,
                "grade": letter,
                "points": points,
            }
        )

    return {
        "sgpa": round(weighted / total_credits, 2),
        "total_credits": total_credits,
        "courses": breakdown,
    }
