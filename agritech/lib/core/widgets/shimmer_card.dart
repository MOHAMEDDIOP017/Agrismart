import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Card shimmer pour afficher pendant le chargement de listes
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.divider,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: height,
              height: height,
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            // Texte placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 14, width: 140, color: AppColors.border),
                    Container(height: 10, width: 100, color: AppColors.border),
                    Container(height: 10, width: 80, color: AppColors.border),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste de shimmer cards pour le chargement
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.count = 5, this.cardHeight = 100});

  final int count;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => ShimmerCard(height: cardHeight),
    );
  }
}
