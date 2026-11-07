# src/dass42/assessment.py

from src.dass21.scoring import assess_dass21
from src.dass42.guidance import generate_guidance


def process_assessment(responses):
    """
    Muni assessment service.

    Accepts 21 DASS-21 questionnaire responses and returns
    preliminary scores, severity classifications,
    and initial guidance.
    """

    # Calculate DASS-21 scores (doubled to the DASS-42 scale)
    assessment_result = assess_dass21(responses)

    # Generate initial guidance
    guidance_result = generate_guidance(assessment_result["assessment"])

    return {
        "status": "success",
        "instrument": "DASS-21",
        "assessment": assessment_result["assessment"],
        "guidance": guidance_result["guidance"],
        "notice": guidance_result["notice"],
    }