from django.test import SimpleTestCase, TestCase
from rest_framework.test import APIClient

from assessments.serializers import AssessmentRequestSerializer
from src.dass21.scoring import ITEM_COUNT, SUBSCALE_ITEMS, assess_dass21
from src.dass42.assessment import process_assessment

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


class ProcessAssessmentTests(SimpleTestCase):
    """Scoring used when a citizen shares (shown to professionals only)."""

    def test_all_zero_returns_full_structure(self):
        data = process_assessment([0] * ITEM_COUNT)
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["instrument"], "DASS-21")
        for scale in SCALES:
            self.assertEqual(data["assessment"][scale]["score"], 0)
            self.assertEqual(data["assessment"][scale]["maximum_score"], 42)
            self.assertEqual(data["assessment"][scale]["severity"], "Normal")
            for key in ("severity", "title", "message", "recommendation"):
                self.assertIn(key, data["guidance"][scale])

    def test_all_three_is_maximum_and_extremely_severe(self):
        data = process_assessment([3] * ITEM_COUNT)
        for scale in SCALES:
            self.assertEqual(data["assessment"][scale]["score"], 42)
            self.assertEqual(data["assessment"][scale]["severity"], "Extremely Severe")

    def test_rejects_wrong_lengths_and_values(self):
        for bad in ([0] * 20, [0] * 22, [0] * 42, [0] * 20 + [4], [0] * 20 + [-1], [True] * ITEM_COUNT):
            with self.subTest(length=len(bad)):
                with self.assertRaises((ValueError, TypeError)):
                    process_assessment(bad)

    def test_notice_is_exact(self):
        self.assertEqual(
            process_assessment([0] * ITEM_COUNT)["notice"],
            "Muni provides preliminary screening information and general "
            "guidance only. It does not diagnose or replace professional "
            "assessment.",
        )


class AssessmentRequestSerializerTests(SimpleTestCase):
    def test_accepts_21_and_rejects_others(self):
        self.assertTrue(AssessmentRequestSerializer(data={"responses": [1] * 21}).is_valid())
        for bad in ([1] * 20, [1] * 42, [1] * 20 + [4], [True] * 21):
            with self.subTest(bad=bad[:2]):
                self.assertFalse(AssessmentRequestSerializer(data={"responses": bad}).is_valid())
        self.assertFalse(AssessmentRequestSerializer(data={}).is_valid())


class PublicScoringRemovedTests(TestCase):
    def test_public_scoring_endpoint_is_gone(self):
        response = APIClient().post("/api/assessments/", {"responses": [0] * ITEM_COUNT}, format="json")
        self.assertEqual(response.status_code, 404)




class CheckInIndicatorTests(TestCase):
    URL = "/api/check-in/"

    def post(self, responses):
        return APIClient().post(self.URL, {"responses": responses}, format="json")

    def test_returns_only_overall_indicator(self):
        response = self.post([0] * ITEM_COUNT)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(set(data), {"status", "indicator", "notice"})
        self.assertEqual(data["indicator"], "low")

    def test_levels_follow_highest_subscale(self):
        cases = [
            (answers_for(depression=6), "low"),        # Mild
            (answers_for(anxiety=6), "moderate"),      # Moderate
            (answers_for(stress=13), "high"),          # Severe
            (answers_for(depression=4, anxiety=10), "high"),  # Extremely Severe wins
        ]
        for responses, expected in cases:
            with self.subTest(expected=expected):
                self.assertEqual(self.post(responses).json()["indicator"], expected)

    def test_rejects_invalid_answers(self):
        self.assertEqual(self.post([0] * 20).status_code, 400)