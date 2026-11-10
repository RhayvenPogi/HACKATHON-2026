"""Minimal Gemini API client (standard library only).

The API key is read from the GEMINI_API_KEY environment variable.
It must never be committed to git or put in the mobile app.
"""

import json
import os
import urllib.error
import urllib.request

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
TIMEOUT_SECONDS = 8

SYSTEM_PROMPT = (
    "You write short, practical self-care tips for a mental wellness app used "
    "by adults in the Philippines. Rules: give general wellbeing tips only. "
    "Never diagnose, never mention medication, supplements or dosages, never "
    "describe self-harm, and never promise results. Use plain, warm, simple "
    "English. Reply ONLY with a JSON array of exactly 3 objects, each with "
    '"title" (max 6 words) and "body" (max 30 words).'
)


class GeminiError(Exception):
    pass


def generate_tips(topic_description):
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise GeminiError("GEMINI_API_KEY is not set.")
    model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash").strip()

    body = {
        "systemInstruction": {"parts": [{"text": SYSTEM_PROMPT}]},
        "contents": [
            {"parts": [{"text": f"Give 3 tips about {topic_description}."}]}
        ],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 2048,
            "responseMimeType": "application/json",
        },
    }
    request = urllib.request.Request(
        API_URL.format(model=model),
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json", "x-goog-api-key": api_key},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            payload = json.load(response)
    except (urllib.error.URLError, TimeoutError, ValueError) as error:
        raise GeminiError(f"Gemini request failed: {type(error).__name__}") from None

    try:
        text = payload["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        raise GeminiError("Unexpected Gemini response shape.") from None
    return text
