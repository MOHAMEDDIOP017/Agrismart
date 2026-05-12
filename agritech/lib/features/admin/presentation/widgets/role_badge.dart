import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Badge coloré affichant le rôle d'un utilisateur
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.compact = false});

  final RoleUtilisateur role;
  final bool compact;

  static const Color _couleurAgriculteur = Color(0xFF1D9E75);
  static const Color _couleurExpert = Color(0xFF534AB7);
  static const Color _couleurAdmin = Color(0xFF888780);

  Color get _couleur {
    switch (role) {
      case RoleUtilisateur.agriculteur:
        return _couleurAgriculteur;
      case RoleUtilisateur.expert:
        return _couleurExpert;
      case RoleUtilisateur.admin:
        return _couleurAdmin;
    }
  }

  IconData get _icone {
    switch (role) {
      case RoleUtilisateur.agriculteur:
        return Icons.agriculture_outlined;
      case RoleUtilisateur.expert:
        return Icons.verified_user_outlined;
      case RoleUtilisateur.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icone, size: compact ? 10 : 12, color: _couleur),
          const SizedBox(width: 4),
          Text(
            role.libelle.toUpperCase(),
            style: AppTypography.textTheme.labelSmall!.copyWith(
              color: _couleur,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}
