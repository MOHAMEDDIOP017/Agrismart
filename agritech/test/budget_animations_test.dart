import 'dart:io';

import 'package:agritech/core/theme/app_motion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie dans le code source que le budget d'animation est tenu.
///
/// Les tests de `theme_systeme_test.dart` contrôlent les durées déclarées dans
/// `AppDurees`. Ils ne voient rien d'une durée écrite à la main au milieu d'un
/// écran, et c'est précisément ce que l'audit avait trouvé : 1 200 ms sur la
/// barre d'aptitude, 700 ms sur le carrousel du tableau de bord, et vingt-cinq
/// valeurs différentes dispersées dans quatorze fichiers.
///
/// Ce test lit donc les fichiers eux-mêmes. C'est inhabituel, et c'est
/// assumé : la règle porte sur la façon d'écrire le code, pas sur ce qu'il
/// produit à l'exécution, et aucune assertion sur un widget ne l'attraperait.
void main() {
  final fichiers = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('il y a bien des fichiers à inspecter', () {
    // Garde-fou : si le chemin changeait, les tests suivants passeraient à
    // vide sans que personne ne s'en aperçoive.
    expect(fichiers.length, greaterThan(100));
  });

  test('aucune durée d\'animation ne dépasse le plafond', () {
    final plafond = AppDurees.plafond.inMilliseconds;
    final depassements = <String>[];

    // Seules les durées d'animation sont jugées. Beaucoup d'autres durées
    // vivent dans le code sans animer quoi que ce soit : délais d'expiration
    // du réseau, minuteurs, attente avant redirection, temps d'affichage d'un
    // bandeau. Les confondre rendrait la règle inapplicable, et une règle
    // inapplicable finit désactivée.
    final motif = RegExp(r'Duration\(\s*milliseconds:\s*(\d+)');

    const horsAnimation = [
      'Future.delayed',
      'Timer(',
      'Timer.periodic',
      '.timeout(',
      'connectTimeout',
      'receiveTimeout',
      'sendTimeout',
      'dureeVerrouillage',
      'SnackBar',
      'duree:',
    ];

    for (final fichier in fichiers) {
      final chemin = fichier.path.replaceAll(r'\', '/');
      // Les durées du système de design sont déclarées là, avec leur
      // justification, et vérifiées par `theme_systeme_test.dart`.
      if (chemin.endsWith('core/theme/app_motion.dart')) continue;

      final source = fichier.readAsStringSync();
      for (final m in motif.allMatches(source)) {
        final valeur = int.parse(m.group(1)!);
        if (valeur <= plafond) continue;

        final contexte = _contexteDe(source, m.start);
        if (horsAnimation.any(contexte.contains)) continue;

        depassements.add('$chemin : ${valeur}ms');
      }
    }

    expect(
      depassements,
      isEmpty,
      reason: 'Durées au-delà de $plafond ms : $depassements. '
          'Au-delà d\'environ 400 ms, une animation cesse d\'accompagner le '
          'geste et se met à le retarder. Passer par AppDurees.',
    );
  });

  test('plus aucune animation décorative en boucle infinie', () {
    // L'audit avait relevé une pastille de notification, un cerveau et un logo
    // qui pulsaient sans fin sur des écrans qui restent ouverts, maintenant le
    // processeur graphique actif sans rien annoncer.
    final boucles = <String>[];
    for (final fichier in fichiers) {
      final chemin = fichier.path.replaceAll(r'\', '/');
      // Seule boucle admise : l'indicateur de saisie de l'assistant, qui dit
      // que la réponse arrive. Le balayage des squelettes vient du paquet
      // shimmer et ne passe pas par `repeat`.
      if (chemin.endsWith('chat/presentation/widgets/message_bubble.dart')) {
        continue;
      }
      // Les trois points de l'écran d'ouverture disent que l'application
      // démarre, pendant les trois secondes où elle le fait. Même nature que
      // l'indicateur de saisie : une attente annoncée, pas un ornement.
      if (chemin
          .endsWith('onboarding/presentation/screens/splash_screen.dart')) {
        continue;
      }
      if (fichier.readAsStringSync().contains('.repeat(')) {
        boucles.add(chemin);
      }
    }
    expect(boucles, isEmpty, reason: 'Animations en boucle : $boucles');
  });

  test('le paquet flutter_animate a disparu du code', () {
    // Ses appels portaient leurs propres durées et délais, hors de toute
    // échelle commune, et ignoraient le réglage de réduction des animations du
    // téléphone. Les soixante-neuf appels relevés par l'audit ont été soit
    // remplacés par ApparitionCascade, soit supprimés quand ils ne servaient
    // qu'à décorer.
    final restants = fichiers
        .where((f) => f.readAsStringSync().contains('flutter_animate'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    expect(restants, isEmpty,
        reason: 'flutter_animate encore présent : $restants');
  });
}

/// La ligne portant [position] et les deux qui la précèdent.
///
/// Deux lignes de recul suffisent : l'appel qui porte la durée est presque
/// toujours juste au-dessus, `Future.delayed(` ou `AnimatedContainer(` sur la
/// ligne précédente et la durée en argument nommé en dessous.
String _contexteDe(String source, int position) {
  var debut = source.lastIndexOf('\n', position) + 1;
  for (var i = 0; i < 2 && debut > 0; i++) {
    debut = source.lastIndexOf('\n', debut - 2) + 1;
  }
  var fin = source.indexOf('\n', position);
  if (fin == -1) fin = source.length;
  return source.substring(debut, fin);
}
