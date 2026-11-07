import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muni_app/app.dart';
import 'package:muni_app/core/services/consent_storage.dart';

Future<ConsentStorage> _storageWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return ConsentStorage.create();
}

void main() {
  testWidgets('first launch shows the welcome screen', (tester) async {
    final storage = await _storageWith({});
    await tester.pumpWidget(MuniApp(consentStorage: storage));

    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('accepted consent opens home directly', (tester) async {
    final storage = await _storageWith({
      ConsentStorage.storageKey: ConsentStorage.currentConsentVersion,
    });
    await tester.pumpWidget(MuniApp(consentStorage: storage));

    expect(find.text('Start assessment'), findsOneWidget);
  });

  testWidgets('outdated consent version re-prompts', (tester) async {
    final storage = await _storageWith({
      ConsentStorage.storageKey: ConsentStorage.currentConsentVersion - 1,
    });
    await tester.pumpWidget(MuniApp(consentStorage: storage));

    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('consent button is disabled until all boxes are checked',
      (tester) async {
    final storage = await _storageWith({});
    await tester.pumpWidget(MuniApp(consentStorage: storage));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(FilledButton, 'I agree and continue');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    final boxes = find.byType(CheckboxListTile);
    expect(boxes, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(boxes.at(i));
      await tester.tap(boxes.at(i));
      await tester.pump();
    }

    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });
}