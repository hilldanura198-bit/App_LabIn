import 'package:flutter_test/flutter_test.dart';
import 'package:labin/main.dart';

void main() {
  testWidgets('LabIN login renders and opens demo dashboard', (tester) async {
    await tester.pumpWidget(const LabInApp());
    await tester.pumpAndSettle();

    expect(find.text('LabIN'), findsWidgets);
    expect(find.text('Masuk ke LabIN'), findsOneWidget);
    expect(find.text('Lihat Demo Dashboard'), findsOneWidget);

    await tester.ensureVisible(find.text('Lihat Demo Dashboard'));
    await tester.tap(find.text('Lihat Demo Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard LabIN'), findsOneWidget);
    expect(find.text('Kalender'), findsWidgets);
    expect(find.text('Peminjaman'), findsWidgets);
  });
}
