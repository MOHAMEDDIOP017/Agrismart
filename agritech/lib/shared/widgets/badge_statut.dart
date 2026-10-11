import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/statut_culture.dart';
import '../../core/enums/statut_validation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Famille de couleur d'un badge, exprimée par l'intention et non par la
/// teinte. Un écran demande « avertissement », pas « orange ».
enum TonBadge {
  neutre,
  primaire,
  succes,
  avertissement,
  attention,
  erreur,
  info
}

/// Poids visuel du badge.
enum IntensiteBadge {
  /// Fond plein et texte contrasté. Pour un statut qui change la lecture de
  /// l'écran : une recommandation validée par un agronome n'a pas la même
  /// portée qu'une sortie brute du moteur.
  pleine,

  /// Fond teinté, texte en encre, icône colorée. Pour les statuts
  /// d'accompagnement, quand plusieurs badges coexistent dans une liste et que
  /// les mettre tous en aplat rendrait l'écran illisible.
  douce,
}

/// Badge de statut unique de l'application.
///
/// Remplace six implémentations concurrentes relevées par l'audit :
/// `StatutBadge` dans les champs, `StatutUtilisateurBadge` et
/// `StatutAssignationBadge` et `RoleBadge` dans l'administration,
/// `BadgeValidation` dans les recommandations, plus deux classes privées
/// `_Badge` et `_RangBadge`. Elles dessinaient la même idée de six façons,
/// avec des tailles de texte de 9 à 12 px et des opacités de fond de 0,12 à
/// 0,25.
///
/// Deux règles les remplacent.
///
/// **La couleur ne porte jamais seule l'information.** Chaque statut a une
/// icône propre et un libellé écrit. Environ un homme sur douze distingue mal
/// le rouge du vert : un badge qui ne se différencie que par la teinte ne dit
/// rien à ces personnes, et ne dit rien non plus en plein soleil quand les
/// couleurs se délavent.
///
/// **Le fond plein remplace la pastille pâle.** Les anciens badges posaient un
/// petit texte coloré sur un fond de la même teinte à 12 % d'opacité, ce qui
/// donne un rapport de contraste autour de 4,1. Le fond plein avec texte
/// contrasté atteint 4,9 à 6,5 selon la famille. La mesure est dans
/// `test/theme_contraste_test.dart`.
class BadgeStatut extends StatelessWidget {
  const BadgeStatut({
    super.key,
    required this.libelle,
    required this.icone,
    required this.ton,
    this.intensite = IntensiteBadge.pleine,
  });

  /// Badge de l'état de relecture d'une recommandation.
  ///
  /// Le moteur produit toujours ses recommandations en attente : ce sont des
  /// sorties d'un modèle statistique. Un agronome peut ensuite les valider,
  /// les corriger ou les rejeter. La distinction compte pour l'agriculteur,
  /// qui doit savoir s'il regarde une prédiction automatique ou un avis
  /// confirmé par un humain.
  ///
  /// [detaille] allonge le libellé pour les écrans de détail, où la place ne
  /// manque pas et où nommer l'expert lève l'ambiguïté.
  factory BadgeStatut.validation(
    StatutValidation statut, {
    bool detaille = false,
    IntensiteBadge intensite = IntensiteBadge.pleine,
  }) {
    final (icone, ton) = switch (statut) {
      StatutValidation.enAttente => (
          Icons.schedule_rounded,
          TonBadge.avertissement
        ),
      StatutValidation.validee => (Icons.verified_rounded, TonBadge.succes),
      StatutValidation.corrigee => (Icons.edit_note_rounded, TonBadge.info),
      StatutValidation.rejetee => (Icons.block_rounded, TonBadge.erreur),
    };

    final libelle = detaille
        ? switch (statut) {
            StatutValidation.enAttente => 'En attente de validation',
            StatutValidation.validee => 'Validée par un expert',
            StatutValidation.corrigee => 'Corrigée par un expert',
            StatutValidation.rejetee => 'Rejetée par un expert',
          }
        : statut.libelle;

    return BadgeStatut(
      libelle: libelle,
      icone: icone,
      ton: ton,
      intensite: intensite,
    );
  }

  /// Badge de l'avancement d'une culture.
  factory BadgeStatut.culture(
    StatutCulture statut, {
    IntensiteBadge intensite = IntensiteBadge.douce,
  }) {
    final (icone, ton) = switch (statut) {
      StatutCulture.prevu => (Icons.event_outlined, TonBadge.info),
      StatutCulture.enCours => (Icons.grass_rounded, TonBadge.primaire),
      StatutCulture.recolte => (
          Icons.shopping_basket_outlined,
          TonBadge.avertissement
        ),
      StatutCulture.abandonne => (Icons.cancel_outlined, TonBadge.neutre),
    };
    return BadgeStatut(
      libelle: statut.libelle,
      icone: icone,
      ton: ton,
      intensite: intensite,
    );
  }

