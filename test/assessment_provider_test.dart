import 'package:flutter_test/flutter_test.dart';
import 'package:muni_app/features/assessment/data/dass42_items.dart';
import 'package:muni_app/features/assessment/providers/assessment_provider.dart';

void main() {
  test('questionnaire has 42 items and 4 options valued 0-3', () {
    expect(dass42Items.length, 42);
    expect(dass42ResponseOptions.map((o) => o.value).toList(), [0, 1, 2, 3]);
  });

  group('AssessmentProvider', () {
    late AssessmentProvider a;

    setUp(() => a = AssessmentProvider(itemCount: 42));

    test('starts empty and incomplete', () {
      expect(a.answeredCount, 0);
      expect(a.isComplete, isFalse);
      expect(a.firstUnansweredIndex, 0);
    });

    test('answers survive navigating back and forward', () {
      a.selectAnswer(2);
      a.next();
      a.selectAnswer(1);
      a.previous();
      expect(a.currentAnswer, 2);
      a.next();
      expect(a.currentAnswer, 1);
    });

    test('rejects values outside 0-3', () {
      expect(() => a.selectAnswer(4), throwsRangeError);
      expect(() => a.selectAnswer(-1), throwsRangeError);
    });

    test('buildResponses throws until complete', () {
      a.selectAnswer(0);
      expect(() => a.buildResponses(), throwsStateError);
    });

    test('complete assessment builds 42 responses in item order', () {
      for (var i = 0; i < 42; i++) {
        a.goTo(i);
        a.selectAnswer(i % 4);
      }
      expect(a.isComplete, isTrue);
      expect(a.firstUnansweredIndex, isNull);

      final responses = a.buildResponses();
      expect(responses.length, 42);
      expect(responses[5], 1);
      expect(responses[41], 41 % 4);
    });

    test('navigation stays in bounds', () {
      a.previous();
      expect(a.currentIndex, 0);
      a.goTo(41);
      a.next();
      expect(a.currentIndex, 41);
      expect(() => a.goTo(42), throwsRangeError);
    });
  });
}