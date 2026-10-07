import pytest

from passguard.strength import COMMON_PASSWORDS, PasswordError, assess, entropy_bits, generate


def test_common_password_is_always_very_weak():
    result = assess("Password123")  # matched case-insensitively
    assert result["score"] == 0
    assert result["label"] == "very weak"
    assert "most common" in result["feedback"][0]


@pytest.mark.parametrize(
    "password, minimum",
    [
        ("Tr0ub4dor&3", 2),
        ("correct-horse-battery-staple", 3),
        ("G7#kP2!vQ9@wL4$z", 4),
    ],
)
def test_strong_passwords_score_well(password, minimum):
    assert assess(password)["score"] >= minimum


def test_short_single_class_password_gets_advice():
    result = assess("sunset")
    assert result["score"] <= 1
    assert "Use at least 12 characters." in result["feedback"]
    assert "Mix upper case, lower case, digits and symbols." in result["feedback"]


def test_sequences_and_repeats_cost_a_point():
    plain = assess("Kx9!mZp2#Lr7")["score"]
    assert assess("Kx9!abcdZp2#")["score"] == plain - 1
    assert assess("Kx9!mmmZp2#L")["score"] == plain - 1


def test_reversed_keyboard_sequence_is_detected():
    assert any("sequences" in tip for tip in assess("Zz9!poiuytr#")["feedback"])


def test_entropy_grows_with_character_pool():
    assert entropy_bits("") == 0
    assert entropy_bits("aaaa") < entropy_bits("aA1!")


@pytest.mark.parametrize("bad", [None, 12345, "", "x" * 129])
def test_bad_input_is_rejected(bad):
    with pytest.raises(PasswordError):
        assess(bad)


def test_generated_passwords_use_every_class_and_are_strong():
    for length in (12, 20, 64):
        password = generate(length)
        assert len(password) == length
        assert password.lower() not in COMMON_PASSWORDS
        assert assess(password)["score"] >= 3


def test_generated_passwords_differ():
    assert len({generate(16) for _ in range(20)}) == 20


@pytest.mark.parametrize("length", [11, 65, "16", True])
def test_generate_rejects_bad_length(length):
    with pytest.raises(PasswordError):
        generate(length)
