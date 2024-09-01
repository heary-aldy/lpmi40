import 'package:flutter_test/flutter_test.dart';
import 'package:lpmi_24/main.dart'; // Correct package path

void main() {
  testWidgets('MyApp loads correctly', (WidgetTester tester) async {
    // Test to ensure the MyApp widget loads without errors
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
