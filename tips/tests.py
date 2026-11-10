import json
from unittest import mock

from django.core.cache import cache
from django.test import TestCase

from .gemini import GeminiError

URL = "/api/tips/"
GOOD = json.dumps([
    {"title": "Keep a routine", "body": "Sleep and wake at the same time."},
    {"title": "Dim the lights", "body": "Lower the lights an hour before bed."},
    {"title": "Park your worries", "body": "Write tomorrow's tasks on paper."},
])


class TipsTests(TestCase):
    def setUp(self):
        cache.clear()

    def post(self, data):
        return self.client.post(URL, json.dumps(data), content_type="application/json")

    def test_unknown_topic_rejected_and_ai_not_called(self):
        with mock.patch("tips.views.generate_tips") as gen:
            response = self.post({"topic": "my answers were 3 3 3"})
        self.assertEqual(response.status_code, 400)
        gen.assert_not_called()

    def test_ai_tips_returned_and_only_topic_is_sent(self):
        with mock.patch("tips.views.generate_tips", return_value=GOOD) as gen:
            data = self.post({"topic": "sleep", "responses": [3] * 21}).json()
        self.assertEqual(data["source"], "ai")
        self.assertEqual(len(data["tips"]), 3)
        gen.assert_called_once_with("sleeping better")  # nothing else sent

    def test_falls_back_when_ai_fails(self):
        with mock.patch("tips.views.generate_tips", side_effect=GeminiError("down")):
            data = self.post({"topic": "stress"}).json()
        self.assertEqual(data["source"], "curated")
        self.assertEqual(len(data["tips"]), 3)

    def test_falls_back_on_unsafe_output(self):
        unsafe = json.dumps([
            {"title": "Try medication", "body": "Ask for a higher dose."},
            {"title": "Rest", "body": "Rest well."},
            {"title": "Walk", "body": "Walk daily."},
        ])
        with mock.patch("tips.views.generate_tips", return_value=unsafe):
            data = self.post({"topic": "low_mood"}).json()
        self.assertEqual(data["source"], "curated")

    def test_falls_back_on_malformed_output(self):
        with mock.patch("tips.views.generate_tips", return_value="not json"):
            data = self.post({"topic": "worry"}).json()
        self.assertEqual(data["source"], "curated")

    def test_cached_per_topic(self):
        with mock.patch("tips.views.generate_tips", return_value=GOOD) as gen:
            self.post({"topic": "sleep"})
            self.post({"topic": "sleep"})
        self.assertEqual(gen.call_count, 1)

    def test_missing_key_uses_curated(self):
        with mock.patch.dict("os.environ", {"GEMINI_API_KEY": ""}):
            data = self.post({"topic": "sleep"}).json()
        self.assertEqual(data["source"], "curated")
