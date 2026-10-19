import 'package:flutter_test/flutter_test.dart';
import 'package:truco/main.dart';

void main() {
  testWidgets('TrucoApp smoke test loads LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();

    expect(find.text('TRUCO AMIGOS'), findsOneWidget);
    expect(find.text('JOGAR COMO CONVIDADO'), findsOneWidget);
  });
}