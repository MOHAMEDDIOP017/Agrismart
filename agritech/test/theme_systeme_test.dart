import 'package:agritech/core/theme/app_colors.dart';
import 'package:agritech/core/theme/app_motion.dart';
import 'package:agritech/core/theme/app_radius.dart';
import 'package:agritech/core/theme/app_spacing.dart';
import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie les règles que le système de design s'impose à lui-même.
///
/// Les contraintes de ce projet sont chiffrées : plancher de 14 px pour un
/// texte utile, échelle d'espacement sur une base de 4, aucune animation
/// au-delà de 400 ms, zone tactile de 48 dp. Écrites seulement en commentaire,
/// elles se perdent au bout de quelques semaines de développement. Vérifiées
/// ici, elles cassent la suite de tests dès qu'une valeur sort du cadre.
void main() {
  group('Typographie', () {
    // Lu dans un `setUp` et non au niveau du groupe : la construction du style
    // passe par `google_fonts`, qui a besoin d'un binding initialisé. Le
    // niveau du groupe est evalue a la collecte, avant tout binding.
    late TextTheme typo;
    setUp(() => typo = AppTypography.textTheme);

    test('aucun style ne descend sous 14 px', () {
      final styles = <String, TextStyle?>{
        'displayLarge': typo.displayLarge,
        'displayMedium': typo.displayMedium,
        'displaySmall': typo.displaySmall,
        'headlineLarge': typo.headlineLarge,
        'headlineMedium': typo.headlineMedium,
        'headlineSmall': typo.headlineSmall,
        'titleLarge': typo.titleLarge,
        'titleMedium': typo.titleMedium,
        'titleSmall': typo.titleSmall,
        'bodyLarge': typo.bodyLarge,
        'bodyMedium': typo.bodyMedium,
        'bodySmall': typo.bodySmall,
        'labelLarge': typo.labelLarge,
        'labelMedium': typo.labelMedium,
        'labelSmall': typo.labelSmall,
      };

      for (final entree in styles.entries) {
        final taille = entree.value?.fontSize;
        expect(taille, isNotNull, reason: '${entree.key} sans taille');
        expect(
          taille,
          greaterThanOrEqualTo(AppTypography.taillePlancher),
          reason: '${entree.key} à ${taille}px, sous le plancher de '
              '${AppTypography.taillePlancher}px. L\'audit avait relevé 78 '
              'déclarations sous 12px, illisibles en plein soleil.',
        );
      }
    });

    test('le corps de texte par défaut est à la taille de base', () {
      // `bodyMedium` est le style qu'un widget `Text` sans style explicite
      // reçoit : c'est lui qui fixe la taille de lecture de l'application.
      expect(typo.bodyMedium?.fontSize, AppTypography.tailleBase);
    });

    test('aucune graisse fine', () {
      // Un texte en graisse 100 à 300 se délave sous une forte luminosité.
      final graisses = [
        typo.bodySmall?.fontWeight,
        typo.bodyMedium?.fontWeight,
        typo.bodyLarge?.fontWeight,
        typo.labelSmall?.fontWeight,
        typo.labelMedium?.fontWeight,
        typo.labelLarge?.fontWeight,
      ];
      for (final g in graisses) {
        expect(g!.index, greaterThanOrEqualTo(FontWeight.w400.index));
      }
    });

    test('les styles ne portent pas de couleur', () {
      // Une couleur figée dans le style rend le mode sombre impossible :
      // c'était le défaut de la version précédente, qui écrivait
      // `AppColors.textPrimary` dans chacun des quinze styles. La couleur est
      // appliquée par `ThemeData` au moment de la construction du thème.
      expect(typo.bodyMedium?.color, isNull);
      expect(typo.titleLarge?.color, isNull);
      expect(typo.labelSmall?.color, isNull);
    });
  });

  group('Espacement', () {
    test('tous les crans sont des multiples de 4', () {
      const crans = [
        AppEspaces.xxs,
        AppEspaces.xs,
        AppEspaces.sm,
        AppEspaces.md,
        AppEspaces.lg,
        AppEspaces.xl,
        AppEspaces.xxl,
      ];
      for (final cran in crans) {
        expect(cran % 4, 0, reason: '$cran n\'est pas un multiple de 4');
      }
      expect(crans, [4, 8, 12, 16, 24, 32, 48]);
    });

    test('l\'échelle est strictement croissante', () {
      const crans = [
        AppEspaces.xxs,
        AppEspaces.xs,
        AppEspaces.sm,
        AppEspaces.md,
        AppEspaces.lg,
        AppEspaces.xl,
        AppEspaces.xxl,
      ];
      for (var i = 1; i < crans.length; i++) {
        expect(crans[i], greaterThan(crans[i - 1]));
      }
    });
  });

  group('Rayons', () {
    test('trois valeurs, du plus contenant au plus cliquable', () {
      // L'audit avait relevé 14 valeurs distinctes, de 2 à 50.
      expect(AppRayons.champ, 8);
      expect(AppRayons.carte, 12);
      expect(AppRayons.bouton, 24);
      expect(AppRayons.champ, lessThan(AppRayons.carte));
      expect(AppRayons.carte, lessThan(AppRayons.bouton));
    });

    test('la pastille reste une capsule à toute taille de texte', () {
      // Le rayon doit dépasser la moitié de la plus grande hauteur possible,
      // soit un libellé de 14px à 200 % avec ses marges intérieures.
      expect(AppRayons.pastille, greaterThan(200));
    });
  });

  group('Mouvement', () {
    test('aucune transition ne dépasse 400 ms', () {
      for (final duree in AppDurees.transitions) {
        expect(
          duree.inMilliseconds,
          lessThanOrEqualTo(AppDurees.plafond.inMilliseconds),
          reason: 'Une transition de ${duree.inMilliseconds} ms dépasse le '
              'plafond de ${AppDurees.plafond.inMilliseconds} ms. L\'audit '
              'avait relevé 1 200 ms sur la barre d\'aptitude et 700 ms sur '
              'le carrousel du tableau de bord.',
        );
      }
    });

    test('le décalage de cascade vaut 100 ms', () {
      // Trois conventions coexistaient : 150 ms, 80 ms, et des délais fixes.
      expect(AppDurees.cascade.inMilliseconds, 100);
    });

    testWidgets('la réduction des animations annule les durées',
        (tester) async {
      late BuildContext contexteNormal;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            contexteNormal = context;
            return const SizedBox();
          }),
        ),
      );
      expect(AppMouvement.reduit(contexteNormal), isFalse);
      expect(AppMouvement.duree(contexteNormal, AppDurees.moyenne),
          AppDurees.moyenne);
      expect(AppMouvement.decalage(contexteNormal, 2), AppDurees.cascade * 2);

      late BuildContext contexteReduit;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(builder: (context) {
              contexteReduit = context;
              return const SizedBox();
            }),
          ),
        ),
      );
      expect(AppMouvement.reduit(contexteReduit), isTrue);
      expect(
          AppMouvement.duree(contexteReduit, AppDurees.moyenne), Duration.zero);
      expect(AppMouvement.decalage(contexteReduit, 2), Duration.zero);
    });

    testWidgets('le décalage de cascade est plafonné', (tester) async {
      // Sans plafond, une liste de trente champs ferait attendre le dernier
      // élément trois secondes.
      late BuildContext contexte;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            contexte = context;
            return const SizedBox();
          }),
        ),
      );
      final rang30 = AppMouvement.decalage(contexte, 30);
      expect(rang30, AppDurees.cascade * 6);
      expect(rang30.inMilliseconds, lessThanOrEqualTo(600));
    });
  });

  group('Thème', () {
    test('les deux modes exposent les jetons sémantiques', () {
      // Sans cette extension, `context.couleurs` retomberait sur le jeu clair
      // et le mode sombre serait silencieusement inopérant.
      expect(AppTheme.lightTheme.extension<CouleursAgriSmart>(), isNotNull);
      expect(AppTheme.darkTheme.extension<CouleursAgriSmart>(), isNotNull);
      expect(AppTheme.lightTheme.extension<CouleursAgriSmart>(),
          CouleursAgriSmart.clair);
      expect(AppTheme.darkTheme.extension<CouleursAgriSmart>(),
          CouleursAgriSmart.sombre);
    });

    test('les boutons atteignent la zone tactile de 48 dp', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final hauteurs = [
          theme.elevatedButtonTheme.style?.minimumSize?.resolve({})?.height,
          theme.outlinedButtonTheme.style?.minimumSize?.resolve({})?.height,
          theme.textButtonTheme.style?.minimumSize?.resolve({})?.height,
        ];
        for (final hauteur in hauteurs) {
          expect(hauteur, isNotNull);
          expect(hauteur, greaterThanOrEqualTo(48));
        }
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      }
    });

    test('le fond de page suit le mode d\'affichage', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor,
          CouleursAgriSmart.clair.fond);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          CouleursAgriSmart.sombre.fond);
    });

    test('le libellé des champs reste visible pendant la saisie', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.inputDecorationTheme.floatingLabelBehavior,
            FloatingLabelBehavior.always);
      }
    });

    test('les deux barres de navigation partagent le même style', () {
      // L'application utilisait Material 2 pour l'agriculteur et l'expert,
      // Material 3 pour l'administrateur, avec deux rendus d'onglet actif.
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final c = theme.extension<CouleursAgriSmart>()!;
        expect(theme.bottomNavigationBarTheme.selectedItemColor, c.primaire);
        expect(theme.bottomNavigationBarTheme.backgroundColor, c.surface);
        expect(theme.navigationBarTheme.backgroundColor, c.surface);
        expect(theme.navigationBarTheme.labelBehavior,
            NavigationDestinationLabelBehavior.alwaysShow);
        // Les libellés des deux états ont la même taille : faire grossir
        // l'onglet actif décale ses voisins sans rien signaler. La distinction
        // passe par la graisse, la couleur et l'icône pleine.
        final actif = theme.bottomNavigationBarTheme.selectedLabelStyle;
        final inactif = theme.bottomNavigationBarTheme.unselectedLabelStyle;
        expect(actif?.fontSize, inactif?.fontSize);
        expect(
            actif?.fontWeight?.index, greaterThan(inactif!.fontWeight!.index));
        expect(theme.bottomNavigationBarTheme.unselectedItemColor,
            c.texteSecondaire);
      }
    });

    test('les cartes se détachent par un trait et non par une ombre', () {
      // Une ombre se recalcule à chaque rendu et ne se voit pas en extérieur.
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.cardTheme.elevation, 0);
        final forme = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(forme.side.style, BorderStyle.solid);
        expect(forme.borderRadius, AppRayons.brCarte);
      }
    });

    test('l\'effet d\'appui évite le shader de Material 3', () {
      // `InkSparkle`, par défaut sur Android, compile un shader au premier
      // appui et provoque une saccade visible sur un GPU modeste.
      expect(AppTheme.lightTheme.splashFactory, InkRipple.splashFactory);
      expect(AppTheme.darkTheme.splashFactory, InkRipple.splashFactory);
    });
  });
}
