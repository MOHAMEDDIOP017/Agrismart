import 'dart:math' as math;

import 'package:agritech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que chaque couple texte/fond de la palette atteint le niveau exigé
/// par WCAG 2.1.
///
/// Ce test remplace une vérification faite une fois dans un outil en ligne. La
/// palette d'une application vit : une teinte ajustée pour des raisons
/// esthétiques peut faire passer un couple sous le seuil sans que personne ne
/// s'en aperçoive, parce qu'un écart de 4,5 à 4,2 ne se voit pas à l'œil. Ici
/// la suite de tests échoue.
///
/// Les seuils appliqués sont ceux de la norme :
///
/// - 4,5:1 pour un texte courant (critère 1.4.3, niveau AA) ;
/// - 3:1 pour un texte large, à partir de 18,66 px en gras ou 24 px ;
/// - 3:1 pour la bordure d'un composant interactif (critère 1.4.11).
///
/// Les trois rôles vérifiés par famille sémantique correspondent aux trois
/// usages réels d'une teinte : fond d'aplat portant du texte, couleur de texte
/// sur le fond de page, et fond teinté portant le texte principal.
void main() {
  group('Contraste de la palette — mode clair', () {
    const c = CouleursAgriSmart.clair;

    test('texte courant sur les deux fonds', () {
      verifierAA(c.textePrincipal, c.fond, 'texte principal sur fond');
      verifierAA(c.textePrincipal, c.surface, 'texte principal sur surface');
      verifierAA(c.texteSecondaire, c.fond, 'texte secondaire sur fond');
      verifierAA(c.texteSecondaire, c.surface, 'texte secondaire sur surface');
    });

    test('texte posé sur un aplat de couleur', () {
      verifierAA(c.surPrimaire, c.primaire, 'surPrimaire sur primaire');
      verifierAA(c.surSecondaire, c.secondaire, 'surSecondaire sur secondaire');
      verifierAA(c.surSucces, c.succes, 'surSucces sur succes');
      verifierAA(c.surAvertissement, c.avertissement,
          'surAvertissement sur avertissement');
      verifierAA(c.surErreur, c.erreur, 'surErreur sur erreur');
      verifierAA(c.surInfo, c.info, 'surInfo sur info');
      verifierAA(c.surAlerteElevee, c.alerteElevee,
          'surAlerteElevee sur alerteElevee');
      verifierAA(
          c.surPrimaire, c.primaireFonce, 'surPrimaire sur primaireFonce');
      verifierAA(Colors.white, c.secondaireFonce, 'blanc sur secondaireFonce');
    });

    test('teinte employée comme couleur de texte sur le fond de page', () {
      verifierAA(c.primaire, c.fond, 'primaire en texte sur fond');
      verifierAA(c.primaire, c.surface, 'primaire en texte sur surface');
      verifierAA(c.secondaireTexte, c.fond, 'secondaireTexte sur fond');
      verifierAA(c.secondaireTexte, c.surface, 'secondaireTexte sur surface');
      verifierAA(c.succes, c.fond, 'succes en texte sur fond');
      verifierAA(c.avertissement, c.fond, 'avertissement en texte sur fond');
      verifierAA(c.erreur, c.fond, 'erreur en texte sur fond');
      verifierAA(c.info, c.fond, 'info en texte sur fond');
      verifierAA(c.alerteElevee, c.fond, 'alerteElevee en texte sur fond');
    });

    test('texte principal sur un fond teinté', () {
      // Règle du système : sur un fond `xVoile`, le texte est toujours
      // `textePrincipal`. La teinte de famille n'y est admise qu'en icône, et
      // les icônes relèvent du seuil de 3:1.
      verifierAA(c.textePrincipal, c.primaireVoile, 'texte sur primaireVoile');
      verifierAA(
          c.textePrincipal, c.secondaireVoile, 'texte sur secondaireVoile');
      verifierAA(c.textePrincipal, c.succesVoile, 'texte sur succesVoile');
      verifierAA(c.textePrincipal, c.avertissementVoile,
          'texte sur avertissementVoile');
      verifierAA(c.textePrincipal, c.erreurVoile, 'texte sur erreurVoile');
      verifierAA(c.textePrincipal, c.infoVoile, 'texte sur infoVoile');
    });

    test('bordure des composants interactifs', () {
      verifierComposant(c.bordure, c.fond, 'bordure sur fond');
      verifierComposant(c.bordure, c.surface, 'bordure sur surface');
      verifierComposant(c.primaire, c.surface, 'bordure focus sur surface');
    });

    test('couleurs de statut lisibles en texte sur le fond de page', () {
      verifierAA(c.validationEnAttente, c.surface, 'statut en attente');
      verifierAA(c.validationValidee, c.surface, 'statut validée');
      verifierAA(c.validationCorrigee, c.surface, 'statut corrigée');
      verifierAA(c.validationRejetee, c.surface, 'statut rejetée');
      verifierAA(c.statutPrevu, c.surface, 'statut prévu');
      verifierAA(c.statutEnCours, c.surface, 'statut en cours');
      verifierAA(c.statutRecolte, c.surface, 'statut récolte');
      verifierAA(c.statutEnTraitement, c.surface, 'statut en traitement');
      verifierAA(c.statutAbandonne, c.surface, 'statut abandonné');
    });
  });

  group('Contraste de la palette — mode sombre', () {
    const c = CouleursAgriSmart.sombre;

    test('texte courant sur les deux fonds', () {
      verifierAA(c.textePrincipal, c.fond, 'texte principal sur fond');
      verifierAA(c.textePrincipal, c.surface, 'texte principal sur surface');
      verifierAA(c.texteSecondaire, c.fond, 'texte secondaire sur fond');
      verifierAA(c.texteSecondaire, c.surface, 'texte secondaire sur surface');
      // La surface haute sert aux éléments superposés, menus et infobulles.
      verifierAA(c.textePrincipal, AppPalette.nuitSurfaceHaute,
          'texte sur surface haute');
      verifierAA(c.texteSecondaire, AppPalette.nuitSurfaceHaute,
          'texte secondaire sur surface haute');
    });

    test('texte posé sur un aplat de couleur', () {
      verifierAA(c.surPrimaire, c.primaire, 'surPrimaire sur primaire');
      verifierAA(c.surSecondaire, c.secondaire, 'surSecondaire sur secondaire');
      verifierAA(c.surSucces, c.succes, 'surSucces sur succes');
      verifierAA(c.surAvertissement, c.avertissement,
          'surAvertissement sur avertissement');
      verifierAA(c.surErreur, c.erreur, 'surErreur sur erreur');
      verifierAA(c.surInfo, c.info, 'surInfo sur info');
      verifierAA(c.surAlerteElevee, c.alerteElevee,
          'surAlerteElevee sur alerteElevee');
      verifierAA(
          c.surPrimaire, c.primaireFonce, 'surPrimaire sur primaireFonce');
    });

    test('teinte employée comme couleur de texte', () {
      verifierAA(c.primaire, c.surface, 'primaire en texte sur surface');
      verifierAA(c.secondaireTexte, c.surface, 'secondaireTexte sur surface');
      verifierAA(c.succes, c.surface, 'succes en texte sur surface');
      verifierAA(c.avertissement, c.surface, 'avertissement en texte');
      verifierAA(c.erreur, c.surface, 'erreur en texte sur surface');
      verifierAA(c.info, c.surface, 'info en texte sur surface');
      verifierAA(c.alerteElevee, c.surface, 'alerteElevee en texte');
    });

    test('texte principal sur un fond teinté', () {
      verifierAA(c.textePrincipal, c.primaireVoile, 'texte sur primaireVoile');
      verifierAA(
          c.textePrincipal, c.secondaireVoile, 'texte sur secondaireVoile');
      verifierAA(c.textePrincipal, c.succesVoile, 'texte sur succesVoile');
      verifierAA(c.textePrincipal, c.avertissementVoile,
          'texte sur avertissementVoile');
      verifierAA(c.textePrincipal, c.erreurVoile, 'texte sur erreurVoile');
      verifierAA(c.textePrincipal, c.infoVoile, 'texte sur infoVoile');
    });

    test('bordure des composants interactifs', () {
      verifierComposant(c.bordure, c.surface, 'bordure sur surface');
      verifierComposant(c.bordure, c.fond, 'bordure sur fond');
      verifierComposant(c.primaire, c.surface, 'bordure focus sur surface');
    });

    test('couleurs de statut lisibles en texte', () {
      verifierAA(c.validationEnAttente, c.surface, 'statut en attente');
      verifierAA(c.validationValidee, c.surface, 'statut validée');
      verifierAA(c.validationCorrigee, c.surface, 'statut corrigée');
      verifierAA(c.validationRejetee, c.surface, 'statut rejetée');
      verifierAA(c.statutPrevu, c.surface, 'statut prévu');
      verifierAA(c.statutEnCours, c.surface, 'statut en cours');
      verifierAA(c.statutRecolte, c.surface, 'statut récolte');
      verifierAA(c.statutEnTraitement, c.surface, 'statut en traitement');
      verifierAA(c.statutAbandonne, c.surface, 'statut abandonné');
    });
  });

  group('Teintes à ne pas employer en texte', () {
    test('l\'ocre en aplat ne porte pas de blanc', () {
      // L'ocre #B9772A est la couleur d'identité chaude du projet. Avec du
      // blanc dessus, elle plafonne à 3,66:1. Ce test fige le constat pour que
      // personne ne réintroduise ce couple en croyant qu'il passe : la paire
      // correcte est `surSecondaire`, qui est de l'encre sombre.
      final rapport =
          contraste(Colors.white, CouleursAgriSmart.clair.secondaire);
      expect(rapport, lessThan(4.5),
          reason: 'Si ce test échoue, l\'ocre a été assombri : '
              'surSecondaire peut alors redevenir du blanc.');
      expect(
          contraste(CouleursAgriSmart.clair.surSecondaire,
              CouleursAgriSmart.clair.secondaire),
          greaterThanOrEqualTo(4.5));
    });

    test('la teinte de famille ne porte pas sur son propre voile', () {
      // Motif écarté par le système : pastille pâle avec petit texte coloré.
      // Les rapports obtenus tournent autour de 4,1 à 4,3, sous le seuil AA.
      const c = CouleursAgriSmart.clair;
      expect(contraste(c.secondaireTexte, c.secondaireVoile), lessThan(4.5));
      expect(contraste(c.avertissement, c.avertissementVoile), lessThan(4.5));
      // Le texte principal, lui, passe largement sur ces mêmes voiles.
      expect(contraste(c.textePrincipal, c.secondaireVoile),
          greaterThanOrEqualTo(4.5));
      expect(contraste(c.textePrincipal, c.avertissementVoile),
          greaterThanOrEqualTo(4.5));
    });
  });
}

