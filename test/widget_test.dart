import 'package:flutter_test/flutter_test.dart';
import 'package:my_strava/main.dart';

void main() {
  testWidgets('MyStravaApp render smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyStravaApp());
    await tester.pump();

    // Pastikan label navigasi tab muncul
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Rekam'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