  /// Badge de l'état d'une parcelle.
  ///
  /// Le statut arrive du serveur sous forme de chaîne, telle que
  /// `AppConstants` la déclare. Deux widgets l'affichaient de deux façons :
  /// l'un traduisait en français, l'autre montrait la constante brute avec ses
  /// tirets bas remplacés par des espaces, ce qui donnait « EN TRAITEMENT » à
  /// l'écran. Les deux sont remplacés ici, et la traduction est faite une fois.
  factory BadgeStatut.statutChamp(
    String statut, {
    IntensiteBadge intensite = IntensiteBadge.douce,
  }) {
    final (libelle, icone, ton) = switch (statut) {
      AppConstants.statutPrevu => (
          'Prévu',
          Icons.event_outlined,
          TonBadge.info
        ),
      AppConstants.statutEnCours => (
          'En cours',
          Icons.grass_rounded,
          TonBadge.primaire
        ),
      AppConstants.statutRecolte => (
          'Récolte',
          Icons.shopping_basket_outlined,
          TonBadge.avertissement
        ),
      AppConstants.statutEnTraitement => (
          'Traitement',
          Icons.healing_rounded,
          TonBadge.attention
        ),
      AppConstants.statutAbandonne => (
          'Abandonné',
          Icons.cancel_outlined,
          TonBadge.neutre
        ),
      // Statut inconnu du client : affiché tel quel plutôt que masqué, pour
      // qu'un ajout côté serveur se voie au lieu de disparaître.
      _ => (statut, Icons.help_outline_rounded, TonBadge.neutre),
    };
    return BadgeStatut(
      libelle: libelle,
      icone: icone,
      ton: ton,
      intensite: intensite,
    );
  }

  /// Badge de rang dans un classement, « 1re », « 2e », « 3e ».
  ///
  /// Le rang vient du moteur et non de la position d'affichage : une liste
  /// filtrée ou réordonnée continue d'indiquer le classement d'origine.
  factory BadgeStatut.rang(
    int rang, {
    IntensiteBadge intensite = IntensiteBadge.pleine,
  }) {
    return BadgeStatut(
      libelle: rang == 1 ? '1re' : '${rang}e',
      icone:
          rang == 1 ? Icons.workspace_premium_rounded : Icons.numbers_rounded,
      ton: rang == 1 ? TonBadge.primaire : TonBadge.neutre,
      intensite: intensite,
    );
  }

  final String libelle;
  final IconData icone;
  final TonBadge ton;
  final IntensiteBadge intensite;

  Color _teinte(CouleursAgriSmart c) => switch (ton) {
        TonBadge.neutre => c.texteSecondaire,
        TonBadge.primaire => c.primaire,
        TonBadge.succes => c.succes,
        TonBadge.avertissement => c.avertissement,
        TonBadge.attention => c.alerteElevee,
        TonBadge.erreur => c.erreur,
        TonBadge.info => c.info,
      };

  Color _surTeinte(CouleursAgriSmart c) => switch (ton) {
        TonBadge.neutre => c.surface,
        TonBadge.primaire => c.surPrimaire,
        TonBadge.succes => c.surSucces,
        TonBadge.avertissement => c.surAvertissement,
        TonBadge.attention => c.surAlerteElevee,
        TonBadge.erreur => c.surErreur,
        TonBadge.info => c.surInfo,
      };

  Color _voile(CouleursAgriSmart c) => switch (ton) {
        TonBadge.neutre => c.fond,
        TonBadge.primaire => c.primaireVoile,
        TonBadge.succes => c.succesVoile,
        TonBadge.avertissement => c.avertissementVoile,
        TonBadge.attention => c.erreurVoile,
        TonBadge.erreur => c.erreurVoile,
        TonBadge.info => c.infoVoile,
      };

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final teinte = _teinte(couleurs);
    final pleine = intensite == IntensiteBadge.pleine;

    final couleurFond = pleine ? teinte : _voile(couleurs);
    final couleurTexte =
        pleine ? _surTeinte(couleurs) : couleurs.textePrincipal;
    final couleurIcone = pleine ? _surTeinte(couleurs) : teinte;

    return Container(
      padding: AppEspaces.pastille,
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: AppRayons.brPastille,
        border: pleine ? null : Border.all(color: teinte, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: couleurIcone),
          const SizedBox(width: AppEspaces.xxs),
          // Le libellé reste toujours présent à côté de l'icône, et peut
          // passer à la ligne plutôt que d'être tronqué : à 200 % de taille de
          // texte, « En attente de validation » ne tient pas sur une ligne.
          Flexible(
            child: Text(
              libelle,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: couleurTexte),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
