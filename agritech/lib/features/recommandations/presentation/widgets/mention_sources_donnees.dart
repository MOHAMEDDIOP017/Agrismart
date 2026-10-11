import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Mention discrète de l'origine des données ayant produit une recommandation.
///
/// Le moteur part systématiquement des moyennes de la zone agroécologique,
/// puis les remplace par des mesures temps réel quand SoilGrids et NASA POWER
/// répondent. Ce repli est ce qui garantit qu'une recommandation est toujours
/// produite, y compris hors ligne ou en cas de panne d'une source externe.
///
/// L'agriculteur doit pouvoir savoir laquelle des deux situations s'applique à
/// sa parcelle : une aptitude calculée sur une moyenne de zone n'a pas la même
/// portée qu'une aptitude calculée sur une mesure du sol de son champ. D'où
/// l'affichage, volontairement sobre mais présent sur les deux écrans.
///
/// Widget partagé entre la liste et le détail : une seule formulation, qui ne
/// peut pas diverger d'un écran à l'autre.
class MentionSourcesDonnees extends StatelessWidget {
  const MentionSourcesDonnees({
    super.key,
    required this.sources,
    this.zoneAgroecologique,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 0),
  });

  /// Origine par bloc de variables, telle que renvoyée par l'API :
  /// `{sol: "moyenne de zone", climat: "NASA POWER (temps réel)", ...}`.
  final Map<String, String> sources;

  /// Zone agroécologique de la parcelle, utilisée pour nommer la zone dans le
  /// libellé de repli (« moyenne de la zone Bassin arachidier »).
  final String? zoneAgroecologique;

  final EdgeInsetsGeometry padding;

  /// Libellés lisibles pour les clés techniques renvoyées par le backend.
  static const _libelles = {
    'sol': 'Sol',
    'climat': 'Climat',
    'phosphore_potassium': 'Phosphore et potassium',
    'ndvi': 'Végétation (NDVI)',
  };

  /// Valeur renvoyée par le backend quand aucune mesure temps réel n'a pu être
  /// obtenue pour ce bloc de variables.
  static const _replique = 'moyenne de zone';

  /// Rend l'origine lisible, en nommant la zone quand il s'agit d'un repli.
  ///
  /// « moyenne de zone » seul ne dit pas à l'agriculteur de quelle zone il
  /// s'agit ; « moyenne de la zone Bassin arachidier » le situe.
  String _origineLisible(String valeur) {
    if (valeur != _replique) return valeur;
    final zone = zoneAgroecologique?.trim();
    return (zone == null || zone.isEmpty)
        ? _replique
        : 'moyenne de la zone $zone';
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      // Pas d'origine connue (historique par exemple) : on nomme au moins la
      // zone, plutôt que de n'afficher aucun contexte.
      final zone = zoneAgroecologique?.trim();
      if (zone == null || zone.isEmpty) return const SizedBox.shrink();
      return _ligne(context, 'Zone agroécologique : $zone');
    }

    final texte = sources.entries
        .map(
            (e) => '${_libelles[e.key] ?? e.key} : ${_origineLisible(e.value)}')
        .join(' · ');

    return _ligne(context, texte);
  }

  Widget _ligne(BuildContext context, String texte) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: context.couleurs.texteSecondaire.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.couleurs.texteSecondaire,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
