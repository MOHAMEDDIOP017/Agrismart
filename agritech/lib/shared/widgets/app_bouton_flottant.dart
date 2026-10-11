import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Bouton d'action flottant, avec son libellé toujours écrit.
///
/// La forme étendue est le défaut, et non une option. Un bouton rond portant
/// une seule icône suppose que l'icône soit comprise : un « + » est à peu près
/// universel, mais une cible, une feuille ou un engrenage ne le sont pas. Le
/// cahier des charges demande un libellé à côté de chaque icône, et c'est
/// l'une des rares surfaces où l'application le refusait.
///
/// La variante compacte existe quand la place manque vraiment, par exemple
/// par-dessus une carte, et elle exige alors une [etiquette] pour les lecteurs
/// d'écran.
class AppBoutonFlottant extends StatefulWidget {
  const AppBoutonFlottant({
    super.key,
    required this.libelle,
    required this.icone,
    required this.onPressed,
    this.heroTag,
  })  : compact = false,
        etiquette = null;

  const AppBoutonFlottant.compact({
    super.key,
    required this.icone,
    required this.onPressed,
    required String this.etiquette,
    this.heroTag,
  })  : compact = true,
        libelle = '';

  final String libelle;
  final IconData icone;
  final VoidCallback? onPressed;
  final bool compact;

  /// Obligatoire en forme compacte : c'est la seule description disponible.
  final String? etiquette;

  /// Nécessaire quand deux boutons flottants coexistent dans l'arbre, sans
  /// quoi Flutter refuse de construire la transition entre les deux pages.
  final Object? heroTag;

  @override
  State<AppBoutonFlottant> createState() => _AppBoutonFlottantState();
}

class _AppBoutonFlottantState extends State<AppBoutonFlottant> {
  bool _appuye = false;

  void _majAppui(bool appuye) {
    if (widget.onPressed == null || _appuye == appuye) return;
    setState(() => _appuye = appuye);
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    final bouton = widget.compact
        ? FloatingActionButton(
            onPressed: widget.onPressed,
            heroTag: widget.heroTag,
            tooltip: widget.etiquette,
            child: Icon(widget.icone, size: 26),
          )
        : FloatingActionButton.extended(
            onPressed: widget.onPressed,
            heroTag: widget.heroTag,
            icon: Icon(widget.icone, size: 24),
            label: Text(widget.libelle),
            // 56 de haut comme les boutons pleins : la cible reste la même
            // d'un bout à l'autre de l'application.
            extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
          );

    return Semantics(
      button: true,
      label: widget.etiquette,
      child: Listener(
        onPointerDown: (_) => _majAppui(true),
        onPointerUp: (_) => _majAppui(false),
        onPointerCancel: (_) => _majAppui(false),
        child: AnimatedScale(
          scale: _appuye ? 0.96 : 1,
          duration: AppMouvement.duree(context, AppDurees.appui),
          curve: AppCourbes.sortie,
          child: Theme(
            // Le bouton flottant reprend la couleur primaire du thème, mais
            // son contenu doit rester lisible si l'écran l'affiche sur un fond
            // déjà coloré : la couleur du dessus est fixée explicitement.
            data: Theme.of(context).copyWith(
              floatingActionButtonTheme:
                  Theme.of(context).floatingActionButtonTheme.copyWith(
                        backgroundColor: couleurs.primaire,
                        foregroundColor: couleurs.surPrimaire,
                      ),
            ),
            child: bouton,
          ),
        ),
      ),
    );
  }
}
