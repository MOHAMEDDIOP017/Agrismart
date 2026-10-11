import 'package:flutter_test/flutter_test.dart';
import 'package:agritech/features/champs/data/models/champ_model.dart';

/// Tests de compatibilité ascendante de `ChampModel`.
///
/// Deux changements de schéma doivent rester sans effet sur les documents
/// déjà en base :
///   1. le retrait des variables agronomiques (pH, N, P, K, humidité), qui
///      sont désormais collectées côté serveur et vivent dans AnalyseParcelle ;
///   2. l'ajout de `adresse`, jusqu'ici absente de l'entité alors que le
///      serveur l'exige — les champs créés avant portent la valeur « Sénégal »
///      écrite en dur par le client.
void main() {
  // Document tel qu'il existe réellement dans Firestore aujourd'hui.
  Map<String, dynamic> documentExistant() => {
        'id': 'champ1',
        'nom': 'Parcelle Nord',
        'superficie': 2.5,
        'typeSol': 'Sableux',
        'adresse': 'Sénégal',
        'latitude': 14.1520,
        'longitude': -16.0726,
        'commentaire': 'Mil',
        'zoneAgroecologiqueId': 'zone_ba',
        'agriculteurId': 'agri1',
        'dateCreation': '2026-05-18T11:08:00.000Z',
      };

  group('Lecture des documents existants', () {
    test('un champ existant reste lisible', () {
      final champ = ChampModel.fromJson(documentExistant());

      expect(champ.id, 'champ1');
      expect(champ.nom, 'Parcelle Nord');
      expect(champ.superficie, 2.5);
      expect(champ.adresse, 'Sénégal');
      expect(champ.latitude, closeTo(14.1520, 1e-6));
    });

    test('les variables agronomiques résiduelles sont ignorées', () {
      // Un document plus ancien porte encore ces clés : elles ne doivent pas
      // faire échouer la lecture, simplement ne pas être reprises.
      final ancien = {
        ...documentExistant(),
        'ph': 6.4,
        'azote': 0.8,
        'phosphore': 7.2,
        'potassium': 71.3,
        'humidite': 52.0,
      };

      final champ = ChampModel.fromJson(ancien);

      expect(champ.nom, 'Parcelle Nord');
      expect(champ.toJson().keys, isNot(contains('ph')));
      expect(champ.toJson().keys, isNot(contains('azote')));
      expect(champ.toJson().keys, isNot(contains('humidite')));
    });

    test('un document sans adresse reste lisible', () {
      // Repli volontaire sur une chaîne vide : mieux vaut un champ affichable
      // et corrigeable qu'une liste entière qui échoue.
      final sansAdresse = {...documentExistant()}..remove('adresse');

      expect(ChampModel.fromJson(sansAdresse).adresse, '');
    });
  });

  group('Modification des champs existants', () {
    test('un champ existant reste modifiable via copyWith', () {
      final champ = ChampModel.fromJson(documentExistant());
      final modifie = champ.copyWith(adresse: 'Ngoundiane, Thiès');

      expect(modifie.adresse, 'Ngoundiane, Thiès');
      expect(modifie.id, champ.id);
      expect(modifie.nom, champ.nom);
      expect(modifie.dateCreation, champ.dateCreation);
    });

    test('l\'adresse saisie remplace « Sénégal » dans la charge envoyée', () {
      final champ = ChampModel.fromJson(documentExistant())
          .copyWith(adresse: 'Ngoundiane, Thiès');

      final charge = champ.toCreateJson();

      expect(charge['adresse'], 'Ngoundiane, Thiès');
      expect(charge['adresse'], isNot('Sénégal'));
    });
  });

  group('Contrat avec le serveur', () {
    test('la charge envoyée ne contient que ce que ChampBase déclare', () {
      final charge = ChampModel.fromJson(documentExistant()).toCreateJson();

      // Champs attendus par ChampBase côté backend.
      expect(
        charge.keys.toSet(),
        {'nom', 'superficie', 'typeSol', 'latitude', 'longitude', 'adresse'},
      );
    });

    test('culture n\'est plus détournée vers commentaire', () {
      // Le détournement écrivait la culture dans `commentaire`, un champ que
      // le client relit sous le nom `culture` — donc toujours nul à l'écran.
      final champ = ChampModel.fromJson({
        ...documentExistant(),
        'culture': 'Arachide',
      });

      expect(champ.culture, 'Arachide');
      expect(champ.toCreateJson().containsKey('commentaire'), isFalse);
    });
  });
}
