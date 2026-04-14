import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('HelpingHandApp loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HelpingHandApp());
    expect(find.byType(HelpingHandApp), findsOneWidget);
  });
}