import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_motion.dart';

/// Carte KPI animée pour le tableau de bord Admin
class KpiAdminCard extends StatelessWidget {
  const KpiAdminCard({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
    this.sousTitre,
    this.onTap,
  });

  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;
  final String? sousTitre;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.couleurs.bordure),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône dans un cercle coloré
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 20),
            ),
            const SizedBox(height: 10),
            // Valeur principale avec animation
            Text(
              valeur,
              style: AppTypography.textTheme.headlineMedium!.copyWith(
                color: couleur,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 4),
            // Titre
            Text(
              titre,
              style: AppTypography.textTheme.bodySmall!.copyWith(
                color: context.couleurs.texteSecondaire,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (sousTitre != null) ...[
              const SizedBox(height: 2),
              Text(
                sousTitre!,
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: couleur,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compteur animé de 0 → valeur cible
class AnimatedCounterAdmin extends StatefulWidget {
  const AnimatedCounterAdmin({
    super.key,
    required this.valeur,
    required this.style,
    this.duree = AppDurees.moyenne,
    this.suffixe = '',
  });

  final int valeur;
  final TextStyle style;
  final Duration duree;
  final String suffixe;

  @override
  State<AnimatedCounterAdmin> createState() => _AnimatedCounterAdminState();
}

class _AnimatedCounterAdminState extends State<AnimatedCounterAdmin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duree);
    _animation = Tween<double>(begin: 0, end: widget.valeur.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounterAdmin old) {
    super.didUpdateWidget(old);
    if (old.valeur != widget.valeur) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.valeur.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Text(
        '${_animation.value.toInt()}${widget.suffixe}',
        style: widget.style,
      ),
    );
  }
}
