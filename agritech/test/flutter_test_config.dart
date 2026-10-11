import 'dart:async';
import 'dart:io';

import 'package:agritech/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Configuration appliquée à tous les fichiers de test du dossier `test/`.
///
/// Flutter appelle automatiquement cette fonction avant le `main()` de chaque
/// fichier de test voisin.
///
/// Le binding est initialisé ici parce que la construction du thème est lue au
/// moment où les groupes de tests sont collectés, donc avant le premier
/// `testWidgets`.
///
/// Nunito est ensuite chargée depuis les assets. Sans cela, les tests
/// mesureraient du texte rendu avec la fonte de substitution de
/// `flutter_test`, dont les métriques n'ont rien à voir avec les vraies. Ce
/// chargement vérifie aussi, à chaque exécution de la suite, que le fichier
/// est bien déclaré dans `pubspec.yaml` : une erreur de chemin casserait les
/// tests au lieu de passer inaperçue jusqu'à l'installation sur un téléphone.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Les quatre graisses sont chargees dans l'ordre de leur declaration dans
  // `pubspec.yaml`. `FontLoader` associe la n-ieme fonte ajoutee a la n-ieme
  // graisse de la famille : inverser deux lignes ici ferait rendre le gras en
  // maigre dans les tests, sans rien changer a l'application.
  final chargeur = FontLoader(AppTypography.famille)
    ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'));
  await chargeur.load();

  await _chargerIconesMaterial();

  // Même initialisation que `main()` : sans elle, tout écran affichant une
  // date lève `LocaleDataException`, et le test échoue sur une cause sans
  // rapport avec ce qu'il vérifie.
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  await testMain();
}

/// Charge la fonte d'icônes de Material dans l'environnement de test.
///
/// Sans elle, chaque `Icon` se dessine en rectangle vide dans les images
/// produites par `apercu_composants_test.dart`. Or la règle « chaque icône est
/// accompagnée d'un libellé » se vérifie précisément en regardant ces images :
/// des rectangles à la place des icônes rendraient le contrôle impossible.
///
/// Le fichier est pris dans le SDK, dont `flutter test` donne le chemin par la
/// variable d'environnement `FLUTTER_ROOT`. Si la fonte est introuvable, les
/// tests continuent : seules les images perdent leurs icônes.
Future<void> _chargerIconesMaterial() async {
  final racine = Platform.environment['FLUTTER_ROOT'];
  if (racine == null) return;

  final fichier = File(
    '$racine/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!fichier.existsSync()) return;

  final octets = await fichier.readAsBytes();
  final chargeur = FontLoader('MaterialIcons')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(octets)));
  await chargeur.load();
}
