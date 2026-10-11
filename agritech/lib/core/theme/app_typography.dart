import 'package:flutter/material.dart';

/// Système typographique d'AgriSmart.
///
/// Quatre décisions structurent ce fichier.
///
/// **Une seule famille.** La version précédente mélangeait Poppins pour les
/// titres et Inter pour le corps, et appelait `GoogleFonts` directement dans
/// 21 fichiers, pour 223 appels. Nunito remplace les deux. Ses formes
/// arrondies et sa hauteur d'x généreuse la rendent lisible à petite taille,
/// et elle couvre les diacritiques du français comme les caractères du wolof
/// latinisé (ñ, ó, à, é, ë), ce qui compte pour une interface destinée à être
/// traduite.
///
/// **Une fonte embarquée, pas téléchargée.** Les fichiers sont dans
/// `assets/fonts/`. `google_fonts` allait chercher la fonte sur le réseau au
/// premier lancement : hors couverture, toute l'application s'affichait dans
/// la police système, ce qui contredit la contrainte de connexion
/// irrégulière. Quatre graisses sont embarquées, réduites aux caractères du
/// français et du wolof, pour 203 Ko au total.
///
/// **Base 16, plancher 14.** La taille la plus fréquente dans le code audité
/// était 13 px, la deuxième 12 px, et 78 déclarations descendaient sous 12.
/// Aucun style de cette échelle ne descend sous 14. Le corps de texte est à
/// 16, taille de référence pour une lecture en extérieur.
///
/// **Aucune couleur.** Les styles ne portent pas de couleur : elle est
/// appliquée par `ThemeData` au moment de la construction du thème, via
/// `apply(bodyColor:)`. C'est ce qui permet au même fichier de servir les
/// modes clair et sombre. L'ancienne version figeait `AppColors.textPrimary`
/// dans chacun des quinze styles, ce qui rendait le mode sombre impossible.
class AppTypography {
  AppTypography._();

  /// Nom de la famille, tel que déclaré dans `pubspec.yaml`.
  static const String famille = 'Nunito';

  /// Taille du corps de texte. Sert de référence à toute l'échelle.
  static const double tailleBase = 16;

  /// Plus petite taille admise pour un texte porteur de sens.
  static const double taillePlancher = 14;

  /// Graisse par défaut du corps de texte.
  ///
  /// Jamais en dessous : un trait fin se délave sous une forte luminosité.
  static const FontWeight graisseBase = FontWeight.w400;

  /// Construit un style dans la famille de l'application.
  ///
  /// La signature reprend les noms de paramètres de `GoogleFonts`, ce qui a
  /// permis de reprendre les 223 appels dispersés dans les écrans sans en
  /// réécrire les arguments.
  ///
  /// Les quatre graisses sont embarquées en fontes statiques distinctes,
  /// déclarées une par `weight:` dans `pubspec.yaml`. Les graisses
  /// intermédiaires, w500 par exemple, sont donc arrondies par le moteur vers
  /// la plus proche des quatre, au lieu d'être interpolées.
  ///
  /// Le choix de quatre fichiers statiques plutôt que d'un fichier variable
  /// vient d'une mesure : sur la fonte variable, `fontWeight` seul n'avait
  /// aucun effet, parce que seul `fontVariations` pilote l'axe de graisse.
  /// `copyWith(fontWeight:)` sur un style du thème ne produisait rien non
  /// plus. Avec 258 usages de `fontWeight` dans le code, ce silence aurait
  /// créé un piège durable. Voir `test/theme_graisse_test.dart`, qui mesure
  /// les quatre graisses pour empêcher la régression.
  static TextStyle police({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: famille,
      fontSize: fontSize,
      fontWeight: fontWeight ?? graisseBase,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      shadows: shadows,
      decoration: decoration,
    );
  }

  /// Les quatre graisses effectivement embarquées.
  static const List<FontWeight> graissesEmbarquees = [
    FontWeight.w400,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ];

  /// Échelle complète, sans couleur.
  ///
  /// Les interlignes sont resserrés sur les grands caractères (1,1 à 1,3) et
  /// ouverts sur le corps de texte (1,5), où ils servent la lecture de
  /// plusieurs lignes d'affilée.
  static TextTheme get textTheme => TextTheme(
        // Display — écrans d'accueil et chiffres mis en avant.
        displayLarge:
            police(fontSize: 40, fontWeight: FontWeight.w800, height: 1.1),
        displayMedium:
            police(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15),
        displaySmall:
            police(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),

        // Headline — titres d'écran.
        headlineLarge:
            police(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
        headlineMedium:
            police(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        headlineSmall:
            police(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),

        // Title — titres de section et de carte.
        titleLarge:
            police(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
        titleMedium:
            police(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35),
        titleSmall:
            police(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),

        // Body — texte courant. `bodyMedium` est le style par défaut d'un
        // widget `Text` sans style explicite : c'est lui qui fixe la taille de
        // lecture de l'application.
        bodyLarge: police(fontSize: 18, fontWeight: graisseBase, height: 1.5),
        bodyMedium:
            police(fontSize: tailleBase, fontWeight: graisseBase, height: 1.5),
        bodySmall: police(
          fontSize: taillePlancher,
          fontWeight: graisseBase,
          height: 1.45,
        ),

        // Label — boutons, pastilles, onglets. Graisses plus appuyées parce
        // que ces textes sont courts et doivent se lire d'un coup d'œil.
        labelLarge: police(
          fontSize: tailleBase,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0.2,
        ),
        labelMedium: police(
          fontSize: taillePlancher,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        labelSmall: police(
          fontSize: taillePlancher,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      );
}
