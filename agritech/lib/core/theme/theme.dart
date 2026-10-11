/// Point d'entrée unique du système de design d'AgriSmart.
///
/// Un écran écrit `import '../../../../core/theme/theme.dart';` et dispose des
/// couleurs, de l'échelle d'espacement, des rayons, des durées et de la
/// typographie. Cela évite les cinq imports séparés en tête de chaque fichier,
/// et donne un seul endroit à surveiller : si un écran n'importe pas ce
/// fichier, c'est qu'il définit encore ses propres valeurs.
library;

export 'app_colors.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';
