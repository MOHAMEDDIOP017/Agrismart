import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../alertes/data/models/alerte_model.dart';

/// Carte d'une alerte agronomique avec bordure colorée selon urgence
class AlerteCard extends StatelessWidget {
  const AlerteCard({
    super.key,
    required this.alerte,
    required this.index,
    required this.onTap,
  });

  final AlerteModel alerte;
  final int index;
  final VoidCallback onTap;

  Color get _niveauColor => switch (alerte.niveau) {
        AppConstants.alerteCritique => AppColors.alerteCritique,
        AppConstants.alerteEleve => AppColors.alerteEleve,
        AppConstants.alerteModere => AppColors.alerteModere,
        _ => AppColors.alerteFaible,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Bordure colorée gauche
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: _niveauColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icône pulsante si non lue
                          if (!alerte.isLue)
                            _PulsingIcon(color: _niveauColor),
                          if (!alerte.isLue) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alerte.titre,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: alerte.isLue
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge niveau
                          _NiveauBadge(niveau: alerte.niveau, color: _niveauColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alerte.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.terrain_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            alerte.champNom,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const Spacer(),
                          Text(
                            DateFormatter.formatRelative(alerte.dateCreation),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 350.ms)
        .slideX(begin: 0.15, end: 0);
  }
}

class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.circle, size: 10, color: color)
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.4, 1.4),
          duration: 700.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.4, 1.4),
          end: const Offset(1, 1),
          duration: 700.ms,
        );
  }
}

class _NiveauBadge extends StatelessWidget {
  const _NiveauBadge({required this.niveau, required this.color});
  final String niveau;
  final Color color;

  String get _libelle => switch (niveau) {
        AppConstants.alerteCritique => 'CRITIQUE',
        AppConstants.alerteEleve => 'ÉLEVÉ',
        AppConstants.alerteModere => 'MODÉRÉ',
        _ => 'FAIBLE',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _libelle,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
