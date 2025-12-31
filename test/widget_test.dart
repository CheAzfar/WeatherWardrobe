import 'package:flutter_test/flutter_test.dart';
import 'package:weather_wardrobe/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherWardrobeApp());
    await tester.pump(); // let first frame build

    expect(find.byType(WeatherWardrobeApp), findsOneWidget);
  });
}
