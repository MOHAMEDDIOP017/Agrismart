import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Cercle de score de confiance avec animation de remplissage
class ScoreCircle extends StatefulWidget {
  const ScoreCircle({
    required this.scorePourcent,
    this.taille = 100,
    super.key,
  });

  final int scorePourcent;
  final double taille;

  @override
  State<ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<ScoreCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: widget.scorePourcent / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _couleurScore(int score) {
    if (score >= 75) return AppColors.primary;
    if (score >= 50) return AppColors.amber;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurScore(widget.scorePourcent);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final valeur = _anim.value;
        final affiche = (valeur * 100).round();
        return SizedBox(
          width: widget.taille,
          height: widget.taille,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: valeur,
                strokeWidth: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(couleur),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$affiche%',
                    style: GoogleFonts.poppins(
                      fontSize: widget.taille * 0.24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Confiance',
                    style: GoogleFonts.inter(
                      fontSize: widget.taille * 0.11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
