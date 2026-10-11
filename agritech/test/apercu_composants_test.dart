@Tags(['apercu'])
library;

import 'package:agritech/core/enums/statut_validation.dart';
import 'package:agritech/core/theme/app_spacing.dart';
import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/shared/reseau/connectivite.dart';
import 'package:agritech/shared/widgets/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rend une planche de tous les composants, en image, pour relecture.
///
/// Les tests de `composants_test.dart` vérifient des règles ; celui-ci sert à
/// regarder. Il produit trois images dans `test/goldens/` :
///
/// - la planche en mode clair,
/// - la même en mode sombre, le seul moyen de contrôler ce thème avant que les
///   écrans ne lisent leurs couleurs par `context.couleurs`,
/// - la même à 130 % de taille de texte, pour voir ce qui déborde.
///
/// Régénérer après une modification volontaire du thème :
///
///     flutter test test/apercu_composants_test.dart --update-goldens
///
/// Les écarts de rendu d'un système à l'autre font que ces images ne sont pas
/// un test de non-régression fiable en intégration continue. Elles sont ici
/// pour la relecture, et pour illustrer le mémoire.
void main() {
  Future<void> planche(
    WidgetTester tester, {
    required ThemeData theme,
    required double echelleTexte,
    required String fichier,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [estHorsLigneProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(echelleTexte)),
            child: const _Planche(),
          ),
        ),
      ),
    );

    // Laisse passer les décalages de cascade et le remplissage des barres.
    //
    // Deux pompages à durée fixe, et non `pumpAndSettle` : la planche contient
    // un bouton en cours d'envoi, dont l'indicateur tourne sans fin.
    // `pumpAndSettle` attendrait la fin d'une animation qui n'en a pas.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(_Planche),
      matchesGoldenFile('goldens/$fichier'),
    );
  }

  testWidgets('planche en mode clair', (tester) async {
    await planche(
      tester,
      theme: AppTheme.lightTheme,
      echelleTexte: 1.0,
      fichier: 'composants_clair.png',
    );
  });

  testWidgets('planche en mode sombre', (tester) async {
    await planche(
      tester,
      theme: AppTheme.darkTheme,
      echelleTexte: 1.0,
      fichier: 'composants_sombre.png',
    );
  });

  testWidgets('planche à 130 % de taille de texte', (tester) async {
    await planche(
      tester,
      theme: AppTheme.lightTheme,
      echelleTexte: 1.3,
      fichier: 'composants_clair_130.png',
    );
  });
}

class _Planche extends StatelessWidget {
  const _Planche();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BandeauHorsConnexion(),
            Padding(
              padding: const EdgeInsets.all(AppEspaces.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Titre('Boutons'),
                  AppBouton.principal(
                    libelle: 'Obtenir une recommandation',
                    icone: Icons.psychology_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppEspaces.xs),
                  AppBouton.principal(
                    libelle: 'Enregistrer',
                    icone: Icons.save_rounded,
                    enChargement: true,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppEspaces.xs),
                  AppBouton.secondaire(
                    libelle: 'Obtenir ma position GPS',
                    icone: Icons.my_location_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppEspaces.xs),
                  AppBouton.principal(
                    libelle: 'Supprimer ce champ',
                    icone: Icons.delete_outline_rounded,
                    ton: TonBouton.destructif,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppEspaces.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppBouton.texte(
                      libelle: 'Plus tard',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: AppEspaces.xs),
                  const AppBouton.principal(
                    libelle: 'Action indisponible',
                    onPressed: null,
                  ),
                  const _Titre('Badges de statut'),
                  Wrap(
                    spacing: AppEspaces.xs,
                    runSpacing: AppEspaces.xs,
                    children: [
                      for (final s in StatutValidation.values)
                        BadgeStatut.validation(s),
                      BadgeStatut.statutChamp('EN_COURS'),
                      BadgeStatut.statutChamp('EN_TRAITEMENT'),
                      BadgeStatut.rang(1),
                      BadgeStatut.rang(2),
                    ],
                  ),
                  const _Titre('Champ de saisie'),
                  const AppChampTexte(
                    libelle: 'Nom du champ',
                    exemple: 'Ex : Champ Nord Thiès',
                    icone: Icons.terrain_rounded,
                    obligatoire: true,
                  ),
                  const SizedBox(height: AppEspaces.sm),
                  const AppChampTexte(
                    libelle: 'Superficie',
                    exemple: '2,5',
                    icone: Icons.straighten_rounded,
                    suffixe: 'ha',
                    aide: 'Surface cultivable, en hectares.',
                  ),
                  const _Titre('Carte de culture'),
                  CarteCulture(
                    nomFrancais: 'Niébé',
                    nomWolof: 'ñebbe',
                    tauxAptitude: 87,
                    rang: 1,
                    miseEnValeur: true,
                    icone: Icons.scatter_plot_rounded,
                    badge: BadgeStatut.validation(StatutValidation.validee),
                    informations: const [
                      LigneInfoCulture(
                        icone: Icons.calendar_today_outlined,
                        texte: 'Semis de juin à juillet',
                      ),
                    ],
                    onTap: () {},
                  ),
                  const SizedBox(height: AppEspaces.entreCartes),
                  CarteCulture(
                    nomFrancais: 'Mil',
                    nomWolof: 'dugub',
                    tauxAptitude: 64,
                    rang: 2,
                    index: 1,
                    badge: BadgeStatut.validation(StatutValidation.enAttente),
                    onTap: () {},
                  ),
                  const SizedBox(height: AppEspaces.entreCartes),
                  CarteCulture(
                    nomFrancais: 'Maïs',
                    nomWolof: 'mbóq',
                    tauxAptitude: 38,
                    rang: 3,
                    index: 2,
                    badge: BadgeStatut.validation(StatutValidation.rejetee),
                    onTap: () {},
                  ),
                  const _Titre('Chargement en squelette'),
                  const SizedBox(height: 120, child: SqueletteCarteChamp()),
                ],
              ),
            ),
            const _Titre('État vide', marge: AppEspaces.md),
            const SizedBox(
              height: 420,
              child: EtatVide(
                titre: 'Aucun champ enregistré',
                message: 'Ajoutez votre première parcelle pour recevoir des '
                    'recommandations de culture.',
                libelleAction: 'Ajouter un champ',
                iconeAction: Icons.add_rounded,
                onAction: _rien,
              ),
            ),
            const _Titre('Erreur réseau', marge: AppEspaces.md),
            SizedBox(
              height: 420,
              child: EtatErreur(
                erreur: DioException(
                  requestOptions: RequestOptions(path: '/x'),
                  type: DioExceptionType.connectionError,
                ),
                onReessayer: _rien,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _rien() {}
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte, {this.marge = 0});

  final String texte;
  final double marge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(marge, AppEspaces.lg, marge, AppEspaces.xs),
      child: Text(texte, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
