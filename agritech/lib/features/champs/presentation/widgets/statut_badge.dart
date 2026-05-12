import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Badge coloré indiquant le statut d'un champ
class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut, this.small = false});

  final String statut;
  final bool small;

  Color get _couleur => switch (statut) {
        AppConstants.statutPrevu => AppColors.statusPrevu,
        AppConstants.statutEnCours => AppColors.statusEnCours,
        AppConstants.statutRecolte => AppColors.statusRecolte,
        AppConstants.statutEnTraitement => AppColors.statusEnTraitement,
        AppConstants.statutAbandonne => AppColors.statusAbandonne,
        _ => AppColors.statusPrevu,
      };

  String get _libelle => switch (statut) {
        AppConstants.statutPrevu => 'Prévu',
        AppConstants.statutEnCours => 'En cours',
        AppConstants.statutRecolte => 'Récolte',
        AppConstants.statutEnTraitement => 'Traitement',
        AppConstants.statutAbandonne => 'Abandonné',
        _ => statut,
      };

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 10.0 : 12.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _couleur,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _libelle,
            style: TextStyle(
              color: _couleur,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
