from django.test import TestCase
from rest_framework.test import APIClient

URL = "/api/assessments/"


class AssessmentEndpointTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def post(self, payload):
        return self.client.post(URL, payload, format="json")

    def test_all_zero_returns_full_structure(self):
        response = self.post({"responses": [0] * 42})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        for scale in ("depression", "anxiety", "stress"):
            self.assertEqual(data["assessment"][scale]["score"], 0)
            self.assertEqual(data["assessment"][scale]["maximum_score"], 42)
            self.assertEqual(data["assessment"][scale]["severity"], "Normal")
            for key in ("severity", "title", "message", "recommendation"):
                self.assertIn(key, data["guidance"][scale])

    def test_all_three_is_maximum_and_extremely_severe(self):
        data = self.post({"responses": [3] * 42}).json()
        for scale in ("depression", "anxiety", "stress"):
            self.assertEqual(data["assessment"][scale]["score"], 42)
            self.assertEqual(data["assessment"][scale]["severity"], "Extremely Severe")

    def test_rejects_41_responses(self):
        self.assertEqual(self.post({"responses": [0] * 41}).status_code, 400)

    def test_rejects_43_responses(self):
        self.assertEqual(self.post({"responses": [0] * 43}).status_code, 400)

    def test_rejects_value_out_of_range(self):
        self.assertEqual(self.post({"responses": [0] * 41 + [4]}).status_code, 400)

    def test_rejects_negative_value(self):
        self.assertEqual(self.post({"responses": [0] * 41 + [-1]}).status_code, 400)

    def test_rejects_missing_field(self):
        self.assertEqual(self.post({}).status_code, 400)

    def test_rejects_booleans(self):
        self.assertEqual(self.post({"responses": [True] * 42}).status_code, 400)

    def test_notice_is_exact(self):
        notice = self.post({"responses": [0] * 42}).json()["notice"]
        self.assertEqual(
            notice,
            "Muni provides preliminary screening information and general "
            "guidance only. It does not diagnose or replace professional "
            "assessment.",
        )