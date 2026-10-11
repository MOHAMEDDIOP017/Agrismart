import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatutCulture {
  prevu,
  enCours,
  recolte,
  abandonne;

  String get libelle {
    switch (this) {
      case StatutCulture.prevu:
        return 'Prévu';
      case StatutCulture.enCours:
        return 'En cours';
      case StatutCulture.recolte:
        return 'Récolté';
      case StatutCulture.abandonne:
        return 'Abandonné';
    }
  }

  /// Couleur du statut, en mode clair. Voir [couleurDe] pour la version qui
  /// suit le mode d'affichage.
  Color get couleur {
    switch (this) {
      case StatutCulture.prevu:
        return AppPalette.info;
      case StatutCulture.enCours:
        return AppPalette.vert;
      case StatutCulture.recolte:
        return AppPalette.ocreEncre;
      case StatutCulture.abandonne:
        return AppPalette.encreDouce;
    }
  }

  /// Couleur du statut résolue pour le mode d'affichage en cours.
  Color couleurDe(CouleursAgriSmart couleurs) {
    switch (this) {
      case StatutCulture.prevu:
        return couleurs.statutPrevu;
      case StatutCulture.enCours:
        return couleurs.statutEnCours;
      case StatutCulture.recolte:
        return couleurs.statutRecolte;
      case StatutCulture.abandonne:
        return couleurs.statutAbandonne;
    }
  }

  static StatutCulture fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EN_COURS':
        return StatutCulture.enCours;
      case 'RECOLTE':
        return StatutCulture.recolte;
      case 'ABANDONNE':
        return StatutCulture.abandonne;
      default:
        return StatutCulture.prevu;
    }
  }

  String toJson() {
    switch (this) {
      case StatutCulture.prevu:
        return 'PREVU';
      case StatutCulture.enCours:
        return 'EN_COURS';
      case StatutCulture.recolte:
        return 'RECOLTE';
      case StatutCulture.abandonne:
        return 'ABANDONNE';
    }
  }
}
