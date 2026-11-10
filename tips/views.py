import json
import re

from django.core.cache import cache
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from .content import CURATED_TIPS, TOPIC_LABELS, TOPICS
from .gemini import GeminiError, generate_tips

RATE_LIMIT = 20  # requests per IP per hour
CACHE_SECONDS = 30 * 60  # reuse AI tips per topic to save quota

# Reject AI output that drifts into clinical or unsafe territory.
BLOCKED = re.compile(
    r"diagnos|medicat|prescri|dosage|\bdoses?\b|\bmg\b|\bpills?\b|"
    r"antidepress|suicid|self-harm|\bkill|overdose|\bcures?\b",
    re.IGNORECASE,
)


def _rate_limited(request):
    ip = request.META.get("REMOTE_ADDR", "unknown")
    key = f"tips-rate:{ip}"
    count = cache.get(key, 0)
    if count >= RATE_LIMIT:
        return True
    cache.set(key, count + 1, 60 * 60)
    return False


def _validate(raw_text):
    """Return a clean list of 3 tips, or None if the output is unusable."""
    try:
        data = json.loads(raw_text)
    except (json.JSONDecodeError, TypeError):
        return None
    if not isinstance(data, list) or len(data) != 3:
        return None
    tips = []
    for item in data:
        if not isinstance(item, dict):
            return None
        title, body = item.get("title"), item.get("body")
        if not isinstance(title, str) or not isinstance(body, str):
            return None
        title, body = title.strip(), body.strip()
        if not title or not body or len(title) > 60 or len(body) > 260:
            return None
        if BLOCKED.search(title) or BLOCKED.search(body):
            return None
        tips.append({"title": title, "body": body})
    return tips


def _curated(topic):
    return [{"title": t, "body": b} for t, b in CURATED_TIPS[topic]]


@csrf_exempt
@require_POST
def tips(request):
    try:
        data = json.loads(request.body or b"{}")
    except (json.JSONDecodeError, UnicodeDecodeError):
        data = {}
    topic = data.get("topic") if isinstance(data, dict) else None
    if topic not in TOPICS:
        return JsonResponse(
            {"error": "Unknown topic.", "topics": list(TOPICS)}, status=400
        )

    response = {"topic": topic, "label": TOPIC_LABELS[topic]}

    cached = cache.get(f"tips:{topic}")
    if cached:
        return JsonResponse({**response, "source": "ai", "tips": cached})

    if _rate_limited(request):
        return JsonResponse({**response, "source": "curated", "tips": _curated(topic)})

    try:
        ai_tips = _validate(generate_tips(TOPICS[topic]))
    except GeminiError:
        ai_tips = None

    if ai_tips is None:
        return JsonResponse({**response, "source": "curated", "tips": _curated(topic)})

    cache.set(f"tips:{topic}", ai_tips, CACHE_SECONDS)
    return JsonResponse({**response, "source": "ai", "tips": ai_tips})
