@Tags(['apercu'])
library;

import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/features/champs/presentation/screens/champ_detail_screen.dart';
import 'package:agritech/features/champs/presentation/screens/champs_list_screen.dart';
import 'package:agritech/features/chat/presentation/providers/chat_provider.dart';
import 'package:agritech/features/chat/presentation/screens/chat_screen.dart';
import 'package:agritech/features/expert/presentation/screens/recommandations_expert_screen.dart';
import 'package:agritech/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:agritech/features/recommandations/presentation/providers/recommandation_provider.dart';
import 'package:agritech/features/recommandations/presentation/screens/recommandations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/donnees_demo.dart';

/// Captures des écrans repris au lot 4, pour relecture.
///
/// Les providers sont remplacés par des jeux de données fixes : l'objectif est
/// de regarder la mise en page, pas d'exercer les appels au serveur. Les
/// notifieurs réels sont sous-classés et seule leur méthode `build` est
/// redéfinie, ce qui évite de toucher à leur logique.
///
///     flutter test --run-skipped --tags apercu --update-goldens
void main() {
  Future<void> capture(
    WidgetTester tester, {
    required Widget ecran,
    required List<Override> donnees,
    required ThemeData theme,
    required double echelleTexte,
    required String fichier,
    Size taille = const Size(360, 800),
  }) async {
    await tester.binding.setSurfaceSize(taille);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: donnees,
      child: MaterialApp(
        theme: theme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr', 'FR'),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(echelleTexte),
            // Les captures montrent l'état final, pas une animation à
            // mi-course : les apparitions en cascade et les barres qui se
            // remplissent se posent directement à leur valeur. Cela rend les
            // images déterministes, et exerce au passage le chemin suivi
            // quand l'utilisateur réduit les animations de son téléphone.
            disableAnimations: true,
          ),
          child: ecran,
        ),
      ),
    ));

    // Durées fixes plutôt que `pumpAndSettle` : certains écrans portent un
    // indicateur qui tourne sans fin.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$fichier'),
    );
  }

  group('Assistant', () {
    testWidgets('conversation vide', (tester) async {
      await capture(
        tester,
        ecran: const ChatScreen(),
        donnees: donneesAssistant(const ChatState()),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'assistant_vide.png',
      );
    });

    testWidgets('conversation en cours', (tester) async {
      await capture(
        tester,
        ecran: const ChatScreen(),
        donnees: donneesAssistant(conversationDemo),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'assistant_conversation.png',
      );
    });

    testWidgets('conversation en mode sombre', (tester) async {
      await capture(
        tester,
        ecran: const ChatScreen(),
        donnees: donneesAssistant(conversationDemo),
        theme: AppTheme.darkTheme,
        echelleTexte: 1.0,
        fichier: 'assistant_sombre.png',
      );
    });
  });

  group('File de validation', () {
    testWidgets('mode clair', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsExpertScreen(),
        donnees: donneesValidation(fileDemo),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'validation_clair.png',
        taille: const Size(360, 1100),
      );
    });

    testWidgets('mode sombre', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsExpertScreen(),
        donnees: donneesValidation(fileDemo),
        theme: AppTheme.darkTheme,
        echelleTexte: 1.0,
        fichier: 'validation_sombre.png',
        taille: const Size(360, 1100),
      );
    });

    testWidgets('à 130 %', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsExpertScreen(),
        donnees: donneesValidation(fileDemo),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.3,
        fichier: 'validation_130.png',
        taille: const Size(360, 1400),
      );
    });
  });

  group('Recommandations', () {
    testWidgets('choix de la parcelle', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsScreen(),
        donnees:
            donneesReco(const RecommandationState(champIdSelectionne: 'c1')),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'reco_choix.png',
      );
    });

    testWidgets('analyse en cours', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsScreen(),
        donnees: donneesReco(const RecommandationState(
          champIdSelectionne: 'c1',
          isAnalysing: true,
          progressMessage: 'Lecture du sol et du climat de la parcelle…',
        )),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'reco_analyse.png',
      );
    });

    testWidgets('résultats, mode clair', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsScreen(),
        donnees: donneesReco(resultatsDemo),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'reco_resultats_clair.png',
        taille: const Size(360, 1100),
      );
    });

    testWidgets('résultats, mode sombre', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsScreen(),
        donnees: donneesReco(resultatsDemo),
        theme: AppTheme.darkTheme,
        echelleTexte: 1.0,
        fichier: 'reco_resultats_sombre.png',
        taille: const Size(360, 1100),
      );
    });

    testWidgets('résultats à 130 %', (tester) async {
      await capture(
        tester,
        ecran: const RecommandationsScreen(),
        donnees: donneesReco(resultatsDemo),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.3,
        fichier: 'reco_resultats_130.png',
        taille: const Size(360, 1400),
      );
    });
  });

  group('Mes champs', () {
    testWidgets('liste, mode clair', (tester) async {
      await capture(
        tester,
        ecran: const ChampsListScreen(),
        donnees: donneesChamps(),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'champs_liste_clair.png',
      );
    });

    testWidgets('liste vide', (tester) async {
      await capture(
        tester,
        ecran: const ChampsListScreen(),
        donnees: donneesChamps(avecChamps: false),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'champs_liste_vide.png',
      );
    });

    testWidgets('détail, mode clair', (tester) async {
      await capture(
        tester,
        ecran: const ChampDetailScreen(champId: 'c1'),
        donnees: donneesChamps(),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'champ_detail_clair.png',
        taille: const Size(360, 1000),
      );
    });

    testWidgets('détail, mode sombre', (tester) async {
      await capture(
        tester,
        ecran: const ChampDetailScreen(champId: 'c1'),
        donnees: donneesChamps(),
        theme: AppTheme.darkTheme,
        echelleTexte: 1.0,
        fichier: 'champ_detail_sombre.png',
        taille: const Size(360, 1000),
      );
    });

    testWidgets('détail à 130 %', (tester) async {
      await capture(
        tester,
        ecran: const ChampDetailScreen(champId: 'c1'),
        donnees: donneesChamps(),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.3,
        fichier: 'champ_detail_130.png',
        taille: const Size(360, 1200),
      );
    });
  });

  group('Accueil agriculteur', () {
    testWidgets('mode clair', (tester) async {
      await capture(
        tester,
        ecran: const DashboardScreen(),
        donnees: donneesAccueil(),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'accueil_clair.png',
      );
    });

    testWidgets('mode sombre', (tester) async {
      await capture(
        tester,
        ecran: const DashboardScreen(),
        donnees: donneesAccueil(),
        theme: AppTheme.darkTheme,
        echelleTexte: 1.0,
        fichier: 'accueil_sombre.png',
      );
    });

    testWidgets('à 130 % de taille de texte', (tester) async {
      await capture(
        tester,
        ecran: const DashboardScreen(),
        donnees: donneesAccueil(),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.3,
        fichier: 'accueil_clair_130.png',
      );
    });

    testWidgets('premier lancement, sans parcelle ni recommandation',
        (tester) async {
      // L'état vide est un écran à part entière : c'est celui que voit un
      // agriculteur qui vient d'installer l'application.
      await capture(
        tester,
        ecran: const DashboardScreen(),
        donnees: donneesAccueil(avecChamps: false, avecReco: false),
        theme: AppTheme.lightTheme,
        echelleTexte: 1.0,
        fichier: 'accueil_vide.png',
      );
    });
  });
}
