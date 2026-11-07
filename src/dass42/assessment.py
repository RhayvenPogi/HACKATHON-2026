
# src/dass42/assessment.py

from src.dass42.scoring import assess_dass42
from src.dass42.guidance import generate_guidance


def process_assessment(responses):
    """
    FLOW assessment service.

    Accepts 42 questionnaire responses and returns
    preliminary scores, severity classifications,
    and initial guidance.
    """

    # Calculate DASS-42 scores
    assessment_result = assess_dass42(responses)

    # Generate initial guidance
    guidance_result = generate_guidance(
        assessment_result["assessment"]
    )

    return {
        "status": "success",
        "assessment": assessment_result["assessment"],
        "guidance": guidance_result["guidance"],
        "notice": guidance_result["notice"]
    }
