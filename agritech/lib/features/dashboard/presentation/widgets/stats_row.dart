import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

/// Ligne de statistiques rapides avec compteurs animés
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.nombreChamps,
    required this.culturesActives,
    required this.derniereAlerte,
  });

  final int nombreChamps;
  final int culturesActives;
  final String derniereAlerte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Champs',
              value: nombreChamps,
              icon: Icons.terrain_rounded,
              color: AppColors.primary,
              delay: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Cultures actives',
              value: culturesActives,
              icon: Icons.grass_rounded,
              color: AppColors.amber,
              delay: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AlerteCard(
              label: 'Alerte',
              value: derniereAlerte,
              delay: 200,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          // Compteur animé de 0 vers value
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1200),
            builder: (_, v, __) => Text(
              '$v',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

class _AlerteCard extends StatelessWidget {
  const _AlerteCard({
    required this.label,
    required this.value,
    required this.delay,
  });

  final String label;
  final String value;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.coral,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }
}
