// AR SCI Mobile App Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:ar_sci/main.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ARSciApp());

    // Verify that splash screen elements are present
    expect(find.text('AR SCI'), findsOneWidget);
    expect(find.text('Science Education Reimagined'), findsOneWidget);
  });
}