/// Seuil du critère 1.4.3 de WCAG 2.1 pour un texte courant.
const double seuilAA = 4.5;

/// Seuil des critères 1.4.3 (texte large) et 1.4.11 (composants).
const double seuilComposant = 3.0;

void verifierAA(Color premierPlan, Color arrierePlan, String libelle) {
  final rapport = contraste(premierPlan, arrierePlan);
  expect(
    rapport,
    greaterThanOrEqualTo(seuilAA),
    reason: '$libelle : ${rapport.toStringAsFixed(2)}:1, '
        'sous le seuil AA de $seuilAA:1 '
        '(${hex(premierPlan)} sur ${hex(arrierePlan)})',
  );
}

void verifierComposant(Color premierPlan, Color arrierePlan, String libelle) {
  final rapport = contraste(premierPlan, arrierePlan);
  expect(
    rapport,
    greaterThanOrEqualTo(seuilComposant),
    reason: '$libelle : ${rapport.toStringAsFixed(2)}:1, '
        'sous le seuil de $seuilComposant:1 exigé pour un composant '
        '(${hex(premierPlan)} sur ${hex(arrierePlan)})',
  );
}

/// Rapport de contraste WCAG 2.1 entre deux couleurs opaques.
double contraste(Color a, Color b) {
  final la = luminanceRelative(a);
  final lb = luminanceRelative(b);
  final haute = math.max(la, lb);
  final basse = math.min(la, lb);
  return (haute + 0.05) / (basse + 0.05);
}

/// Luminance relative, selon la définition de WCAG 2.1.
///
/// Flutter expose déjà `Color.computeLuminance()`, qui applique la même
/// formule. Le calcul est refait ici pour que le test reste une vérification
/// indépendante : si l'implémentation du framework changeait, le test le
/// signalerait au lieu de suivre silencieusement.
double luminanceRelative(Color c) {
  double canal(double valeur) => valeur <= 0.03928
      ? valeur / 12.92
      : math.pow((valeur + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

String hex(Color c) {
  String deux(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${deux(c.r)}${deux(c.g)}${deux(c.b)}';
}
