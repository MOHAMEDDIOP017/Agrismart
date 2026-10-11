import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Fait apparaître un élément de liste avec un léger retard selon son rang.
///
/// L'audit avait relevé trois conventions concurrentes pour le même effet :
/// 150 ms d'écart sur la carte de culture, 80 ms sur la liste des champs, et
/// des délais fixes de 300, 500 puis 700 ms sur le tableau de bord. Un seul
/// composant les remplace, avec l'écart de 100 ms retenu pour le système.
///
/// L'apparition ne se joue qu'une fois, au premier affichage. Au défilement,
/// les éléments déjà construits ne rejouent rien : une liste qui refait son
/// animation à chaque recyclage de cellule donne une impression de lenteur.
///
/// Quand la réduction des animations est active, l'élément est posé
/// directement à sa place, sans délai ni déplacement.
class ApparitionCascade extends StatefulWidget {
  const ApparitionCascade({
    super.key,
    required this.child,
    required this.index,
    this.deplacement = 16,
  });

  final Widget child;

  /// Rang dans la liste. Le décalage est plafonné par [AppMouvement.decalage],
  /// pour qu'une liste longue ne fasse pas attendre ses derniers éléments.
  final int index;

  /// Distance parcourue à l'apparition, en points, depuis le bas.
  final double deplacement;

  @override
  State<ApparitionCascade> createState() => _ApparitionCascadeState();
}

class _ApparitionCascadeState extends State<ApparitionCascade> {
  double _avancement = 0;
  Timer? _depart;
  bool _programme = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_programme) return;
    _programme = true;

    final delai = AppMouvement.decalage(context, widget.index);
    if (delai == Duration.zero) {
      _avancement = 1;
      return;
    }
    _depart = Timer(delai, () {
      if (mounted) setState(() => _avancement = 1);
    });
  }

  @override
  void dispose() {
    _depart?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _avancement),
      duration: AppMouvement.duree(context, AppDurees.courte),
      curve: AppCourbes.sortie,
      builder: (context, valeur, enfant) {
        // Une seule interpolation pilote l'opacité et le déplacement, plutôt
        // que deux widgets animés superposés.
        return Opacity(
          opacity: valeur,
          child: Transform.translate(
            offset: Offset(0, (1 - valeur) * widget.deplacement),
            child: enfant,
          ),
        );
      },
      child: widget.child,
    );
  }
}
