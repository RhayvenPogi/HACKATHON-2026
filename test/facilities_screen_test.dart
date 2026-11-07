import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muni_app/core/theme/app_theme.dart';
import 'package:muni_app/features/facilities/screens/facilities_screen.dart';

void main() {
  testWidgets('shows sample banner, lists facilities, opens details',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const FacilitiesScreen(showMapTiles: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('SAMPLE DATA'), findsOneWidget);
    expect(find.text('Sample Facility A'), findsOneWidget);
    expect(find.text('Directions'), findsNothing);

    await tester.tap(find.text('Sample Facility A'));
    await tester.pumpAndSettle();

    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Sample data: not a real facility'), findsOneWidget);
  });
}