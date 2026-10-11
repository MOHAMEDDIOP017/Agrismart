import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Un bloc gris, brique de base d'un écran en attente.
class Squelette extends StatelessWidget {
  const Squelette({
    super.key,
    this.largeur,
    this.hauteur = 16,
    this.rayon = AppRayons.brChamp,
  });

  /// Bloc rond, pour une vignette ou un avatar.
  const Squelette.cercle({super.key, required double diametre})
      : largeur = diametre,
        hauteur = diametre,
        rayon = AppRayons.brPastille;

  /// Ligne de texte. La largeur est exprimée en fraction de la place
  /// disponible, pour que le squelette suive la largeur de l'écran.
  const Squelette.ligne({super.key, this.largeur, double epaisseur = 16})
      : hauteur = epaisseur,
        rayon = AppRayons.brChamp;

  final double? largeur;
  final double hauteur;
  final BorderRadius rayon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largeur,
      height: hauteur,
      decoration: BoxDecoration(
        color: context.couleurs.separateur,
        borderRadius: rayon,
      ),
    );
  }
}

/// Applique le balayage lumineux à tout un ensemble de [Squelette].
///
/// Le balayage est posé une seule fois, autour de la liste entière, et non
/// autour de chaque carte. `Shimmer` fonctionne par masque de dégradé, qui se
/// recalcule à chaque image : un masque pour cinq cartes coûte cinq fois moins
/// qu'un masque par carte, ce qui compte sur un téléphone d'entrée de gamme.
///
/// Quand l'utilisateur a demandé moins d'animations, les blocs restent fixes.
/// La forme du contenu à venir est annoncée de la même façon ; seul le
/// mouvement disparaît.
class ZoneSquelette extends StatelessWidget {
  const ZoneSquelette({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    if (AppMouvement.reduit(context)) return child;

    return Shimmer.fromColors(
      baseColor: couleurs.separateur,
      // La teinte claire du balayage dérive du fond : en mode sombre, un
      // balayage blanc sur un fond presque noir produit un éclair désagréable
      // dans l'obscurité, qui est justement le moment d'usage visé.
      highlightColor: Color.alphaBlend(
        couleurs.textePrincipal.withValues(alpha: 0.08),
        couleurs.separateur,
      ),
      period: AppDurees.squelette,
      child: child,
    );
  }
}

/// Squelette d'une carte de parcelle : vignette carrée à gauche, trois lignes
/// de texte à droite.
class SqueletteCarteChamp extends StatelessWidget {
  const SqueletteCarteChamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEspaces.carte,
      decoration: BoxDecoration(
        color: context.couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: context.couleurs.separateur),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Squelette(largeur: 72, hauteur: 72, rayon: AppRayons.brChamp),
          SizedBox(width: AppEspaces.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Squelette.ligne(largeur: 160, epaisseur: 18),
                SizedBox(height: AppEspaces.xs),
                Squelette.ligne(largeur: 110),
                SizedBox(height: AppEspaces.xs),
                Squelette.ligne(largeur: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Squelette d'une carte de culture recommandée : vignette, deux lignes de nom
/// et la barre d'aptitude.
class SqueletteCarteCulture extends StatelessWidget {
  const SqueletteCarteCulture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEspaces.carte,
      decoration: BoxDecoration(
        color: context.couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: context.couleurs.separateur),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Squelette(largeur: 56, hauteur: 56, rayon: AppRayons.brChamp),
              SizedBox(width: AppEspaces.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Squelette.ligne(largeur: 130, epaisseur: 20),
                    SizedBox(height: AppEspaces.xxs),
                    Squelette.ligne(largeur: 80),
                  ],
                ),
              ),
              Squelette(largeur: 52, hauteur: 28, rayon: AppRayons.brPastille),
            ],
          ),
          SizedBox(height: AppEspaces.sm),
          Squelette(hauteur: 8, rayon: AppRayons.brPastille),
        ],
      ),
    );
  }
}

/// Liste de squelettes, pour un écran dont le contenu est une liste.
///
/// [constructeur] permet de choisir la forme qui correspond au contenu
/// attendu. Un squelette qui ne ressemble pas à ce qui arrive ensuite est pire
/// qu'une roue : il annonce une mise en page qui ne viendra pas.
class SqueletteListe extends StatelessWidget {
  const SqueletteListe({
    super.key,
    this.nombre = 4,
    this.constructeur,
    this.marge = AppEspaces.liste,
  });

  /// Liste de cartes de parcelles.
  const SqueletteListe.champs({super.key, this.nombre = 4})
      : constructeur = _champ,
        marge = AppEspaces.liste;

  /// Liste de cartes de cultures recommandées.
  const SqueletteListe.cultures({super.key, this.nombre = 3})
      : constructeur = _culture,
        marge = AppEspaces.liste;

  final int nombre;
  final WidgetBuilder? constructeur;
  final EdgeInsets marge;

  static Widget _champ(BuildContext _) => const SqueletteCarteChamp();
  static Widget _culture(BuildContext _) => const SqueletteCarteCulture();

  @override
  Widget build(BuildContext context) {
    final forme = constructeur ?? _champ;
    return ZoneSquelette(
      child: ListView.separated(
        // Un écran en attente ne se fait pas défiler : il n'y a rien à
        // atteindre, et un défilement rendrait le squelette plus présent que
        // le contenu qu'il annonce.
        physics: const NeverScrollableScrollPhysics(),
        padding: marge,
        itemCount: nombre,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppEspaces.entreCartes),
        itemBuilder: (context, _) => forme(context),
      ),
    );
  }
}
