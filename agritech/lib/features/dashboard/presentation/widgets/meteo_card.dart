import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../meteo/data/models/meteo_model.dart';

/// Carte météo locale avec fond coloré selon les conditions
class MeteoCard extends StatelessWidget {
  const MeteoCard({super.key, required this.meteo});

  final MeteoModel meteo;

  Color get _backgroundColor {
    return switch (meteo.icone) {
      'sunny' => const Color(0xFFFFF3CD),
      'rainy' => const Color(0xFFDCEEF8),
      'stormy' => const Color(0xFFDDE0E6),
      _ => const Color(0xFFE8F4F1),
    };
  }

  Color get _accentColor {
    return switch (meteo.icone) {
      'sunny' => AppColors.amber,
      'rainy' => AppColors.info,
      'stormy' => const Color(0xFF546E7A),
      _ => AppColors.primary,
    };
  }

  IconData get _weatherIcon {
    return switch (meteo.icone) {
      'sunny' => Icons.wb_sunny_rounded,
      'rainy' => Icons.grain_rounded,
      'stormy' => Icons.thunderstorm_rounded,
      _ => Icons.cloud_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône météo animée
          Icon(_weatherIcon, size: 56, color: _accentColor)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds,
              ),
          const SizedBox(width: 16),

          // Données météo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meteo.ville,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  meteo.temperatureLabel,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  meteo.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Humidité et vent
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MeteoStat(
                icon: Icons.water_drop_outlined,
                value: meteo.humiditeLabel,
                color: AppColors.info,
              ),
              const SizedBox(height: 8),
              _MeteoStat(
                icon: Icons.air_rounded,
                value: meteo.ventLabel,
                color: AppColors.textSecondary,
              ),
              if (meteo.pluviometrie > 0) ...[
                const SizedBox(height: 8),
                _MeteoStat(
                  icon: Icons.umbrella_outlined,
                  value: meteo.pluviometrieLabel,
                  color: AppColors.info,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MeteoStat extends StatelessWidget {
  const _MeteoStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
