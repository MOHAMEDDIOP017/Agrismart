import 'package:flutter/material.dart';
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

  Color _niveauColor(BuildContext context) => switch (alerte.niveau) {
        AppConstants.alerteCritique => context.couleurs.alerteCritique,
        AppConstants.alerteEleve => context.couleurs.alerteElevee,
        AppConstants.alerteModere => context.couleurs.alerteModeree,
        _ => context.couleurs.alerteFaible,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.couleurs.bordure),
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
                  color: _niveauColor(context),
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
                            _PulsingIcon(color: _niveauColor(context)),
                          if (!alerte.isLue) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alerte.titre,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: alerte.isLue
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge niveau
                          _NiveauBadge(
                              niveau: alerte.niveau,
                              color: _niveauColor(context)),
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
                          Icon(Icons.terrain_outlined,
                              size: 12,
                              color: context.couleurs.texteSecondaire),
                          const SizedBox(width: 4),
                          Text(
                            alerte.champNom,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: context.couleurs.primaire),
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
    );
  }
}

class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.circle, size: 10, color: color);
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
