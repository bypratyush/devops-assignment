import pytest

from app.grading import GradingError, grade_for, sgpa


@pytest.mark.parametrize(
    "score, expected",
    [
        (100, ("O", 10)),
        (90, ("O", 10)),
        (89.5, ("A+", 9)),
        (80, ("A+", 9)),
        (79, ("A", 8)),
        (60, ("B+", 7)),
        (50, ("B", 6)),
        (45, ("C", 5)),
        (40, ("P", 4)),
        (39.9, ("F", 0)),
        (0, ("F", 0)),
    ],
)
def test_grade_band_boundaries(score, expected):
    assert grade_for(score) == expected


def test_numeric_strings_are_accepted():
    assert grade_for("72") == ("A", 8)


@pytest.mark.parametrize("bad", [-1, 100.1, "abc", None, True])
def test_invalid_scores_are_rejected(bad):
    with pytest.raises(GradingError):
        grade_for(bad)


def test_sgpa_is_credit_weighted():
    result = sgpa(
        [
            {"name": "DevOps", "credits": 4, "score": 91},  # O  -> 10 x 4 = 40
            {"name": "DBMS", "credits": 3, "score": 76},  # A  ->  8 x 3 = 24
            {"name": "Maths", "credits": 2, "score": 55},  # B  ->  6 x 2 = 12
        ]
    )
    assert result["sgpa"] == round(76 / 9, 2) == 8.44
    assert result["total_credits"] == 9
    assert [c["grade"] for c in result["courses"]] == ["O", "A", "B"]


def test_sgpa_names_unnamed_courses():
    result = sgpa([{"credits": 3, "score": 85}])
    assert result["courses"][0]["name"] == "course-1"


@pytest.mark.parametrize(
    "courses",
    [
        [],
        None,
        ["not-a-dict"],
        [{"credits": 0, "score": 80}],
        [{"credits": 11, "score": 80}],
        [{"credits": 2.5, "score": 80}],
        [{"credits": True, "score": 80}],
        [{"credits": 3, "score": 120}],
    ],
)
def test_sgpa_rejects_bad_input(courses):
    with pytest.raises(GradingError):
        sgpa(courses)
