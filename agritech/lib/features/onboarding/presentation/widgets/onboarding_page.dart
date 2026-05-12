import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Données d'une page d'onboarding
class OnboardingData {
  const OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color backgroundColor;
}

/// Widget d'une page d'onboarding individuelle
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.data,
    required this.isActive,
  });

  final OnboardingData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration animée
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: size.width * 0.65,
            height: size.width * 0.65,
            decoration: BoxDecoration(
              color: data.backgroundColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              data.icon,
              size: size.width * 0.3,
              color: data.iconColor,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 48),

          // Titre
          Text(
            data.title,
            style: AppTypography.textTheme.displayMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Sous-titre
          Text(
            data.subtitle,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 250.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
