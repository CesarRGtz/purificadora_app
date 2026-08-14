// Default test file - updated for the purificadora app
import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PurificadoraApp());
    expect(find.text('Purificadora'), findsOneWidget);
  });
}
