# src/dass21/indicator.py

"""
Muni - overall screening indicator shown to citizens.

Collapses the three DASS-21 subscale severities into ONE general level,
based on the highest severity across depression, anxiety and stress:

    low      highest severity is Normal or Mild
    moderate highest severity is Moderate
    high     highest severity is Severe or Extremely Severe

Subscale scores and labels are never returned to citizens.
"""

from src.dass21.scoring import assess_dass21

SEVERITY_ORDER = ["Normal", "Mild", "Moderate", "Severe", "Extremely Severe"]

LEVEL_BY_SEVERITY = {
    "Normal": "low",
    "Mild": "low",
    "Moderate": "moderate",
    "Severe": "high",
    "Extremely Severe": "high",
}


def overall_indicator(responses):
    """Return 'low', 'moderate' or 'high' for 21 DASS-21 responses."""
    assessment = assess_dass21(responses)["assessment"]
    highest = max(
        (result["severity"] for result in assessment.values()),
        key=SEVERITY_ORDER.index,
    )
    return LEVEL_BY_SEVERITY[highest]