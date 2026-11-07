import 'package:muni_app/models/guidance.dart';
import 'package:muni_app/models/json_utils.dart';
import 'package:muni_app/models/severity.dart';

enum Subscale {
  depression('depression', 'Depression'),
  anxiety('anxiety', 'Anxiety'),
  stress('stress', 'Stress');

  const Subscale(this.key, this.label);

  /// JSON key used by the backend.
  final String key;
  final String label;
}

class SubscaleScore {
  const SubscaleScore({
    required this.score,
    required this.maximumScore,
    required this.severity,
  });

  factory SubscaleScore.fromJson(Map<String, dynamic> json) {
    final score = requireInt(json, 'score');
    final maximumScore = requireInt(json, 'maximum_score');
    if (maximumScore <= 0 || score < 0 || score > maximumScore) {
      throw const FormatException('Score out of range.');
    }
    return SubscaleScore(
      score: score,
      maximumScore: maximumScore,
      severity: Severity.fromApi(json['severity']),
    );
  }

  final int score;
  final int maximumScore;
  final Severity severity;
}

class SubscaleResult {
  const SubscaleResult({
    required this.subscale,
    required this.score,
    required this.guidance,
  });

  final Subscale subscale;
  final SubscaleScore score;
  final SubscaleGuidance guidance;
}

class AssessmentResponse {
  const AssessmentResponse({required this.results, required this.notice});

  factory AssessmentResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'success') {
      throw const FormatException('Unexpected status.');
    }
    final assessment = requireMap(json, 'assessment');
    final guidance = requireMap(json, 'guidance');

    final results = <Subscale, SubscaleResult>{};
    for (final subscale in Subscale.values) {
      final score = SubscaleScore.fromJson(requireMap(assessment, subscale.key));
      final advice =
          SubscaleGuidance.fromJson(requireMap(guidance, subscale.key));
      if (score.severity != advice.severity) {
        throw FormatException(
          'Severity mismatch between score and guidance for '
          '"${subscale.key}".',
        );
      }
      results[subscale] = SubscaleResult(
        subscale: subscale,
        score: score,
        guidance: advice,
      );
    }

    return AssessmentResponse(
      results: Map<Subscale, SubscaleResult>.unmodifiable(results),
      notice: requireString(json, 'notice'),
    );
  }

  final Map<Subscale, SubscaleResult> results;
  final String notice;

  SubscaleResult operator [](Subscale subscale) => results[subscale]!;
}