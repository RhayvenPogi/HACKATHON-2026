import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_app/features/results/screens/check_in_complete_screen.dart';
import 'package:muni_app/models/check_in_result.dart';

void main() {
  Future<void> pump(WidgetTester tester, ScreeningLevel level) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: CheckInCompleteScreen(
        responses: List<int>.filled(21, 3),
        result: CheckInResult(level: level, notice: 'Not a diagnosis.'),
      ),
    ));
  }

  testWidgets('shows one overall indicator and no subscale scores',
      (tester) async {
    await pump(tester, ScreeningLevel.high);
    expect(find.text('Overall screening indicator'), findsOneWidget);
    expect(find.textContaining('high level of distress'), findsOneWidget);
    expect(find.textContaining('/ 21'), findsNothing);
    expect(find.text('Extremely Severe'), findsNothing);
    expect(find.text('Depression'), findsNothing);
  });

  testWidgets('low result still points to support', (tester) async {
    await pump(tester, ScreeningLevel.low);
    expect(find.textContaining('does not rule out a concern'), findsOneWidget);
    expect(find.text('Need help now?'), findsOneWidget);
    expect(find.text('Share with a professional'), findsOneWidget);
  });
}