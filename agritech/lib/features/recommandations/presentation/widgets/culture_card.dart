import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../data/models/recommandation_model.dart';

/// Étiquette de la transition entre la carte du classement et le détail.
///
/// Déclarée ici et appelée des deux côtés : deux chaînes écrites à la main
/// finiraient par diverger, et la transition cesserait alors sans erreur ni
/// avertissement, simplement en ne se jouant plus.
String etiquetteHeroCulture(String nomCulture) => 'culture_$nomCulture';

/// Carte d'une culture recommandée, telle que l'écran des recommandations
/// l'affiche.
///
/// Adaptateur : il traduit la réponse du moteur en arguments pour
/// [CarteCulture]. Tout le dessin est dans le composant partagé, qui ne
/// connaît donc aucun modèle de données, et cette classe ne contient aucune
/// mise en page.
///
/// Ce que l'ancienne version faisait ici et qui a changé :
///
/// - le score était affiché deux fois, en cercle à droite et en barre en bas,
///   avec deux animations de 1 200 ms chacune. Il ne reste que la barre, avec
///   sa valeur écrite à côté, animée sur 300 ms ;
/// - le badge de rang était une classe privée de ce fichier, dupliquant la
///   cinquième implémentation de badge de l'application ;
/// - le nom wolof était en italique et en petite taille ; il est maintenant en
///   taille de lecture, sous le nom français ;
/// - la cascade d'apparition utilisait 150 ms d'écart, là où le système en
///   retient 100.
class CultureCard extends StatelessWidget {
  const CultureCard({
    super.key,
    required this.recommandation,
    required this.index,
    required this.onTap,
  });

  final RecommandationModel recommandation;

  /// Position de rendu, qui décide du décalage de l'animation.
  final int index;

  final VoidCallback onTap;

  /// Icône de repli quand l'image de la culture n'est pas disponible, ce qui
  /// est le cas courant hors connexion.
  ///
  /// Deux icônes seulement, et toutes deux franchement végétales : l'herbe
  /// pour les céréales, la feuille pour le reste.
  ///
  /// La tentation était d'en donner une à chaque culture. Material n'offre
  /// rien qui ressemble à un plant de niébé ou à un pied de manioc, et les
  /// rapprochements trouvés tenaient de l'arbitraire : des points épars pour
  /// les légumineuses se lisaient comme des points épars, un arbre pour le
  /// manioc comme un arbre. Une fausse distinction coûte plus qu'une absence
  /// de distinction, parce qu'elle laisse croire qu'elle veut dire quelque
  /// chose. L'identité de la culture est portée par son nom, écrit en grand,
  /// doublé de son nom wolof.
  ///
  /// La vraie réponse serait une illustration par culture, qui demanderait de
  /// les dessiner et de les embarquer dans l'application.
  IconData get _icone {
    switch (recommandation.culture.toLowerCase()) {
      case 'mil':
      case 'sorgho':
      case 'maïs':
      case 'riz':
        return Icons.grass_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le rang vient du moteur. En son absence seulement, la position de rendu
    // sert de repli.
    final rang = recommandation.rang ?? index + 1;

    return ApparitionCascade(
      index: index,
      child: CarteCulture(
        nomFrancais: recommandation.culture,
        nomWolof: recommandation.nomWolof,
        tauxAptitude: recommandation.scoreCompatibilite,
        rang: rang,
        imageUrl: recommandation.imageUrl,
        icone: _icone,
        index: index,
        miseEnValeur: rang == 1,
        // La même étiquette est posée sur le détail, ce qui fait voyager la
        // vignette d'un écran à l'autre au lieu de la faire réapparaître.
        heroTag: etiquetteHeroCulture(recommandation.culture),
        badge: BadgeStatut.validation(recommandation.statutValidation),
        informations: [
          LigneInfoCulture(
            icone: Icons.calendar_today_outlined,
            texte: recommandation.periodeIdealePlantation,
          ),
          LigneInfoCulture(
            icone: Icons.trending_up_rounded,
            texte: recommandation.rendementLabel,
          ),
        ],
        onTap: onTap,
      ),
    );
  }
}
