import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Sujet d'une illustration d'état.
enum SujetIllustration {
  /// Une parcelle sans culture : rien n'a encore été enregistré.
  parcelle,

  /// Le réseau est coupé.
  reseau,

  /// Une recherche sans résultat.
  recherche,
}

/// Illustration dessinée pour accompagner un état vide ou une erreur.
///
/// Dessinée et non importée, pour trois raisons.
///
/// Les dossiers d'assets du projet étaient vides, alors que le code déclarait
/// quatorze animations Lottie et trois images inexistantes : toute lecture de
/// ces chemins levait une exception. Il n'y avait donc aucune illustration à
/// récupérer.
///
/// Un fichier Lottie se décode à chaque affichage et coûte plus cher qu'un
/// tracé de quelques courbes sur un téléphone d'entrée de gamme. Une image
/// distante, elle, demanderait le réseau, ce qui est absurde pour illustrer
/// précisément l'écran qui s'affiche quand le réseau manque.
///
/// Un tracé prend enfin ses couleurs dans le thème, donc s'adapte au mode
/// sombre sans second jeu de fichiers.
class Illustration extends StatelessWidget {
  const Illustration({
    super.key,
    required this.sujet,
    this.taille = 140,
  });

  final SujetIllustration sujet;

  /// Largeur souhaitée. La hauteur suit dans un rapport de 10 sur 14.
  final double taille;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    return ExcludeSemantics(
      // L'illustration ne porte aucune information que le titre et le message
      // ne disent déjà. L'annoncer à un lecteur d'écran ajouterait du bruit.
      child: SizedBox(
        width: taille,
        height: taille * 100 / 140,
        child: CustomPaint(
          painter: _PeintreIllustration(
            sujet: sujet,
            trait: couleurs.primaire,
            remplissage: couleurs.primaireVoile,
            attenue: couleurs.texteSecondaire,
          ),
        ),
      ),
    );
  }
}

class _PeintreIllustration extends CustomPainter {
  _PeintreIllustration({
    required this.sujet,
    required this.trait,
    required this.remplissage,
    required this.attenue,
  });

  final SujetIllustration sujet;
  final Color trait;
  final Color remplissage;
  final Color attenue;

  /// Espace de dessin de référence. Les coordonnées ci-dessous sont écrites
  /// dedans, puis mises à l'échelle de la taille demandée.
  static const Size _reference = Size(140, 100);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
        size.width / _reference.width, size.height / _reference.height);

    // 3 px de trait et non 1 : un trait fin disparaît sous une forte
    // luminosité, comme le reste de l'interface.
    final crayon = Paint()
      ..color = trait
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pinceau = Paint()
      ..color = remplissage
      ..style = PaintingStyle.fill;

    switch (sujet) {
      case SujetIllustration.parcelle:
        _sillons(canvas, crayon, nombre: 3);
        _pousse(canvas, crayon, pinceau);
      case SujetIllustration.reseau:
        _sillons(canvas, crayon, nombre: 2);
        _signalCoupe(canvas, crayon);
      case SujetIllustration.recherche:
        _sillons(canvas, crayon, nombre: 2);
        _loupe(canvas, crayon, pinceau);
    }

    canvas.restore();
  }

  /// Sillons de labour, repère commun aux trois sujets : l'illustration dit
  /// d'abord qu'on parle d'une parcelle.
  void _sillons(Canvas canvas, Paint crayon, {required int nombre}) {
    final attenueCrayon = Paint()
      ..color = attenue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const depart = [
      (8.0, 84.0, 132.0, 84.0, 64.0),
      (14.0, 94.0, 126.0, 94.0, 76.0),
      (26.0, 74.0, 114.0, 74.0, 58.0),
    ];

    for (var i = 0; i < nombre && i < depart.length; i++) {
      final (x1, y1, x2, y2, controle) = depart[i];
      final chemin = Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(_reference.width / 2, controle, x2, y2);
      canvas.drawPath(chemin, attenueCrayon);
    }
  }

  /// Jeune plant : une tige et deux feuilles.
  void _pousse(Canvas canvas, Paint crayon, Paint pinceau) {
    canvas.drawLine(const Offset(70, 70), const Offset(70, 30), crayon);

    final gauche = Path()
      ..moveTo(70, 54)
      ..quadraticBezierTo(50, 52, 46, 32)
      ..quadraticBezierTo(64, 34, 70, 54)
      ..close();

    final droite = Path()
      ..moveTo(70, 46)
      ..quadraticBezierTo(90, 44, 94, 24)
      ..quadraticBezierTo(76, 26, 70, 46)
      ..close();

    canvas.drawPath(gauche, pinceau);
    canvas.drawPath(gauche, crayon);
    canvas.drawPath(droite, pinceau);
    canvas.drawPath(droite, crayon);
  }

  /// Ondes de signal barrées.
  void _signalCoupe(Canvas canvas, Paint crayon) {
    const origine = Offset(70, 68);
    canvas.drawCircle(origine, 4, Paint()..color = trait);

    // Arcs ouverts vers le haut, de plus en plus larges.
    for (final rayon in [16.0, 28.0, 40.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: origine, radius: rayon),
        -math.pi * 5 / 6,
        math.pi * 2 / 3,
        false,
        crayon,
      );
    }

    // La barre oblique est le seul élément qui dit « coupé » : elle est tracée
    // plus épaisse pour rester lisible quand l'illustration est réduite.
    canvas.drawLine(
      const Offset(44, 16),
      const Offset(100, 76),
      Paint()
        ..color = trait
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Loupe, pour une recherche sans résultat.
  void _loupe(Canvas canvas, Paint crayon, Paint pinceau) {
    const centre = Offset(80, 40);
    canvas.drawCircle(centre, 20, pinceau);
    canvas.drawCircle(centre, 20, crayon);
    canvas.drawLine(const Offset(66, 55), const Offset(48, 72), crayon);
  }

  @override
  bool shouldRepaint(_PeintreIllustration ancien) =>
      ancien.sujet != sujet ||
      ancien.trait != trait ||
      ancien.remplissage != remplissage ||
      ancien.attenue != attenue;
}
