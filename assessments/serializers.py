from rest_framework import serializers

from src.dass21.scoring import ITEM_COUNT


class AssessmentRequestSerializer(serializers.Serializer):
    responses = serializers.ListField(
        child=serializers.ChoiceField(choices=[0, 1, 2, 3]),
        min_length=ITEM_COUNT,
        max_length=ITEM_COUNT,
        error_messages={
            "min_length": f"Exactly {ITEM_COUNT} responses are required.",
            "max_length": f"Exactly {ITEM_COUNT} responses are required.",
        }
    )

    def validate_responses(self, value):
        if any(isinstance(item, bool) for item in value):
            raise serializers.ValidationError(
                "Boolean values are not valid questionnaire responses."
            )

        return [int(item) for item in value]