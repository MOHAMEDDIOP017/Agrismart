import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Thèmes clair et sombre d'AgriSmart.
///
/// Les deux sont construits par la même fonction, [_construire], à partir d'un
/// jeu de jetons [CouleursAgriSmart]. Un composant stylé une fois l'est donc
/// dans les deux modes, et il devient impossible d'en soigner un et d'oublier
/// l'autre.
///
/// Deux choix portent sur les performances, parce que l'application doit
/// rester fluide sur un téléphone d'entrée de gamme.
///
/// Les cartes sont séparées du fond par un trait et non par une ombre
/// (`elevation: 0`). Une ombre se recalcule à chaque rendu et se cumule mal
/// quand plusieurs cartes se chevauchent au défilement ; un trait de 1 px
/// coûte un rectangle. Le contraste obtenu est aussi plus franc en extérieur,
/// où une ombre diffuse ne se voit pas.
///
/// L'effet d'appui utilise `InkRipple` et non `InkSparkle`, que Material 3
/// installe par défaut sur Android. `InkSparkle` passe par un shader
/// fragmentaire dont la première compilation provoque une saccade visible sur
/// un GPU modeste.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme =>
      _construire(CouleursAgriSmart.clair, Brightness.light);

  static ThemeData get darkTheme =>
      _construire(CouleursAgriSmart.sombre, Brightness.dark);

  static ThemeData _construire(CouleursAgriSmart c, Brightness luminosite) {
    final sombre = luminosite == Brightness.dark;

    final schema = ColorScheme(
      brightness: luminosite,
      primary: c.primaire,
      onPrimary: c.surPrimaire,
      primaryContainer: c.primaireVoile,
      onPrimaryContainer: c.textePrincipal,
      secondary: c.secondaire,
      onSecondary: c.surSecondaire,
      secondaryContainer: c.secondaireVoile,
      onSecondaryContainer: c.textePrincipal,
      tertiary: c.info,
      onTertiary: c.surInfo,
      tertiaryContainer: c.infoVoile,
      onTertiaryContainer: c.textePrincipal,
      error: c.erreur,
      onError: c.surErreur,
      errorContainer: c.erreurVoile,
      onErrorContainer: c.textePrincipal,
      surface: c.surface,
      onSurface: c.textePrincipal,
      surfaceContainerHighest:
          sombre ? AppPalette.nuitSurfaceHaute : AppPalette.creme,
      onSurfaceVariant: c.texteSecondaire,
      outline: c.bordure,
      outlineVariant: c.separateur,
      shadow: c.ombre,
      scrim: AppPalette.encre,
      inverseSurface: sombre ? AppPalette.creme : AppPalette.encre,
      onInverseSurface: sombre ? AppPalette.encre : AppPalette.creme,
      inversePrimary: sombre ? AppPalette.vert : AppPalette.vertClair,
    );

    final typo = AppTypography.textTheme.apply(
      bodyColor: c.textePrincipal,
      displayColor: c.textePrincipal,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: luminosite,
      colorScheme: schema,
      scaffoldBackgroundColor: c.fond,
      textTheme: typo,
      canvasColor: c.surface,
      splashFactory: InkRipple.splashFactory,

      // Garantit la zone tactile de 48 dp sur tous les composants Material,
      // même quand leur contenu visible est plus petit.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      // Les jetons sémantiques voyagent avec le thème : un écran y accède par
      // `context.couleurs`, sans savoir quel mode est actif.
      extensions: <ThemeExtension<dynamic>>[c],

      iconTheme: IconThemeData(color: c.textePrincipal, size: 24),
      primaryIconTheme: IconThemeData(color: c.surPrimaire, size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textePrincipal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppEspaces.md,
        iconTheme: IconThemeData(color: c.textePrincipal, size: 24),
        actionsIconTheme: IconThemeData(color: c.textePrincipal, size: 24),
        titleTextStyle: typo.titleMedium,
        // Un trait sous la barre remplace l'ombre portée : visible en plein
        // soleil, et sans recalcul au défilement.
        shape: Border(bottom: BorderSide(color: c.separateur)),
        systemOverlayStyle: sombre
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
      ),

      // ── Boutons ─────────────────────────────────────────────────────────
      // 56 dp de haut, au-dessus du minimum de 48, parce qu'une main qui
      // travaille dehors vise moins précisément qu'un pouce au repos.

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primaire,
          foregroundColor: c.surPrimaire,
          disabledBackgroundColor: c.separateur,
          disabledForegroundColor: c.texteSecondaire,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppEspaces.lg),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRayons.brBouton,
          ),
          elevation: 0,
          textStyle: typo.labelLarge,
          animationDuration: AppDurees.appui,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primaire,
          foregroundColor: c.surPrimaire,
          minimumSize: const Size(double.infinity, 56),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRayons.brBouton,
          ),
          textStyle: typo.labelLarge,
          animationDuration: AppDurees.appui,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primaire,
          disabledForegroundColor: c.texteSecondaire,
          // 1,5 px et non 1 : un contour d'un pixel disparaît sous une forte
          // luminosité et le bouton cesse de se lire comme un bouton.
          side: BorderSide(color: c.primaire, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppEspaces.lg),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRayons.brBouton,
          ),
          textStyle: typo.labelLarge,
          animationDuration: AppDurees.appui,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primaire,
          disabledForegroundColor: c.texteSecondaire,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.md,
            vertical: AppEspaces.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRayons.brBouton,
          ),
          textStyle: typo.labelLarge,
          animationDuration: AppDurees.appui,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textePrincipal,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRayons.brPastille,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primaire,
        foregroundColor: c.surPrimaire,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 1,
        extendedTextStyle: typo.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: AppRayons.brBouton),
      ),

      // ── Saisie ──────────────────────────────────────────────────────────

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        // Le libellé reste au-dessus du champ en permanence au lieu de
        // remonter à la saisie. Un libellé qui sert d'exemple puis disparaît
        // oblige à se souvenir de ce qu'on remplissait.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppEspaces.md,
          vertical: AppEspaces.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRayons.brChamp,
          borderSide: BorderSide(color: c.bordure, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRayons.brChamp,
          borderSide: BorderSide(color: c.bordure, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRayons.brChamp,
          borderSide: BorderSide(color: c.separateur, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRayons.brChamp,
          borderSide: BorderSide(color: c.primaire, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRayons.brChamp,
          borderSide: BorderSide(color: c.erreur, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRayons.brChamp,
          borderSide: BorderSide(color: c.erreur, width: 2.5),
        ),
        labelStyle: typo.labelMedium?.copyWith(color: c.textePrincipal),
        floatingLabelStyle: typo.labelMedium?.copyWith(color: c.textePrincipal),
        hintStyle: typo.bodyMedium?.copyWith(color: c.texteSecondaire),
        helperStyle: typo.bodySmall?.copyWith(color: c.texteSecondaire),
        errorStyle: typo.bodySmall?.copyWith(color: c.erreur),
        prefixIconColor: c.texteSecondaire,
        suffixIconColor: c.texteSecondaire,
        // Deux lignes pour un message d'erreur : « La connexion est faible.
        // Vos données sont gardées, réessayez dans un instant. » tient sur
        // deux lignes à 360 dp, et davantage à 130 % de taille de texte.
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),

      // ── Surfaces ────────────────────────────────────────────────────────

      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRayons.brCarte,
          side: BorderSide(color: c.separateur),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRayons.brCarte,
          side: BorderSide(color: c.separateur),
        ),
        titleTextStyle: typo.titleMedium,
        contentTextStyle: typo.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRayons.brFeuille,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.texteSecondaire,
        textColor: c.textePrincipal,
        titleTextStyle: typo.titleSmall,
        subtitleTextStyle: typo.bodySmall?.copyWith(color: c.texteSecondaire),
        minVerticalPadding: AppEspaces.sm,
        shape: const RoundedRectangleBorder(borderRadius: AppRayons.brChamp),
      ),

      dividerTheme: DividerThemeData(
        color: c.separateur,
        thickness: 1,
        space: 1,
      ),

      // ── Navigation ──────────────────────────────────────────────────────
      // Les deux barres sont stylées de la même manière : l'application en
      // utilisait deux styles différents, Material 2 pour l'agriculteur et
      // l'expert, Material 3 pour l'administrateur.

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primaire,
        unselectedItemColor: c.texteSecondaire,
        // Les deux libellés ont la même taille : faire grossir celui de
        // l'onglet actif d'un pixel, comme auparavant, décale ses voisins sans
        // rien signaler. L'état actif se lit à la graisse, à la couleur et à
        // l'icône pleine.
        selectedLabelStyle: typo.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: typo.labelMedium,
        selectedIconTheme: IconThemeData(color: c.primaire, size: 26),
        unselectedIconTheme: IconThemeData(color: c.texteSecondaire, size: 26),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaireVoile,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRayons.brPastille,
        ),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((etats) {
          final actif = etats.contains(WidgetState.selected);
          return typo.labelMedium?.copyWith(
            color: actif ? c.primaire : c.texteSecondaire,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((etats) {
          final actif = etats.contains(WidgetState.selected);
          return IconThemeData(
            color: actif ? c.primaire : c.texteSecondaire,
            size: 26,
          );
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: c.primaire,
        unselectedLabelColor: c.texteSecondaire,
        labelStyle: typo.labelLarge,
        unselectedLabelStyle: typo.labelMedium,
        indicatorColor: c.primaire,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: c.separateur,
      ),

      // ── Retours et indicateurs ──────────────────────────────────────────

      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primaireVoile,
        disabledColor: c.separateur,
        labelStyle: typo.labelMedium?.copyWith(color: c.textePrincipal),
        secondaryLabelStyle: typo.labelMedium?.copyWith(color: c.primaire),
        padding: AppEspaces.pastille,
        side: BorderSide(color: c.bordure),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRayons.brPastille,
        ),
        iconTheme: IconThemeData(color: c.texteSecondaire, size: 18),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primaire,
        linearTrackColor: c.separateur,
        circularTrackColor: c.separateur,
        // 8 px au lieu des 4 par défaut : une barre fine ne se lit pas de loin
        // et le taux d'aptitude est l'information centrale de l'application.
        linearMinHeight: 8,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            sombre ? AppPalette.nuitSurfaceHaute : AppPalette.encre,
        contentTextStyle: typo.bodyMedium?.copyWith(
          color: sombre ? AppPalette.encreClaire : AppPalette.creme,
        ),
        actionTextColor: sombre ? AppPalette.vertClair : AppPalette.vertClair,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRayons.brChamp),
        insetPadding: const EdgeInsets.all(AppEspaces.md),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: sombre ? AppPalette.nuitSurfaceHaute : AppPalette.encre,
          borderRadius: AppRayons.brChamp,
        ),
        textStyle: typo.bodySmall?.copyWith(
          color: sombre ? AppPalette.encreClaire : AppPalette.creme,
        ),
        padding: AppEspaces.pastille,
      ),

      // ── Contrôles de formulaire ─────────────────────────────────────────

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.selected)
              ? c.surPrimaire
              : c.texteSecondaire,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (etats) =>
              etats.contains(WidgetState.selected) ? c.primaire : c.separateur,
        ),
        trackOutlineColor: WidgetStateProperty.all(c.bordure),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (etats) =>
              etats.contains(WidgetState.selected) ? c.primaire : c.bordure,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (etats) => etats.contains(WidgetState.selected)
              ? c.primaire
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(c.surPrimaire),
        side: BorderSide(color: c.bordure, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );
  }
}
