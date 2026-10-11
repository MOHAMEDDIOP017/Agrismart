import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que la graisse demandée est bien celle qui est rendue.
///
/// Ce test existe à cause d'une mesure faite pendant la mise en place du
/// système. La première version embarquait Nunito en fonte variable, un seul
/// fichier couvrant l'axe de graisse de 200 à 1 000. Dans cette configuration,
/// `fontWeight` ne produisait aucun effet : seul `fontVariations` pilote l'axe,
/// `fontWeight` servant uniquement à choisir parmi les fichiers déclarés. Avec
/// un unique fichier déclaré, deux graisses opposées rendaient exactement la
/// même largeur, 202,13 px, correspondant au tracé par défaut de l'axe, très
/// fin. Un `copyWith(fontWeight:)` sur un style du thème ne produisait rien
/// non plus.
///
/// Le code compte 258 usages de `fontWeight` et sept `copyWith(fontWeight:)`.
/// Un réglage sans effet y serait resté invisible : rien ne plante, le texte
/// s'affiche, simplement plus fin que voulu. C'est le pire cas pour une
/// application qui doit rester lisible en plein soleil.
///
/// Quatre fontes statiques, déclarées une par graisse, rétablissent le
/// comportement attendu. Ce test mesure la largeur rendue pour l'établir, et
/// échouerait si quelqu'un revenait à un fichier variable.
void main() {
  // Chaîne de référence : un libellé réel de l'application, assez long pour
  // que l'écart de graisse se cumule sur plusieurs caractères.
  const phrase = 'Obtenir une recommandation';

  double largeurRendue(TextStyle style) {
    final peintre = TextPainter(
      text: TextSpan(text: phrase, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return peintre.width;
  }

  test('les quatre graisses embarquées rendent des largeurs croissantes', () {
    final largeurs = AppTypography.graissesEmbarquees
        .map((g) =>
            largeurRendue(AppTypography.police(fontSize: 16, fontWeight: g)))
        .toList();

    for (var i = 1; i < largeurs.length; i++) {
      expect(
        largeurs[i],
        greaterThan(largeurs[i - 1]),
        reason: 'La graisse ${AppTypography.graissesEmbarquees[i].value} rend '
            '${largeurs[i].toStringAsFixed(2)} px, soit pas plus que '
            '${AppTypography.graissesEmbarquees[i - 1].value} à '
            '${largeurs[i - 1].toStringAsFixed(2)} px. La graisse demandée '
            'n\'est pas appliquée : vérifier que les quatre fontes statiques '
            'sont bien déclarées dans pubspec.yaml.',
      );
    }
  });

  test('fontWeight seul suffit, sans fontVariations', () {
    // C'est la propriété que les fontes statiques apportent et que la fonte
    // variable n'avait pas. Tout le code existant écrit ses styles ainsi.
    const maigre = TextStyle(
      fontFamily: AppTypography.famille,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );
    const gras = TextStyle(
      fontFamily: AppTypography.famille,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );
    expect(largeurRendue(gras), greaterThan(largeurRendue(maigre)));
  });

  test('copyWith(fontWeight:) sur un style du thème est appliqué', () {
    // Sept endroits du code s'en servent, et le lot 2 en ajoutera.
    final base = AppTheme.lightTheme.textTheme.bodyMedium!;
    final renforce = base.copyWith(fontWeight: FontWeight.w800);
    expect(largeurRendue(renforce), greaterThan(largeurRendue(base)));
  });

  group('Couverture des caractères après réduction', () {
    // Les fontes sont réduites aux caractères utiles pour tenir dans 203 Ko au
    // lieu de 517. Une réduction trop large retirerait silencieusement une
    // lettre : le texte continuerait de s'afficher, avec un rectangle vide à
    // la place du caractère.
    //
    // Un glyphe absent se détecte à sa largeur. Le moteur rend alors le glyphe
    // `.notdef`, dont l'avance est constante quelle que soit la lettre
    // demandée. Comparer la largeur d'un caractère à celle d'un caractère dont
    // on sait qu'il est absent suffit donc à conclure.
    //
    // Comparer une lettre accentuée à sa lettre de base ne marcherait pas :
    // dans Nunito, « ñ » et « n » ont exactement la même avance, le tilde
    // étant dessiné au-dessus sans élargir le caractère.
    const style = TextStyle(
      fontFamily: AppTypography.famille,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );

    double largeurDe(String texte) {
      final peintre = TextPainter(
        text: TextSpan(text: texte, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return peintre.width;
    }

    /// Avance du glyphe `.notdef`, mesurée sur un idéogramme que la réduction
    /// a forcément retiré.
    final largeurAbsente = largeurDe('漢');

    void verifierPresence(String caractere, String description) {
      expect(
        largeurDe(caractere),
        isNot(closeTo(largeurAbsente, 0.001)),
        reason: '« $caractere » ($description) rend la largeur du glyphe '
            'manquant : le caractère a disparu de la fonte réduite. Revoir '
            'les plages conservées dans tool/fontes_nunito.py.',
      );
    }

    test('la réduction a bien retiré les écritures inutilisées', () {
      // Contrôle du contrôle : si ces caractères étaient présents, la mesure
      // de référence ne vaudrait rien et les tests suivants passeraient à vide.
      for (final absent in ['漢', 'Ж', 'א']) {
        expect(largeurDe(absent), closeTo(largeurAbsente, 0.001));
      }
    });

    test('les lettres accentuées du français sont présentes', () {
      for (final c in 'àâäéèêëîïôöùûüÿçœÀÂÉÈÊËÎÏÔÖÙÛÜÇŒ'.split('')) {
        verifierPresence(c, 'français');
      }
    });

    test('les lettres propres au wolof sont présentes', () {
      // Alphabet officiel du wolof, décret sénégalais de 1971. Les noms de
      // cultures affichés sous le nom français en ont besoin : ñebbe pour le
      // niébé, ñambi pour le manioc, mbóq pour le maïs.
      for (final c in ['ñ', 'Ñ', 'ŋ', 'Ŋ', 'ó', 'Ó', 'é', 'à', 'ë']) {
        verifierPresence(c, 'wolof');
      }
      expect(largeurDe('ñebbe'), greaterThan(0));
      expect(largeurDe('mbóq'), greaterThan(0));
    });

    test('la ponctuation française et les symboles sont présents', () {
      for (final c in ['«', '»', '’', '…', '·', '°', '%']) {
        verifierPresence(c, 'ponctuation');
      }
    });

    test('la limite de la mesure par largeur est connue', () {
      // Trois caractères échappent à cette méthode, et il faut le dire plutôt
      // que de les retirer en silence.
      //
      // Le tiret demi-cadratin « – » a une avance d'exactement un demi-cadratin,
      // soit 8 px à 16 px de corps, qui est aussi l'avance du glyphe `.notdef`.
      // Le cadratin « — » et l'euro « € » ont de même des métriques fixes,
      // identiques d'une graisse à l'autre. Aucune mesure de largeur ne peut
      // donc trancher entre « présent » et « manquant » pour ces trois-là.
      //
      // Leur présence est vérifiée à la source, par lecture de la table cmap,
      // dans tool/fontes_nunito.py. Ce test se contente de figer le constat,
      // pour qu'une future tentative de les ajouter ci-dessus tombe sur
      // l'explication au lieu d'un échec incompréhensible.
      expect(largeurDe('–'), closeTo(largeurAbsente, 0.001));
      expect(largeurDe('—'), closeTo(largeurAbsente * 2, 0.001));
      expect(largeurDe('€'), closeTo(9.6, 0.001));
    });
  });
}
