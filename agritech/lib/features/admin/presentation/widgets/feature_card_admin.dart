import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Carte d'accès rapide pour le dashboard Admin
class FeatureCardAdmin extends StatefulWidget {
  const FeatureCardAdmin({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.couleur,
    required this.onTap,
    this.badgeCount,
    this.index = 0,
  });

  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  /// Nombre affiché en badge (ex: assignations en attente)
  final int? badgeCount;
  final int index;

  @override
  State<FeatureCardAdmin> createState() => _FeatureCardAdminState();
}

class _FeatureCardAdminState extends State<FeatureCardAdmin> {
  bool _navigating = false;

  void _handleTap() {
    if (_navigating) return;
    setState(() => _navigating = true);
    widget.onTap();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _navigating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.couleur.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: widget.couleur.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.couleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icone, color: widget.couleur, size: 22),
                ),
                const Spacer(),
                if (widget.badgeCount != null && widget.badgeCount! > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.couleur,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              widget.titre,
              style: AppTypography.textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: context.couleurs.textePrincipal,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.sousTitre,
              style: AppTypography.textTheme.labelSmall!.copyWith(
                color: context.couleurs.texteSecondaire,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
