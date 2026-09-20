import 'package:flutter/material.dart';

/// Palette de couleurs de l'application KoobalaTech
class AppColors {
  AppColors._();

  // Couleurs primaires
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF0F6E56);
  static const Color primaryLight = Color(0xFF5DCAA5);

  // Couleurs secondaires
  static const Color amber = Color(0xFFEF9F27);
  static const Color amberDark = Color(0xFFBA7517);
  static const Color amberLight = Color(0xFFFFC96F);

  // Alertes
  static const Color coral = Color(0xFFD85A30);
  static const Color danger = Color(0xFFE53935);
  static const Color teal = Color(0xFF00897B);
  static const Color info = Color(0xFF1976D2);

  // Succès
  static const Color success = Color(0xFF43A047);

  // Neutres
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Statuts cultures
  static const Color statusPrevu = Color(0xFF9E9E9E);
  static const Color statusEnCours = Color(0xFF1D9E75);
  static const Color statusRecolte = Color(0xFFEF9F27);
  static const Color statusEnTraitement = Color(0xFFD85A30);
  static const Color statusAbandonne = Color(0xFFE53935);

  // Niveaux d'alerte
  static const Color alerteCritique = Color(0xFFE53935);
  static const Color alerteEleve = Color(0xFFD85A30);
  static const Color alerteModere = Color(0xFFEF9F27);
  static const Color alerteFaible = Color(0xFF1976D2);

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
  );
}
