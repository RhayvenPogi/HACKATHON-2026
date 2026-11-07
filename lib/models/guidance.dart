import 'package:muni_app/models/json_utils.dart';
import 'package:muni_app/models/severity.dart';

class SubscaleGuidance {
  const SubscaleGuidance({
    required this.severity,
    required this.title,
    required this.message,
    required this.recommendation,
  });

  factory SubscaleGuidance.fromJson(Map<String, dynamic> json) {
    return SubscaleGuidance(
      severity: Severity.fromApi(json['severity']),
      title: requireString(json, 'title'),
      message: requireString(json, 'message'),
      recommendation: requireString(json, 'recommendation'),
    );
  }

  final Severity severity;
  final String title;
  final String message;
  final String recommendation;
}