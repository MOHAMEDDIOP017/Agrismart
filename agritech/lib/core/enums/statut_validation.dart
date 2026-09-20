import 'package:flutter/material.dart';

enum StatutValidation {
  enAttente,
  validee,
  corrigee,
  rejetee;

  String get libelle {
    switch (this) {
      case StatutValidation.enAttente:
        return 'En attente';
      case StatutValidation.validee:
        return 'Validée';
      case StatutValidation.corrigee:
        return 'Corrigée';
      case StatutValidation.rejetee:
        return 'Rejetée';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutValidation.enAttente:
        return const Color(0xFFEF9F27);
      case StatutValidation.validee:
        return const Color(0xFF1D9E75);
      case StatutValidation.corrigee:
        return const Color(0xFF1976D2);
      case StatutValidation.rejetee:
        return const Color(0xFFE53935);
    }
  }

  bool get estEnAttente => this == StatutValidation.enAttente;
  bool get estValidee => this == StatutValidation.validee;
  bool get estCorrigee => this == StatutValidation.corrigee;
  bool get estRejetee => this == StatutValidation.rejetee;
  bool get estTraitee => !estEnAttente;

  static StatutValidation fromString(String value) {
    switch (value.toUpperCase()) {
      case 'VALIDEE':
        return StatutValidation.validee;
      case 'CORRIGEE':
        return StatutValidation.corrigee;
      case 'REJETEE':
        return StatutValidation.rejetee;
      default:
        return StatutValidation.enAttente;
    }
  }

  String toJson() {
    switch (this) {
      case StatutValidation.enAttente:
        return 'EN_ATTENTE';
      case StatutValidation.validee:
        return 'VALIDEE';
      case StatutValidation.corrigee:
        return 'CORRIGEE';
      case StatutValidation.rejetee:
        return 'REJETEE';
    }
  }
}
