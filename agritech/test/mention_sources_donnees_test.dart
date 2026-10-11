import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agritech/features/recommandations/presentation/widgets/mention_sources_donnees.dart';

/// Vérifie la formulation de la mention de provenance.
///
/// C'est le mécanisme de repli du moteur rendu visible à l'agriculteur : une
/// aptitude calculée sur une moyenne de zone n'a pas la même portée qu'une
/// aptitude calculée sur une mesure du sol de sa parcelle. La formulation doit
/// donc nommer la zone, et pas se contenter de « moyenne de zone ».
void main() {
  Future<void> afficher(
    WidgetTester tester, {
    required Map<String, String> sources,
    String? zone,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MentionSourcesDonnees(
            sources: sources,
            zoneAgroecologique: zone,
          ),
        ),
      ),
    );
  }

  String texteAffiche(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text)).data!;

  testWidgets('nomme la zone quand le moteur se replie sur ses moyennes',
      (tester) async {
    await afficher(
      tester,
      sources: {'sol': 'moyenne de zone'},
      zone: 'Bassin arachidier',
    );

    expect(texteAffiche(tester), 'Sol : moyenne de la zone Bassin arachidier');
  });

  testWidgets('conserve le nom de la source quand la mesure est temps réel',
      (tester) async {
    await afficher(
      tester,
      sources: {'climat': 'NASA POWER (temps réel)'},
      zone: 'Casamance',
    );

    expect(texteAffiche(tester), 'Climat : NASA POWER (temps réel)');
  });

  testWidgets('distingue les blocs mesurés des blocs repliés', (tester) async {
    await afficher(
      tester,
      sources: {
        'sol': 'SoilGrids (temps réel)',
        'climat': 'moyenne de zone',
      },
      zone: 'Niayes',
    );

    expect(
      texteAffiche(tester),
      'Sol : SoilGrids (temps réel) · Climat : moyenne de la zone Niayes',
    );
  });

  testWidgets('reste lisible sans zone connue', (tester) async {
    await afficher(tester, sources: {'sol': 'moyenne de zone'});

    expect(texteAffiche(tester), 'Sol : moyenne de zone');
  });

  testWidgets('affiche la zone seule quand l\'origine est inconnue',
      (tester) async {
    // Cas de l'historique : l'origine vit sur l'AnalyseParcelle et n'est pas
    // dupliquée sur chaque recommandation persistée.
    await afficher(tester, sources: const {}, zone: 'Sénégal oriental');

    expect(texteAffiche(tester), 'Zone agroécologique : Sénégal oriental');
  });

  testWidgets('ne montre rien quand il n\'y a aucune information',
      (tester) async {
    await afficher(tester, sources: const {});

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('porte une icône d\'information', (tester) async {
    await afficher(
      tester,
      sources: {'sol': 'moyenne de zone'},
      zone: 'Vallée du Fleuve',
    );

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });
}
