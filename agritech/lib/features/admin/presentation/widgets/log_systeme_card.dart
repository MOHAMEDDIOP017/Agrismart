import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/log_systeme_entity.dart';

/// Carte d'un log système dans l'historique
class LogSystemeCard extends StatelessWidget {
  const LogSystemeCard({
    super.key,
    required this.log,
    required this.onArchiver,
  });

  final LogSystemeEntity log;
  final VoidCallback onArchiver;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: context.couleurs.texteSecondaire,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onArchiver();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: log.type.couleur.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type log
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: log.type.couleurFond,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(log.type.icone, size: 18, color: log.type.couleur),
            ),
            const SizedBox(width: 12),
            // Corps du log
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge type + horodatage
                  Row(
                    children: [
                      _TypeBadge(log: log),
                      const Spacer(),
                      Text(
                        log.horodatageFormate,
                        style: AppTypography.textTheme.labelSmall!.copyWith(
                          color: context.couleurs.texteSecondaire,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    log.description,
                    style: AppTypography.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.couleurs.textePrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Utilisateur concerné
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 12, color: context.couleurs.texteSecondaire),
                      const SizedBox(width: 4),
                      Text(
                        '${log.utilisateurNom} • ${log.utilisateurRole.libelle}',
                        style: AppTypography.textTheme.labelSmall!.copyWith(
                          color: context.couleurs.texteSecondaire,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.log});

  final LogSystemeEntity log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: log.type.couleurFond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        log.type.libelle,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: log.type.couleur,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
