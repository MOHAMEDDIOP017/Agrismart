import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
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
              if (estAlerte && valeur > 0) _PulseDot(couleur: couleur),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCounter(
            value: valeur,
            style: AppTypography.police(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: estAlerte && valeur > 0 ? couleur : couleur,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            libelle,
            style: AppTypography.police(
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
/// Point d'attention d'une carte d'indicateur.
///
/// Il clignotait en boucle. Un point qui bat attire l'œil en continu sur un
/// écran que l'expert garde ouvert : il finit par être ignoré, et il occupe le
/// processeur graphique pour cela.
class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
      );
}
