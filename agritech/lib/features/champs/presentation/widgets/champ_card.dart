import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/champ_entity.dart';

/// Carte d'une parcelle dans la liste.
///
/// Trois changements par rapport à la version précédente.
///
/// **La vignette ne dépend plus du réseau.** Chaque carte chargeait une photo
/// de champ générique depuis un service distant, la même pour toutes les
/// parcelles. Elle n'apportait aucune information, et hors couverture la liste
/// s'affichait avec des rectangles vides. La vignette est maintenant dessinée,
/// et ne laisse la place à une image que lorsque l'agriculteur en a pris une.
///
/// **Le balayage pour supprimer a été retiré.** La carte était enveloppée dans
/// un `Dismissible` : glisser vers la gauche supprimait la parcelle, vers la
/// droite l'ouvrait en modification. Un geste destructeur invisible, déclenché
/// par un doigt qui dérape sur un écran tenu d'une main en plein champ, et
/// dont rien n'indiquait l'existence. Supprimer et modifier sont désormais des
/// boutons écrits, sur l'écran de détail.
///
/// **L'état de la parcelle se lit sans la couleur seule**, par le badge
/// commun, qui porte une icône et un mot.
class ChampCard extends StatelessWidget {
  const ChampCard({super.key, required this.champ, required this.onTap});

  final ChampEntity champ;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return ZoneTactile(
      onTap: onTap,
      rayon: AppRayons.brCarte,
      tailleMinimale: null,
      etiquette: 'Parcelle ${champ.nom}, ${champ.superficieFormatee}',
      child: Container(
        padding: AppEspaces.carte,
        decoration: BoxDecoration(
          color: couleurs.surface,
          borderRadius: AppRayons.brCarte,
          border: Border.all(color: couleurs.separateur),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VignetteChamp(champ: champ, cote: 64),
            const SizedBox(width: AppEspaces.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    champ.nom,
                    style: textes.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppEspaces.xxs),
                  _Ligne(
                    icone: Icons.straighten_rounded,
                    texte: '${champ.superficieFormatee} · sol ${champ.typeSol}',
                  ),
                  if (champ.culture != null && champ.culture!.isNotEmpty)
                    _Ligne(
                      icone: Icons.grass_rounded,
                      texte: champ.culture!,
                      teinte: couleurs.primaire,
                    ),
                  const SizedBox(height: AppEspaces.xs),
                  BadgeStatut.statutChamp(champ.statut),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppEspaces.xs),
              child: Icon(
                Icons.chevron_right_rounded,
                color: couleurs.texteSecondaire,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vignette d'une parcelle : sa photo si elle en a une, sinon une tuile
/// dessinée portant l'initiale de son nom.
///
/// L'initiale n'est pas décorative : dans une liste de parcelles aux noms
/// proches, « Champ Nord » et « Champ Ouest », elle donne un repère visuel
/// avant même la lecture.
class VignetteChamp extends StatelessWidget {
  const VignetteChamp({
    super.key,
    required this.champ,
    this.cote = 64,
    this.heroTag,
    this.couleurFond,
  });

  final ChampEntity champ;
  final double cote;
  final Object? heroTag;

  /// Fond de la tuile dessinée. Par défaut le voile vert du thème ; à
  /// préciser quand la vignette est posée sur une surface déjà teintée du
  /// même voile, où elle disparaîtrait.
  final Color? couleurFond;

  @override
  Widget build(BuildContext context) {
    final photo = champ.photoUrl;

    Widget contenu = ClipRRect(
      borderRadius: AppRayons.brChamp,
      child: (photo == null || photo.isEmpty)
          ? _tuile(context)
          : CachedNetworkImage(
              imageUrl: photo,
              width: cote,
              height: cote,
              fit: BoxFit.cover,
              placeholder: (_, __) => ZoneSquelette(
                child: Squelette(largeur: cote, hauteur: cote),
              ),
              errorWidget: (_, __, ___) => _tuile(context),
            ),
    );

    if (heroTag != null) contenu = Hero(tag: heroTag!, child: contenu);
    return contenu;
  }

  Widget _tuile(BuildContext context) {
    final couleurs = context.couleurs;
    final initiale =
        champ.nom.trim().isEmpty ? '?' : champ.nom.trim()[0].toUpperCase();

    return Container(
      width: cote,
      height: cote,
      color: couleurFond ?? couleurs.primaireVoile,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.terrain_rounded,
            size: cote * 0.62,
            color: couleurs.primaire.withValues(alpha: 0.25),
          ),
          Text(
            initiale,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: couleurs.primaire,
                  fontSize: cote * 0.36,
                ),
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.texte, this.teinte});

  final IconData icone;
  final String texte;
  final Color? teinte;

  @override
  Widget build(BuildContext context) {
    final couleur = teinte ?? context.couleurs.texteSecondaire;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaces.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: couleur),
          const SizedBox(width: AppEspaces.xs),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: couleur),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
