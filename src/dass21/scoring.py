# src/dass21/scoring.py

"""
Muni - DASS-21 Assessment Scoring Engine

Accepts 21 responses encoded from 0 to 3.
Each subscale has 7 items. The raw subscale sum is multiplied by 2,
which is the standard DASS-21 scoring rule, so the DASS-42 severity
bands and the 0-42 range apply unchanged.

This module provides screening scores, not medical diagnoses.
"""

from src.dass42.scoring import classify_severity

ITEM_COUNT = 21
MULTIPLIER = 2
MAXIMUM_SCORE = 42

# DASS-21 item numbers belonging to each subscale.
SUBSCALE_ITEMS = {
    "depression": [3, 5, 10, 13, 16, 17, 21],
    "anxiety": [2, 4, 7, 9, 15, 19, 20],
    "stress": [1, 6, 8, 11, 12, 14, 18],
}


def validate_responses(responses):
    """Validate the 21 questionnaire responses."""

    if not isinstance(responses, (list, tuple)):
        raise TypeError("Responses must be a list or tuple.")

    if len(responses) != ITEM_COUNT:
        raise ValueError(f"DASS-21 requires exactly {ITEM_COUNT} responses.")

    for index, response in enumerate(responses, start=1):
        if isinstance(response, bool) or not isinstance(response, int):
            raise TypeError(f"Item {index} must contain an integer.")

        if response not in (0, 1, 2, 3):
            raise ValueError(f"Item {index} must be between 0 and 3.")


def calculate_subscale(responses, subscale):
    """Calculate one DASS-21 subscale score (raw sum x 2)."""

    if subscale not in SUBSCALE_ITEMS:
        raise ValueError("Unknown DASS-21 subscale.")

    raw = sum(responses[item - 1] for item in SUBSCALE_ITEMS[subscale])
    return raw * MULTIPLIER


def assess_dass21(responses):
    """
    Calculate all three DASS-21 subscale scores.

    Returns preliminary screening information.
    """

    validate_responses(responses)

    results = {}
    for subscale in SUBSCALE_ITEMS:
        score = calculate_subscale(responses, subscale)
        results[subscale] = {
            "score": score,
            "maximum_score": MAXIMUM_SCORE,
            "severity": classify_severity(score, subscale),
        }

    return {"assessment": results}