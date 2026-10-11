import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Décoration partagée pour les champs de formulaire Admin
InputDecoration adminDecorChamp(
  BuildContext context,
  String label,
  IconData icone,
) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icone, size: 20),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.couleurs.bordure),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.couleurs.bordure),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF534AB7), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// Titre de section avec séparateur horizontal (formulaires Admin)
class AdminSectionTitre extends StatelessWidget {
  const AdminSectionTitre({
    super.key,
    required this.titre,
    required this.icone,
  });

  final String titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: const Color(0xFF534AB7)),
        const SizedBox(width: 8),
        Text(
          titre,
          style: AppTypography.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF534AB7),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
