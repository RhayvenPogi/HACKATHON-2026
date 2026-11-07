
from rest_framework import serializers


class AssessmentRequestSerializer(serializers.Serializer):
    responses = serializers.ListField(
        child=serializers.ChoiceField(choices=[0, 1, 2, 3]),
        min_length=42,
        max_length=42,
        error_messages={
            "min_length": "Exactly 42 responses are required.",
            "max_length": "Exactly 42 responses are required.",
        }
    )

    def validate_responses(self, value):
        if any(isinstance(item, bool) for item in value):
            raise serializers.ValidationError(
                "Boolean values are not valid questionnaire responses."
            )

        return [int(item) for item in value]
