import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animated_counter.dart';

/// Carte KPI avec compteur animé — tableau de bord Expert
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.valeur,
    required this.libelle,
    required this.icone,
    required this.couleur,
    this.couleurFond,
    this.estAlerte = false,
  });

  final int valeur;
  final String libelle;
  final IconData icone;
  final Color couleur;
  final Color? couleurFond;

  /// Si vrai et valeur > 0 : fond rouge clair, sinon vert
  final bool estAlerte;

  @override
  Widget build(BuildContext context) {
    final fond = couleurFond ??
        (estAlerte && valeur > 0
            ? couleur.withValues(alpha: 0.10)
            : couleur.withValues(alpha: 0.08));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: couleur, size: 20),
              ),
              if (estAlerte && valeur > 0)
                _PulseDot(couleur: couleur),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCounter(
            value: valeur,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: estAlerte && valeur > 0 ? couleur : couleur,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            libelle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Point pulsant rouge pour signaler une urgence
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.couleur});
  final Color couleur;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
        ..repeat(reverse: true);
  late final Animation<double> _a = Tween(begin: 0.4, end: 1.0).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: widget.couleur, shape: BoxShape.circle),
        ),
      );
}
