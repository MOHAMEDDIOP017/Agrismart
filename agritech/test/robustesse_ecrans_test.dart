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

/// Monte chaque écran principal dans les conditions du terrain.
///
/// La tâche 6 demandait de vérifier chaque écran en mode sombre, à 130 % de
/// taille de texte et sur un écran étroit de 360 dp. Regarder trente-huit
/// écrans à l'œil, dans quatre conditions, reviendrait à cent cinquante
/// relectures à refaire à chaque retouche. Ce fichier monte les écrans
/// prioritaires et leurs états dans les quatre combinaisons, et échoue si le
/// rendu lève quoi que ce soit.
///
/// Ce que le contrôle attrape : un `Row` qui dépasse sa largeur, une colonne
/// plus haute que son parent, une contrainte infinie, une couleur absente du
/// thème sombre, une division par zéro dans un calcul de barre. Flutter signale
/// chacun de ces cas par une exception pendant la disposition ou la peinture,
/// et `takeException` la récupère.
///
/// Ce qu'il n'attrape pas : un texte tronqué par `TextOverflow.ellipsis`, un
/// contraste insuffisant, un élément hors de la zone visible d'un conteneur qui
/// découpe. Ces trois-là ne lèvent rien et restent du ressort des planches
/// (`apercu_ecrans_test.dart`) et du test de contraste.
///
/// Les animations sont laissées actives, à l'inverse des planches qui les
/// désactivent pour rester déterministes : le contrôle exerce ainsi le chemin
/// réellement suivi sur le téléphone, apparitions en cascade comprises.
void main() {
  /// Les quatre conditions de terrain. La largeur reste à 360 dp partout,
  /// taille des téléphones d'entrée de gamme visés ; seules la luminosité et
  /// l'échelle de texte varient.
  const conditions = <String, (bool, double)>{
    'clair': (false, 1.0),
    'sombre': (true, 1.0),
    'clair à 130 %': (false, 1.3),
    'sombre à 130 %': (true, 1.3),
  };

  /// Monte [ecran] et rend la main une fois les apparitions terminées.
  ///
  /// Les durées sont fixes plutôt qu'un `pumpAndSettle` : l'indicateur de
  /// saisie de l'assistant et le miroitement des squelettes tournent sans fin,
  /// et l'attente ne se terminerait jamais. Le total dépasse le plafond de
  /// décalage de la cascade (600 ms), pour qu'aucun minuteur ne reste en
  /// suspens à la fin du test.
  Future<void> monter(
    WidgetTester tester, {
    required Widget ecran,
    required List<Override> donnees,
    required bool sombre,
    required double echelleTexte,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: donnees,
      child: MaterialApp(
        theme: sombre ? AppTheme.darkTheme : AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr', 'FR'),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(echelleTexte)),
          child: ecran,
        ),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.takeException(),
      isNull,
      reason: 'Le rendu a levé une exception. Un dépassement de disposition '
          'apparaît ici avant de se voir sur un téléphone.',
    );
  }

  /// Déroule les quatre conditions pour un écran donné.
  void verifier(
    String nom, {
    required Widget Function() ecran,
    required List<Override> Function() donnees,
  }) {
    group(nom, () {
      conditions.forEach((etiquette, reglage) {
        final (sombre, echelle) = reglage;
        testWidgets(etiquette, (tester) async {
          await monter(
            tester,
            ecran: ecran(),
            donnees: donnees(),
            sombre: sombre,
            echelleTexte: echelle,
          );
        });
      });
    });
  }

  // ── Accueil de l'agriculteur ───────────────────────────────────────────────

  verifier(
    'Accueil',
    ecran: () => const DashboardScreen(),
    donnees: donneesAccueil,
  );

  verifier(
    'Accueil au premier lancement',
    ecran: () => const DashboardScreen(),
    donnees: () => donneesAccueil(avecChamps: false, avecReco: false),
  );

  // ── Parcelles ──────────────────────────────────────────────────────────────

  verifier(
    'Liste des champs',
    ecran: () => const ChampsListScreen(),
    donnees: donneesChamps,
  );

  verifier(
    'Liste des champs vide',
    ecran: () => const ChampsListScreen(),
    donnees: () => donneesChamps(avecChamps: false),
  );

  verifier(
    'Détail du champ',
    ecran: () => const ChampDetailScreen(champId: 'c1'),
    donnees: donneesChamps,
  );

  // ── Recommandation, dans ses quatre états ──────────────────────────────────

  verifier(
    'Recommandation, choix de la parcelle',
    ecran: () => const RecommandationsScreen(),
    donnees: () =>
        donneesReco(const RecommandationState(champIdSelectionne: 'c1')),
  );

  verifier(
    'Recommandation, analyse en cours',
    ecran: () => const RecommandationsScreen(),
    donnees: () => donneesReco(const RecommandationState(
      champIdSelectionne: 'c1',
      isAnalysing: true,
      progressMessage: 'Lecture du sol et du climat de la parcelle…',
    )),
  );

  verifier(
    'Recommandation, résultats',
    ecran: () => const RecommandationsScreen(),
    donnees: () => donneesReco(resultatsDemo),
  );

  verifier(
    'Recommandation, erreur réseau',
    ecran: () => const RecommandationsScreen(),
    donnees: () => donneesReco(const RecommandationState(
      champIdSelectionne: 'c1',
      error: 'La connexion est faible.',
    )),
  );

  // ── Assistant ──────────────────────────────────────────────────────────────

  verifier(
    'Assistant, conversation vide',
    ecran: () => const ChatScreen(),
    donnees: () => donneesAssistant(const ChatState()),
  );

  verifier(
    'Assistant, conversation en cours',
    ecran: () => const ChatScreen(),
    donnees: () => donneesAssistant(conversationDemo),
  );

  // ── File de validation de l'expert ─────────────────────────────────────────

  verifier(
    'File de validation',
    ecran: () => const RecommandationsExpertScreen(),
    donnees: () => donneesValidation(fileDemo),
  );
}
