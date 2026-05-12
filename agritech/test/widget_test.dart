import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agritech/app.dart';

void main() {
  testWidgets('AgriSmart smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AgriSmartApp()),
    );
    expect(find.byType(AgriSmartApp), findsOneWidget);
  });
}
