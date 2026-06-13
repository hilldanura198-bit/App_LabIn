import 'package:flutter_test/flutter_test.dart';
import 'package:labin/main.dart';

void main() {
  testWidgets('LabIN dashboard renders as first screen', (tester) async {
    await tester.pumpWidget(const LabInApp());
    await tester.pumpAndSettle();

    expect(find.text('LabIN'), findsWidgets);
    expect(find.text('Dashboard LabIN'), findsOneWidget);
    expect(find.text('Kalender'), findsWidgets);
    expect(find.text('Peminjaman'), findsWidgets);
  });
}
