import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agritech/app.dart';

void main() {
  testWidgets('KoobalaTech smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KoobalaTechApp()),
    );
    expect(find.byType(KoobalaTechApp), findsOneWidget);
  });
}
