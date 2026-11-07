from rest_framework import serializers

from assessments.serializers import AssessmentRequestSerializer


class ShareCreateSerializer(AssessmentRequestSerializer):
    """Reuses the exact response validation from /api/assessments/."""

    consent_version = serializers.IntegerField(min_value=1)
    consent_given = serializers.BooleanField()

    def validate_consent_given(self, value):
        if value is not True:
            raise serializers.ValidationError("Explicit consent is required to share.")
        return value


class TokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=128)


class ProfessionalLoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=128, trim_whitespace=False)

class PasswordChangeSerializer(serializers.Serializer):
    current_password = serializers.CharField(max_length=128, trim_whitespace=False)
    new_password = serializers.CharField(max_length=128, trim_whitespace=False)