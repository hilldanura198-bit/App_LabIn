import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labin/main.dart';

void main() {
  testWidgets('LabIn onboarding then login screen renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LabInApp());
    await tester.pump();

    expect(find.text('LabIn'), findsWidgets);
    expect(
      find.text('Inventaris lab dalam satu ruang digital.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke LabIn'), findsOneWidget);
    expect(find.text('Email Login'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
  });
}
