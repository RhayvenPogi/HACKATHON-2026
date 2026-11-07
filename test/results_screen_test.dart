import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_app/core/theme/app_theme.dart';
import 'package:muni_app/features/results/screens/results_screen.dart';
import 'package:muni_app/models/assessment_response.dart';

AssessmentResponse _response(Map<String, (int, String)> values) {
  Map<String, dynamic> score(int s, String sev) =>
      {'score': s, 'maximum_score': 42, 'severity': sev};
  Map<String, dynamic> guidance(String sev) => {
        'severity': sev,
        'title': 'Guidance title',
        'message': 'Guidance message',
        'recommendation': 'Guidance recommendation',
      };

  return AssessmentResponse.fromJson({
    'status': 'success',
    'assessment': {
      for (final e in values.entries) e.key: score(e.value.$1, e.value.$2),
    },
    'guidance': {
      for (final e in values.entries) e.key: guidance(e.value.$2),
    },
    'notice': 'Screening notice text.',
  });
}

Future<void> _pump(WidgetTester tester, AssessmentResponse result) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ResultsScreen(result: result, responses: List<int>.filled(42, 0)),
    ),
  );
}

void main() {
  testWidgets('shows all subscales, scores, severities and notice',
      (tester) async {
    await _pump(
      tester,
      _response({
        'depression': (0, 'Normal'),
        'anxiety': (10, 'Moderate'),
        'stress': (34, 'Extremely Severe'),
      }),
    );

    expect(find.text('Depression'), findsOneWidget);
    expect(find.text('Anxiety'), findsOneWidget);
    expect(find.text('Stress'), findsOneWidget);
    expect(find.text('10 / 42'), findsOneWidget);
    expect(find.text('34 / 42'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('Extremely Severe'), findsOneWidget);
    expect(find.text('Screening notice text.'), findsOneWidget);
  });

  testWidgets('elevated results show get-help actions', (tester) async {
    await _pump(
      tester,
      _response({
        'depression': (0, 'Normal'),
        'anxiety': (10, 'Moderate'),
        'stress': (0, 'Normal'),
      }),
    );

    expect(find.text('Get help now'), findsOneWidget);
    expect(find.text('Find a facility'), findsOneWidget);
  });

  testWidgets('all-normal results still point to support', (tester) async {
    await _pump(
      tester,
      _response({
        'depression': (0, 'Normal'),
        'anxiety': (0, 'Normal'),
        'stress': (0, 'Normal'),
      }),
    );

    expect(find.text('Get help now'), findsNothing);
    expect(find.text('Support is always available'), findsOneWidget);
    expect(find.text('See support options'), findsOneWidget);
  });
}