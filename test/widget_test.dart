import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labin/main.dart';

void main() {
  testWidgets('LabIN login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LabInApp());
    await tester.pump();

    expect(find.text('LabIN'), findsWidgets);
    expect(find.text('Masuk ke LabIN'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
  });
}
