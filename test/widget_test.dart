import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muni_app/app.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/features/home/screens/home_screen.dart';
import 'package:muni_app/features/onboarding/widgets/terms_sheet.dart';

Future<ConsentStorage> _storageWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return ConsentStorage.create();
}

/// Moves past the splash/intro timers without waiting for endless animations.
Future<void> _pastSplash(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Opens the Terms sheet; returns a getter for its result.
Future<bool? Function()> _openTerms(WidgetTester tester) async {
  bool? result;
  var closed = false;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              result = await showTermsSheet(ctx);
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('Terms and Conditions & User Consent'), findsOneWidget);
  return () {
    expect(closed, isTrue, reason: 'sheet should have closed');
    return result;
  };
}

void main() {
  testWidgets('first launch does not skip straight to home', (tester) async {
    final storage = await _storageWith({});
    await tester.pumpWidget(MuniApp(consentStorage: storage));
    await _pastSplash(tester);

    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('accepted consent opens home', (tester) async {
    final storage = await _storageWith({
      ConsentStorage.storageKey: ConsentStorage.currentConsentVersion,
    });
    await tester.pumpWidget(MuniApp(consentStorage: storage));
    await _pastSplash(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('outdated consent version re-prompts', (tester) async {
    final storage = await _storageWith({
      ConsentStorage.storageKey: ConsentStorage.currentConsentVersion - 1,
    });
    await tester.pumpWidget(MuniApp(consentStorage: storage));
    await _pastSplash(tester);

    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('Terms: agree is blocked until 18+ is confirmed',
      (tester) async {
    await _openTerms(tester);
    await tester.tap(find.text('I agree & continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Terms and Conditions & User Consent'), findsOneWidget);
  });

  testWidgets('Terms: 18+ then agree returns true', (tester) async {
    final result = await _openTerms(tester);
    await tester.tap(find.text('I am 18 years old or older.'));
    await tester.pump();
    await tester.tap(find.text('I agree & continue'));
    await tester.pumpAndSettle();
    expect(result(), isTrue);
  });

  testWidgets('Terms: declining does not give consent', (tester) async {
    final result = await _openTerms(tester);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(result(), isFalse);
  });

  testWidgets('Terms: dismissing the sheet does not give consent',
      (tester) async {
    final result = await _openTerms(tester);
    await tester.tapAt(const Offset(10, 10)); // tap the dimmed area above
    await tester.pumpAndSettle();
    expect(result(), isNull);
  });
}