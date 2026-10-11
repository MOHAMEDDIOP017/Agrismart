/// Bibliothèque de composants d'AgriSmart.
///
/// Un écran écrit `import '../../../../shared/widgets/widgets.dart';` et
/// dispose de l'ensemble. Comme pour le thème, cela donne un seul endroit à
/// surveiller : un écran qui n'importe pas ce fichier et qui construit pourtant
/// des boutons ou des badges en définit encore ses propres variantes.
///
/// Ce que chaque composant remplace, et pourquoi, est documenté dans son
/// fichier. En résumé de l'audit : six implémentations de badge, quatre
/// manières d'écrire un bouton, 26 zones touchables sans retour visuel, 21
/// écrans affichant une trace d'exception, et aucun état hors connexion.
library;

export 'apparition_cascade.dart';
export 'app_bouton.dart';
export 'app_bouton_flottant.dart';
export 'app_champ_texte.dart';
export 'badge_statut.dart';
export 'barre_navigation.dart';
export 'barre_titre.dart';
export 'bandeau_hors_connexion.dart';
export 'carte_culture.dart';
export 'etat_erreur.dart';
export 'etat_vide.dart';
export 'illustration.dart';
export 'retour_action.dart';
export 'squelette.dart';
export 'zone_tactile.dart';
