enum Severity {
  normal('Normal'),
  mild('Mild'),
  moderate('Moderate'),
  severe('Severe'),
  extremelySevere('Extremely Severe');

  const Severity(this.apiValue);

  /// Exact string used by the Django backend.
  final String apiValue;

  static Severity fromApi(Object? value) {
    for (final severity in Severity.values) {
      if (severity.apiValue == value) return severity;
    }
    throw const FormatException('Unknown severity value.');
  }
}