@Tags(['apercu'])
library;

import 'package:agritech/core/theme/app_spacing.dart';
import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Planche des trois barres de navigation, pour relecture.
///
/// Les trois rôles y figurent avec leur onglet actif, afin de vérifier d'un
/// coup d'œil que l'état courant se distingue nettement et que les libellés
/// tiennent à 360 dp.
///
///     flutter test --run-skipped --tags apercu --update-goldens
void main() {
  Future<void> planche(
    WidgetTester tester, {
    required ThemeData theme,
    required double echelleTexte,
    required String fichier,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(echelleTexte)),
        child: const _Planche(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(_Planche),
      matchesGoldenFile('goldens/$fichier'),
    );
  }

  testWidgets('barres de navigation, mode clair', (tester) async {
    await planche(
      tester,
      theme: AppTheme.lightTheme,
      echelleTexte: 1.0,
      fichier: 'navigation_clair.png',
    );
  });

  testWidgets('barres de navigation, mode sombre', (tester) async {
    await planche(
      tester,
      theme: AppTheme.darkTheme,
      echelleTexte: 1.0,
      fichier: 'navigation_sombre.png',
    );
  });

  testWidgets('barres de navigation à 130 %', (tester) async {
    await planche(
      tester,
      theme: AppTheme.lightTheme,
      echelleTexte: 1.3,
      fichier: 'navigation_clair_130.png',
    );
  });
}

class _Planche extends StatelessWidget {
  const _Planche();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppEspaces.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Titre('Agriculteur'),
            BarreNavigation(
              indexActif: 0,
              onChange: _rien,
              destinations: [
                DestinationNavigation(
                  libelle: 'Accueil',
                  icone: Icons.home_outlined,
                  iconeActive: Icons.home_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Champs',
                  icone: Icons.terrain_outlined,
                  iconeActive: Icons.terrain_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Assistant',
                  icone: Icons.forum_outlined,
                  iconeActive: Icons.forum_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Profil',
                  icone: Icons.person_outline,
                  iconeActive: Icons.person_rounded,
                ),
              ],
            ),
            _Titre('Expert, avec les recommandations en attente'),
            BarreNavigation(
              indexActif: 0,
              onChange: _rien,
              destinations: [
                DestinationNavigation(
                  libelle: 'À valider',
                  icone: Icons.fact_check_outlined,
                  iconeActive: Icons.fact_check_rounded,
                  compteur: 12,
                ),
                DestinationNavigation(
                  libelle: 'Champs',
                  icone: Icons.terrain_outlined,
                  iconeActive: Icons.terrain_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Conseils',
                  icone: Icons.chat_bubble_outline,
                  iconeActive: Icons.chat_bubble_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Profil',
                  icone: Icons.person_outline,
                  iconeActive: Icons.person_rounded,
                ),
              ],
            ),
            _Titre('Administrateur, troisième onglet actif'),
            BarreNavigation(
              indexActif: 2,
              onChange: _rien,
              destinations: [
                DestinationNavigation(
                  libelle: 'Accueil',
                  icone: Icons.dashboard_outlined,
                  iconeActive: Icons.dashboard_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Comptes',
                  icone: Icons.people_outline,
                  iconeActive: Icons.people_rounded,
                ),
                DestinationNavigation(
                  libelle: 'Experts',
                  icone: Icons.assignment_ind_outlined,
                  iconeActive: Icons.assignment_ind,
                ),
                DestinationNavigation(
                  libelle: 'Chiffres',
                  icone: Icons.bar_chart_outlined,
                  iconeActive: Icons.bar_chart_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _rien(int _) {}
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppEspaces.md,
        AppEspaces.lg,
        AppEspaces.md,
        AppEspaces.xs,
      ),
      child: Text(texte, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
