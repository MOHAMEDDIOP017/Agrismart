import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/detection/domain/enums/niveau_gravite.dart';

/// Badge de gravité avec animation pulse si CRITIQUE
class GraviteBadge extends StatefulWidget {
  const GraviteBadge({
    super.key,
    required this.gravite,
    this.compact = false,
  });

  final NiveauGravite gravite;
  final bool compact;

  @override
  State<GraviteBadge> createState() => _GraviteBadgeState();
}

class _GraviteBadgeState extends State<GraviteBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.gravite == NiveauGravite.critique) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 10,
        vertical: widget.compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: widget.gravite.couleurFond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.gravite.couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.gravite.icone, size: widget.compact ? 10 : 12, color: widget.gravite.couleur),
          const SizedBox(width: 4),
          Text(
            widget.gravite.libelle,
            style: GoogleFonts.poppins(
              fontSize: widget.compact ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: widget.gravite.couleur,
            ),
          ),
        ],
      ),
    );

    if (widget.gravite == NiveauGravite.critique) {
      return ScaleTransition(scale: _pulse, child: badge);
    }
    return badge;
  }
}
