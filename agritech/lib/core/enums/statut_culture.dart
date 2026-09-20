import 'package:flutter/material.dart';

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

  Color get couleur {
    switch (this) {
      case StatutCulture.prevu:
        return const Color(0xFF1976D2);
      case StatutCulture.enCours:
        return const Color(0xFF1D9E75);
      case StatutCulture.recolte:
        return const Color(0xFFEF9F27);
      case StatutCulture.abandonne:
        return const Color(0xFF9E9E9E);
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
