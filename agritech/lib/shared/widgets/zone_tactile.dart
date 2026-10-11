import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';

/// Rend un élément touchable, avec une cible assez grande et un retour
/// immédiat sous le doigt.
///
/// Remplace les 26 `GestureDetector` nus relevés par l'audit. Un
/// `GestureDetector` capte bien l'appui, mais il ne donne aucun signe que
/// l'appui a été reçu et n'impose aucune taille minimale. Sur un écran tenu à
/// bout de bras en plein champ, cela produit deux défauts : on ne sait pas si
/// l'application a entendu, et on rate la cible.
///
/// L'enfoncement est préféré à l'onde de Material pour deux raisons. Il
/// commence au premier contact, là où l'onde met le temps de se propager pour
/// devenir visible. Et il ne demande pas d'ancêtre `Material`, ce qui permet
/// de rendre touchable n'importe quelle composition, y compris une carte
/// dessinée à la main.
///
/// La zone tactile est portée à [tailleMinimale] même quand le contenu est
/// plus petit : une pastille de 20 px de haut reste atteignable.
class ZoneTactile extends StatefulWidget {
  const ZoneTactile({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.rayon = AppRayons.brCarte,
    this.tailleMinimale = 48,
    this.etiquette,
    this.estBouton = true,
    this.echelleAppui = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Rayon utilisé pour découper le contenu pendant l'enfoncement.
  final BorderRadius rayon;

  /// Côté minimal de la zone sensible, en points. La valeur par défaut est
  /// celle que recommandent les règles d'accessibilité d'Android et d'iOS.
  /// `null` laisse le contenu décider, pour les cas où forcer 48 casserait la
  /// mise en page.
  final double? tailleMinimale;

  /// Description lue par les lecteurs d'écran, quand le contenu visible ne
  /// suffit pas à comprendre l'action.
  final String? etiquette;

  /// Annonce l'élément comme un bouton aux outils d'accessibilité.
  final bool estBouton;

  /// Facteur de réduction au moment de l'appui. 0,97 se perçoit sans donner
  /// l'impression que l'élément recule.
  final double echelleAppui;

  @override
  State<ZoneTactile> createState() => _ZoneTactileState();
}

class _ZoneTactileState extends State<ZoneTactile> {
  bool _appuye = false;

  bool get _actif => widget.onTap != null || widget.onLongPress != null;

  void _majAppui(bool appuye) {
    if (!_actif || _appuye == appuye) return;
    setState(() => _appuye = appuye);
  }

  @override
  Widget build(BuildContext context) {
    Widget contenu = widget.child;

    if (widget.tailleMinimale != null) {
      contenu = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.tailleMinimale!,
          minHeight: widget.tailleMinimale!,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: contenu),
      );
    }

    contenu = AnimatedScale(
      scale: _appuye ? widget.echelleAppui : 1,
      duration: AppMouvement.duree(context, AppDurees.appui),
      curve: AppCourbes.sortie,
      child: ClipRRect(borderRadius: widget.rayon, child: contenu),
    );

    return Semantics(
      button: widget.estBouton && _actif,
      label: widget.etiquette,
      enabled: _actif,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _majAppui(true),
        onTapUp: (_) => _majAppui(false),
        onTapCancel: () => _majAppui(false),
        child: contenu,
      ),
    );
  }
}
