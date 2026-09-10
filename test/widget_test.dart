import 'package:flutter_test/flutter_test.dart';

import 'package:tringgling_slide/main.dart';
import 'package:tringgling_slide/ui/game_screen.dart';

void main() {
  testWidgets('Game screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
