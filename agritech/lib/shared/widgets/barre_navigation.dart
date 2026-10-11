import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Un onglet de la barre de navigation.
class DestinationNavigation {
  const DestinationNavigation({
    required this.libelle,
    required this.icone,
    required this.iconeActive,
    this.compteur = 0,
    this.etiquette,
  });

  /// Libellé écrit sous l'icône. Toujours affiché, jamais tronqué.
  ///
  /// Court par nécessité : à 360 dp de large et à quatre onglets, chaque
  /// libellé dispose d'environ 80 points, et il devra encore tenir une fois
  /// traduit en wolof.
  final String libelle;

  /// Icône de l'onglet au repos, en version contour.
  final IconData icone;

  /// Icône de l'onglet actif, en version pleine. Le passage du contour au
  /// plein est l'un des quatre signaux qui distinguent l'onglet courant.
  final IconData iconeActive;

  /// Nombre affiché en pastille sur l'icône. Zéro n'affiche rien.
  final int compteur;

  /// Description parlée, quand le libellé seul ne suffit pas.
  final String? etiquette;
}

/// Barre de navigation inférieure, commune aux trois rôles.
///
/// L'application en utilisait deux styles : `BottomNavigationBar` pour
/// l'agriculteur et l'expert, `NavigationBar` de Material 3 pour
/// l'administrateur, avec deux rendus différents de l'onglet actif. Un seul
/// composant les remplace.
///
/// **L'onglet actif se distingue par quatre signaux simultanés** : une pastille
/// colorée derrière l'icône, l'icône en version pleine plutôt que contour, le
/// libellé en graisse appuyée, et la couleur primaire. L'ancienne barre ne
/// jouait que sur la teinte et un pixel de taille de police, ce qui ne se
/// perçoit pas en plein soleil, et pas du tout pour qui distingue mal les
/// couleurs.
///
/// **Les libellés ne disparaissent jamais**, y compris sur l'onglet inactif.
/// Material masque volontiers les libellés inactifs ; pour une personne peu à
/// l'aise avec le numérique, cela revient à devoir deviner trois icônes sur
/// quatre.
///
/// **La hauteur suit la taille de texte du téléphone.** La barre n'a pas de
/// hauteur fixe : à 130 % elle grandit au lieu de rogner ses libellés.
class BarreNavigation extends StatelessWidget {
  const BarreNavigation({
    super.key,
    required this.destinations,
    required this.indexActif,
    required this.onChange,
  });

  final List<DestinationNavigation> destinations;
  final int indexActif;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Container(
      decoration: BoxDecoration(
        color: couleurs.surface,
        // Un trait plutôt qu'une ombre portée : visible en extérieur, et sans
        // recalcul à chaque image au défilement du contenu.
        border: Border(top: BorderSide(color: couleurs.separateur)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppEspaces.xs),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _Onglet(
                    destination: destinations[i],
                    actif: i == indexActif,
                    position: i + 1,
                    total: destinations.length,
                    onAppui: () => onChange(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({
    required this.destination,
    required this.actif,
    required this.position,
    required this.total,
    required this.onAppui,
  });

  final DestinationNavigation destination;
  final bool actif;
  final int position;
  final int total;
  final VoidCallback onAppui;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    final teinte = actif ? couleurs.primaire : couleurs.texteSecondaire;

    return Semantics(
      selected: actif,
      button: true,
      label: destination.etiquette ?? destination.libelle,
      // Annonce « 2 sur 4 » : sans cela, un lecteur d'écran ne dit pas où l'on
      // se trouve dans la barre.
      hint: 'Onglet $position sur $total',
      child: InkWell(
        onTap: onAppui,
        borderRadius: AppRayons.brCarte,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppEspaces.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pastille(
                actif: actif,
                compteur: destination.compteur,
                icone: actif ? destination.iconeActive : destination.icone,
                teinte: teinte,
              ),
              const SizedBox(height: AppEspaces.xxs),
              // Le libellé se réduit pour tenir dans la largeur de l'onglet,
              // au lieu d'être rogné.
              //
              // À 360 dp et quatre onglets, chaque libellé dispose de 90
              // points. « Assistant » en occupe 68 à la taille de texte
              // normale, et 88 à 130 % : la marge est mince, et au-delà il
              // déborderait. Un mot d'un seul tenant ne peut pas passer à la
              // ligne, et le couper après « Assistan » ne dirait plus rien.
              //
              // La réduction ne s'applique donc qu'au-delà du point où le
              // libellé ne tient plus, jamais en deçà : à taille normale, il
              // reste au corps de 14 que le système impose comme plancher.
              // C'est le seul endroit de l'application où la taille de texte
              // choisie par l'utilisateur n'est pas suivie à la lettre, et
              // c'est pour que le mot reste entier.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.libelle,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: textes.labelMedium?.copyWith(
                    color: teinte,
                    fontWeight: actif ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icône de l'onglet, sa pastille d'activité et son compteur éventuel.
class _Pastille extends StatelessWidget {
  const _Pastille({
    required this.actif,
    required this.compteur,
    required this.icone,
    required this.teinte,
  });

  final bool actif;
  final int compteur;
  final IconData icone;
  final Color teinte;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: AppMouvement.duree(context, AppDurees.courte),
          curve: AppCourbes.sortie,
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.md,
            vertical: AppEspaces.xxs,
          ),
          decoration: BoxDecoration(
            color: actif ? couleurs.primaireVoile : Colors.transparent,
            borderRadius: AppRayons.brPastille,
          ),
          child: Icon(icone, size: 26, color: teinte),
        ),
        if (compteur > 0)
          Positioned(
            top: -2,
            right: 0,
            child: _Compteur(nombre: compteur),
          ),
      ],
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    // Au-delà de 99, le nombre exact n'apporte rien et la pastille déborderait.
    final texte = nombre > 99 ? '99+' : '$nombre';

    return Semantics(
      label: '$nombre en attente',
      child: Container(
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: couleurs.erreur,
          borderRadius: AppRayons.brPastille,
          // Liseré de la couleur du fond, pour que la pastille se détache même
          // posée sur l'icône.
          border: Border.all(color: couleurs.surface, width: 1.5),
        ),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: couleurs.surErreur,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
        ),
      ),
    );
  }
}
