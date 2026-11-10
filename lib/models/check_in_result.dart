import 'package:muni_app/models/json_utils.dart';

enum ScreeningLevel { low, moderate, high }

/// The ONLY result citizens receive: one general level.
class CheckInResult {
  const CheckInResult({required this.level, required this.notice});

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'success') {
      throw const FormatException('Unexpected status.');
    }
    final level = switch (json['indicator']) {
      'low' => ScreeningLevel.low,
      'moderate' => ScreeningLevel.moderate,
      'high' => ScreeningLevel.high,
      _ => throw const FormatException('Unknown indicator.'),
    };
    return CheckInResult(level: level, notice: requireString(json, 'notice'));
  }

  final ScreeningLevel level;
  final String notice;
}