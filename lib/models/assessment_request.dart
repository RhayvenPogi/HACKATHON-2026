class AssessmentRequest {
  AssessmentRequest(List<int> responses)
      : responses = List<int>.unmodifiable(responses) {
    if (responses.length != itemCount) {
      throw ArgumentError(
        'Expected $itemCount responses, got ${responses.length}.',
      );
    }
    if (responses.any((r) => r < 0 || r > 3)) {
      throw ArgumentError('Every response must be between 0 and 3.');
    }
  }

  static const int itemCount = 21;

  final List<int> responses;

  Map<String, dynamic> toJson() => {'responses': responses};
}