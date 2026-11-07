
# src/dass42/guidance.py

"""
FLOW - Initial Guidance Engine

Provides general, non-diagnostic guidance based on
DASS-42 screening categories.
"""

GUIDANCE = {
    "Normal": {
        "title": "No elevated symptoms indicated by this screening",
        "message": (
            "Your responses did not indicate elevated symptoms "
            "within this screening. Continue taking care of your "
            "well-being and seek support whenever you need it."
        ),
        "recommendation": (
            "Maintain healthy routines, stay connected with "
            "supportive people, and monitor your well-being."
        )
    },

    "Mild": {
        "title": "Some symptoms may be present",
        "message": (
            "Your responses indicate some symptoms worth paying "
            "attention to. This result does not establish a "
            "mental health condition."
        ),
        "recommendation": (
            "Consider talking with someone you trust or seeking "
            "guidance from a qualified mental health professional."
        )
    },

    "Moderate": {
        "title": "Additional support may be helpful",
        "message": (
            "Your responses suggest that you may be experiencing "
            "a level of distress worth discussing with a "
            "qualified professional."
        ),
        "recommendation": (
            "Consider arranging a consultation with a qualified "
            "mental health professional or an appropriate "
            "mental health service."
        )
    },

    "Severe": {
        "title": "Professional support is recommended",
        "message": (
            "Your responses indicate a higher level of reported "
            "distress. A screening result cannot determine its "
            "cause or establish a diagnosis."
        ),
        "recommendation": (
            "Consider reaching out to a qualified mental health "
            "professional as soon as reasonably possible. "
            "You may use Muni's facility locator to find support."
        )
    },

    "Extremely Severe": {
        "title": "Prompt professional support is recommended",
        "message": (
            "Your responses indicate a particularly high level "
            "of reported distress. Please consider discussing "
            "these results with a qualified professional promptly."
        ),
        "recommendation": (
            "Reach out to a qualified mental health professional "
            "or an appropriate healthcare facility promptly. "
            "If you feel unable to keep yourself safe or face "
            "an immediate emergency, contact local emergency "
            "services or seek immediate help from a trusted person."
        )
    }
}


def generate_guidance(assessment):
    """
    Generate initial guidance for all three DASS-42 subscales.
    """

    if not isinstance(assessment, dict):
        raise TypeError("Assessment must be a dictionary.")

    guidance_results = {}

    for subscale in ("depression", "anxiety", "stress"):
        if subscale not in assessment:
            raise ValueError(f"Missing assessment: {subscale}")

        severity = assessment[subscale].get("severity")

        if severity not in GUIDANCE:
            raise ValueError(
                f"Invalid severity category for {subscale}: {severity}."
            )

        guidance_results[subscale] = {
            "severity": severity,
            **GUIDANCE[severity]
        }

    return {
        "guidance": guidance_results,
        "notice": (
            "Muni provides preliminary screening information and general guidance only. It does not diagnose or replace professional assessment."
        )
    }
