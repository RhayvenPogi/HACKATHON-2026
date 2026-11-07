import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/models/json_utils.dart';

/// A citizen-shared assessment, held in memory only while viewed.
class SharedAssessmentView {
  const SharedAssessmentView({
    required this.result,
    required this.responses,
    required this.sharedAt,
    required this.expiresAt,
  });

  factory SharedAssessmentView.fromJson(Map<String, dynamic> json) {
    final raw = json['responses'];
    if (raw is! List ||
        raw.length != 42 ||
        raw.any((r) => r is! int || r < 0 || r > 3)) {
      throw const FormatException('Invalid "responses".');
    }
    final sharedAt = DateTime.tryParse(requireString(json, 'shared_at'));
    final expiresAt = DateTime.tryParse(requireString(json, 'expires_at'));
    if (sharedAt == null || expiresAt == null) {
      throw const FormatException('Invalid dates.');
    }
    return SharedAssessmentView(
      result: AssessmentResponse.fromJson(json),
      responses: List<int>.unmodifiable(raw.cast<int>()),
      sharedAt: sharedAt,
      expiresAt: expiresAt,
    );
  }

  final AssessmentResponse result;
  final List<int> responses;
  final DateTime sharedAt;
  final DateTime expiresAt;
}