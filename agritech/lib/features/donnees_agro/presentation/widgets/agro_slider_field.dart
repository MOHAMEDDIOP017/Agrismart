import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Slider agronomique avec indicateur coloré et libellés
class AgroSliderField extends StatelessWidget {
  const AgroSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
    this.divisions,
    this.coloredByValue = false,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final void Function(double) onChanged;
  final String unit;
  final int? divisions;
  final bool coloredByValue;

  Color get _activeColor {
    if (!coloredByValue) return AppColors.primary;
    final ratio = (value - min) / (max - min);
    if (ratio < 0.25) return AppColors.danger;
    if (ratio < 0.45) return AppColors.amber;
    if (ratio < 0.75) return AppColors.primary;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _activeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: _activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _activeColor,
            thumbColor: _activeColor,
            overlayColor: _activeColor.withValues(alpha: 0.15),
            inactiveTrackColor: AppColors.border,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? (max - min).toInt(),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min $unit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$max $unit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
