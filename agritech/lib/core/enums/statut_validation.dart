import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

  /// Couleur du statut, en mode clair.
  ///
  /// Conservée pour les écrans qui n'ont pas encore de `BuildContext` sous la
  /// main. Un composant qui doit suivre le mode sombre appelle [couleurDe].
  Color get couleur {
    switch (this) {
      case StatutValidation.enAttente:
        return AppPalette.avertissement;
      case StatutValidation.validee:
        return AppPalette.succes;
      case StatutValidation.corrigee:
        return AppPalette.info;
      case StatutValidation.rejetee:
        return AppPalette.erreur;
    }
  }

  /// Couleur du statut résolue pour le mode d'affichage en cours.
  ///
  /// Le statut reste une donnée métier : l'enum décide quelle famille
  /// sémantique lui correspond, le thème décide de la teinte. Les hex étaient
  /// auparavant écrits ici en double de la palette, sans rien pour garantir
  /// qu'ils resteraient synchronisés.
  Color couleurDe(CouleursAgriSmart couleurs) {
    switch (this) {
      case StatutValidation.enAttente:
        return couleurs.validationEnAttente;
      case StatutValidation.validee:
        return couleurs.validationValidee;
      case StatutValidation.corrigee:
        return couleurs.validationCorrigee;
      case StatutValidation.rejetee:
        return couleurs.validationRejetee;
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
