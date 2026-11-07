
# src/dass42/scoring.py

"""
FLOW - DASS-42 Assessment Scoring Engine

Accepts 42 responses encoded from 0 to 3.
Calculates Depression, Anxiety, and Stress subscale scores.

This module provides screening scores, not medical diagnoses.
"""

# DASS-42 item numbers belonging to each subscale.
SUBSCALE_ITEMS = {
    "depression": [
        3, 5, 10, 13, 16, 17, 21,
        24, 26, 31, 34, 37, 38, 42
    ],
    "anxiety": [
        2, 4, 7, 9, 15, 19, 20,
        23, 25, 28, 30, 36, 40, 41
    ],
    "stress": [
        1, 6, 8, 11, 12, 14, 18,
        22, 27, 29, 32, 33, 35, 39
    ]
}

# DASS-42 severity bands (not DASS-21 bands).
SEVERITY_BANDS = {
    "depression": [
        (9, "Normal"),
        (13, "Mild"),
        (20, "Moderate"),
        (27, "Severe"),
        (42, "Extremely Severe")
    ],
    "anxiety": [
        (7, "Normal"),
        (9, "Mild"),
        (14, "Moderate"),
        (19, "Severe"),
        (42, "Extremely Severe")
    ],
    "stress": [
        (14, "Normal"),
        (18, "Mild"),
        (25, "Moderate"),
        (33, "Severe"),
        (42, "Extremely Severe")
    ]
}


def validate_responses(responses):
    """Validate the 42 questionnaire responses."""

    if not isinstance(responses, (list, tuple)):
        raise TypeError("Responses must be a list or tuple.")

    if len(responses) != 42:
        raise ValueError("DASS-42 requires exactly 42 responses.")

    for index, response in enumerate(responses, start=1):
        if isinstance(response, bool) or not isinstance(response, int):
            raise TypeError(
                f"Item {index} must contain an integer."
            )

        if response not in (0, 1, 2, 3):
            raise ValueError(
                f"Item {index} must be between 0 and 3."
            )


def calculate_subscale(responses, subscale):
    """Calculate one DASS-42 subscale score."""

    if subscale not in SUBSCALE_ITEMS:
        raise ValueError("Unknown DASS-42 subscale.")

    item_numbers = SUBSCALE_ITEMS[subscale]

    return sum(
        responses[item_number - 1]
        for item_number in item_numbers
    )


def classify_severity(score, subscale):
    """Return the severity band for a subscale score."""

    for upper_limit, severity in SEVERITY_BANDS[subscale]:
        if score <= upper_limit:
            return severity

    return "Unknown"


def assess_dass42(responses):
    """
    Calculate all three DASS-42 subscale scores.

    Returns preliminary screening information.
    """

    validate_responses(responses)

    results = {}

    for subscale in SUBSCALE_ITEMS:
        score = calculate_subscale(responses, subscale)

        results[subscale] = {
            "score": score,
            "maximum_score": 42,
            "severity": classify_severity(score, subscale)
        }

    return {
        "assessment": results,
        "notice": (
            "These results are preliminary screening information "
            "and are not a medical diagnosis."
        )
    }
