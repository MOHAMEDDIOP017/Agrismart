import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/champ_entity.dart';
import 'statut_badge.dart';

/// Carte d'un champ avec Hero animation sur l'image
class ChampCard extends StatelessWidget {
  const ChampCard({
    super.key,
    required this.champ,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final ChampEntity champ;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('champ_${champ.id}'),
      background: const _DismissBackground(isLeft: false),
      secondaryBackground: const _DismissBackground(isLeft: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe gauche = supprimer
          return await _confirmDelete(context);
        } else {
          // Swipe droite = modifier
          onEdit?.call();
          return false;
        }
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Image avec Hero animation
              Hero(
                tag: 'champ_image_${champ.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: champ.photoUrl ?? AssetsConstants.fieldPlaceholder,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.border,
                      highlightColor: AppColors.divider,
                      child: Container(
                        width: 96,
                        height: 96,
                        color: AppColors.border,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 96,
                      height: 96,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.terrain_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

              // Infos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              champ.nom,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatutBadge(statut: champ.statut, small: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.straighten_rounded,
                        text: champ.superficieFormatee,
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.layers_outlined,
                        text: 'Sol ${champ.typeSol}',
                      ),
                      if (champ.culture != null) ...[
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.grass_rounded,
                          text: champ.culture!,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce champ ?'),
        content: Text(
          'Le champ "${champ.nom}" et toutes ses données seront supprimés définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isLeft ? AppColors.danger : AppColors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLeft ? Icons.delete_rounded : Icons.edit_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            isLeft ? 'Supprimer' : 'Modifier',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
