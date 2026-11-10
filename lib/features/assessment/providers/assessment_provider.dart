import 'package:flutter/foundation.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/models/assessment_request.dart';
import 'package:muni_app/models/check_in_result.dart';

/// Holds answers IN MEMORY ONLY. Never persist or log these values.
class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider({required this.itemCount})
      : _answers = List<int?>.filled(itemCount, null);

  final int itemCount;
  final List<int?> _answers;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _disposed = false;

  int get currentIndex => _currentIndex;
  int? get currentAnswer => _answers[_currentIndex];
  int? answerAt(int index) => _answers[index];

  int get answeredCount => _answers.where((a) => a != null).length;
  bool get isComplete => answeredCount == itemCount;
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == itemCount - 1;
  bool get isSubmitting => _isSubmitting;

  int? get firstUnansweredIndex {
    final index = _answers.indexOf(null);
    return index == -1 ? null : index;
  }

  void selectAnswer(int value) {
    RangeError.checkValueInInterval(value, 0, 3, 'value');
    _answers[_currentIndex] = value;
    notifyListeners();
  }

  void goTo(int index) {
    RangeError.checkValidIndex(index, _answers, 'index');
    _currentIndex = index;
    notifyListeners();
  }

  void next() {
    if (isLast) return;
    _currentIndex++;
    notifyListeners();
  }

  void previous() {
    if (isFirst) return;
    _currentIndex--;
    notifyListeners();
  }

  /// Returns responses in item order (index 0 = item 1).
  /// Throws [StateError] if any item is unanswered.
  List<int> buildResponses() {
    if (!isComplete) {
      throw StateError(
        'Assessment incomplete: $answeredCount of $itemCount answered.',
      );
    }
    return List<int>.unmodifiable(_answers.cast<int>());
  }

  /// Gets the ONE overall indicator from the server. The server does not
  /// store the answers. Answers are kept here if this throws, so the user
  /// can retry.
  Future<CheckInResult> checkIn(ApiService api) async {
    if (_isSubmitting) {
      throw StateError('Submission already in progress.');
    }
    final request = AssessmentRequest(buildResponses());

    _isSubmitting = true;
    notifyListeners();
    try {
      return await api.checkIn(request);
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}