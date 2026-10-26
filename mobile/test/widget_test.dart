import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('LangNest Mobile smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LangNestMobileApp(initialLoggedIn: false));
    expect(find.text('LangNest'), findsOneWidget);
  });
}
