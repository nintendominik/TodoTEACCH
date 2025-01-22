import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/pages/home_page.dart';

void main() {
  testWidgets('HomePage buttons test', (WidgetTester tester) async {
    // Build the HomePage widget and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Betreuermodus'), findsOneWidget);
  });
}
