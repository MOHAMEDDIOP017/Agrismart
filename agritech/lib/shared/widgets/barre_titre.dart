import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Barre de titre garantissant toujours une issue.
///
/// Sur un écran empilé, elle montre la flèche de retour. Sur un écran qui
/// n'est au sommet d'aucune pile, elle montre un bouton d'accueil explicite,
/// avec son libellé parlé. Dans les deux cas, il existe un moyen visible de
/// repartir.
///
/// L'`AppBar` de Material fait déjà la première moitié : elle ajoute la flèche
/// quand la route peut être dépilée. Elle ne fait pas la seconde, et un écran
/// atteint par un lien direct, par une notification ou par une redirection de
/// droits se retrouve alors sans sortie visible. C'est le cas de l'écran
/// « accès non autorisé », où la personne arrive sans l'avoir demandé.
///
/// [routeRepli] est la destination du bouton d'accueil. Elle dépend du rôle,
/// d'où le passage par l'appelant plutôt qu'une valeur fixe.
class BarreTitre extends StatelessWidget implements PreferredSizeWidget {
  const BarreTitre({
    super.key,
    required this.titre,
    this.sousTitre,
    this.actions,
    this.routeRepli,
    this.bas,
  });

  final String titre;

  /// Précision affichée sous le titre, en plus petit. Sert à situer l'écran
  /// quand le titre seul est ambigu, « Champ Nord » sous « Recommandations ».
  final String? sousTitre;

  final List<Widget>? actions;

  /// Où envoyer la personne quand il n'y a rien à dépiler.
  final String? routeRepli;

  /// Contenu supplémentaire sous la barre, des onglets par exemple.
  final PreferredSizeWidget? bas;

  @override
  Size get preferredSize => Size.fromHeight(
        (sousTitre == null ? kToolbarHeight : kToolbarHeight + 16) +
            (bas?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    // `context.canPop()` lève une exception hors d'un GoRouter. La barre doit
    // pouvoir servir dans un écran monté seul, en test ou en planche de
    // relecture : elle retombe alors sur le `Navigator` ordinaire.
    final routeur = GoRouter.maybeOf(context);
    final peutDepiler =
        routeur != null ? routeur.canPop() : Navigator.canPop(context);

    return AppBar(
      titleSpacing: peutDepiler ? 0 : null,
      leading: peutDepiler
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              // Libellé parlé explicite : la flèche seule ne dit pas où elle
              // ramène.
              tooltip: 'Revenir à l\'écran précédent',
              onPressed: () => context.pop(),
            )
          : (routeRepli == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.home_rounded),
                  tooltip: 'Revenir à l\'accueil',
                  onPressed: () => context.go(routeRepli!),
                )),
      title: sousTitre == null
          ? Text(titre)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titre),
                Text(
                  sousTitre!,
                  style: textes.bodySmall?.copyWith(
                    color: couleurs.texteSecondaire,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
      actions: actions,
      bottom: bas,
    );
  }
}
