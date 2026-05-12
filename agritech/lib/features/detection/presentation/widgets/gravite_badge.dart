import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/enums/niveau_gravite.dart';

/// Badge coloré indiquant le niveau de gravité — pulse si CRITIQUE
class GraviteBadge extends StatefulWidget {
  const GraviteBadge({required this.gravite, this.compact = false, super.key});

  final NiveauGravite gravite;
  final bool compact;

  @override
  State<GraviteBadge> createState() => _GraviteBadgeState();
}

class _GraviteBadgeState extends State<GraviteBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.gravite == NiveauGravite.critique) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleur = widget.gravite.couleur;
    final fond = widget.gravite.couleurFond;

    final badge = Container(
      padding: widget.compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.gravite.icone,
              size: widget.compact ? 12 : 14, color: couleur),
          const SizedBox(width: 4),
          Text(
            widget.gravite.libelle,
            style: GoogleFonts.poppins(
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: couleur,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (widget.gravite != NiveauGravite.critique) return badge;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: badge,
    );
  }
}
