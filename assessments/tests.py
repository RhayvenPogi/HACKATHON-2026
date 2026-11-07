from django.test import SimpleTestCase, TestCase
from rest_framework.test import APIClient

from src.dass21.scoring import ITEM_COUNT, SUBSCALE_ITEMS, assess_dass21

URL = "/api/assessments/"
SCALES = ("depression", "anxiety", "stress")


def answers_for(**raw_by_scale):
    """Build 21 answers whose RAW subscale sums equal the given values."""
    responses = [0] * ITEM_COUNT
    for scale, raw in raw_by_scale.items():
        remaining = raw
        for item in SUBSCALE_ITEMS[scale]:
            value = min(3, remaining)
            responses[item - 1] = value
            remaining -= value
        assert remaining == 0, f"raw {raw} too high for {scale}"
    return responses


class Dass21ScoringTests(SimpleTestCase):
    def test_items_partition_1_to_21(self):
        items = sorted(i for scale in SUBSCALE_ITEMS.values() for i in scale)
        self.assertEqual(items, list(range(1, 22)))
        for scale in SCALES:
            self.assertEqual(len(SUBSCALE_ITEMS[scale]), 7)

    def test_scores_are_doubled(self):
        responses = [0] * ITEM_COUNT
        responses[3 - 1] = 3  # item 3 is a depression item
        result = assess_dass21(responses)["assessment"]
        self.assertEqual(result["depression"]["score"], 6)
        self.assertEqual(result["anxiety"]["score"], 0)
        self.assertEqual(result["stress"]["score"], 0)

    def test_severity_boundaries_after_doubling(self):
        # (scale, raw sum, expected severity) at each DASS-42 cutoff edge.
        cases = [
            ("depression", 4, "Normal"), ("depression", 5, "Mild"),
            ("depression", 6, "Mild"), ("depression", 7, "Moderate"),
            ("depression", 10, "Moderate"), ("depression", 11, "Severe"),
            ("depression", 13, "Severe"), ("depression", 14, "Extremely Severe"),
            ("anxiety", 3, "Normal"), ("anxiety", 4, "Mild"),
            ("anxiety", 5, "Moderate"), ("anxiety", 7, "Moderate"),
            ("anxiety", 8, "Severe"), ("anxiety", 9, "Severe"),
            ("anxiety", 10, "Extremely Severe"),
            ("stress", 7, "Normal"), ("stress", 8, "Mild"),
            ("stress", 9, "Mild"), ("stress", 10, "Moderate"),
            ("stress", 12, "Moderate"), ("stress", 13, "Severe"),
            ("stress", 16, "Severe"), ("stress", 17, "Extremely Severe"),
        ]
        for scale, raw, expected in cases:
            with self.subTest(scale=scale, raw=raw):
                result = assess_dass21(answers_for(**{scale: raw}))["assessment"]
                self.assertEqual(result[scale]["score"], raw * 2)
                self.assertEqual(result[scale]["severity"], expected)
                for other in SCALES:
                    if other != scale:
                        self.assertEqual(result[other]["score"], 0)


class AssessmentEndpointTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def post(self, payload):
        return self.client.post(URL, payload, format="json")

    def test_all_zero_returns_full_structure(self):
        response = self.post({"responses": [0] * ITEM_COUNT})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["instrument"], "DASS-21")
        for scale in SCALES:
            self.assertEqual(data["assessment"][scale]["score"], 0)
            self.assertEqual(data["assessment"][scale]["maximum_score"], 42)
            self.assertEqual(data["assessment"][scale]["severity"], "Normal")
            for key in ("severity", "title", "message", "recommendation"):
                self.assertIn(key, data["guidance"][scale])

    def test_all_three_is_maximum_and_extremely_severe(self):
        data = self.post({"responses": [3] * ITEM_COUNT}).json()
        for scale in SCALES:
            self.assertEqual(data["assessment"][scale]["score"], 42)
            self.assertEqual(data["assessment"][scale]["severity"], "Extremely Severe")

    def test_rejects_20_responses(self):
        self.assertEqual(self.post({"responses": [0] * 20}).status_code, 400)

    def test_rejects_22_responses(self):
        self.assertEqual(self.post({"responses": [0] * 22}).status_code, 400)

    def test_rejects_old_42_item_payload(self):
        self.assertEqual(self.post({"responses": [0] * 42}).status_code, 400)

    def test_rejects_value_out_of_range(self):
        self.assertEqual(self.post({"responses": [0] * 20 + [4]}).status_code, 400)

    def test_rejects_negative_value(self):
        self.assertEqual(self.post({"responses": [0] * 20 + [-1]}).status_code, 400)

    def test_rejects_missing_field(self):
        self.assertEqual(self.post({}).status_code, 400)

    def test_rejects_booleans(self):
        self.assertEqual(self.post({"responses": [True] * ITEM_COUNT}).status_code, 400)

    def test_notice_is_exact(self):
        notice = self.post({"responses": [0] * ITEM_COUNT}).json()["notice"]
        self.assertEqual(
            notice,
            "Muni provides preliminary screening information and general "
            "guidance only. It does not diagnose or replace professional "
            "assessment.",
        )