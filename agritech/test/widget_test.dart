import 'package:agritech/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AgriSmart smoke test', (WidgetTester tester) async {
    // L'écran d'accueil attend trois secondes puis lit les préférences pour
    // choisir sa destination. Sans ces deux lignes, le test se terminait avec
    // un minuteur encore en attente et le binding le signalait comme un échec.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      const ProviderScope(child: AgriSmartApp()),
    );
    expect(find.byType(AgriSmartApp), findsOneWidget);

    // Laisse le minuteur de l'écran d'accueil arriver à échéance.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
  });
}
