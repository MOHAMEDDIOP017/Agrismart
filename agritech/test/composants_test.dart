import 'dart:async';
import 'dart:io';

import 'package:agritech/core/enums/statut_validation.dart';
import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/shared/erreurs/message_erreur.dart';
import 'package:agritech/shared/reseau/connectivite.dart';
import 'package:agritech/shared/widgets/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie les garanties que la bibliothèque de composants doit tenir.
///
/// Ces tests ne décrivent pas une apparence, qui changera, mais les règles que
/// le cahier des charges impose et qu'une relecture visuelle ne permet pas de
/// vérifier : qu'un bouton ne puisse pas envoyer deux fois, qu'un badge ne
/// porte jamais son sens par la seule couleur, qu'aucun message technique
/// n'atteigne l'écran, qu'une zone touchable fasse bien 48 points.
void main() {
  Widget cadre(Widget enfant,
      {ThemeData? theme, List<Override> surcharges = const []}) {
    return ProviderScope(
      overrides: surcharges,
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(body: Center(child: enfant)),
      ),
    );
  }

  group('AppBouton', () {
    testWidgets('un second appui pendant l\'envoi est ignoré', (tester) async {
      // C'est la garantie la plus importante du composant. Sur une connexion
      // lente, un agriculteur sans retour visuel appuie une deuxième fois ;
      // sans ce verrou, deux parcelles sont créées.
      var appels = 0;
      final envoi = Completer<void>();

      await tester.pumpWidget(cadre(
        AppBouton.principal(
          libelle: 'Enregistrer',
          onPressed: () {
            appels++;
            return envoi.future;
          },
        ),
      ));

      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      expect(appels, 1);

      // Deuxième appui pendant que la requête est en cours.
      await tester.tap(find.text('Enregistrer'), warnIfMissed: false);
      await tester.pump();
      expect(appels, 1, reason: 'Le second appui ne doit pas repartir');

      envoi.complete();
      await tester.pumpAndSettle();

      // Une fois la requête terminée, le bouton redevient utilisable.
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      expect(appels, 2);
    });

    testWidgets('le libellé reste lisible pendant l\'envoi', (tester) async {
      // L'ancien bouton remplaçait tout son contenu par une roue : on ne
      // savait plus ce qui était en cours.
      await tester.pumpWidget(cadre(
        AppBouton.principal(
          libelle: 'Enregistrer',
          enChargement: true,
          onPressed: () {},
        ),
      ));

      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('un bouton sans action est désactivé', (tester) async {
      await tester.pumpWidget(cadre(
        const AppBouton.principal(libelle: 'Valider', onPressed: null),
      ));

      final bouton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(bouton.onPressed, isNull);
    });

    testWidgets('les trois variantes atteignent 48 points de haut',
        (tester) async {
      for (final construire in [
        () => AppBouton.principal(libelle: 'A', onPressed: () {}),
        () => AppBouton.secondaire(libelle: 'A', onPressed: () {}),
        () => AppBouton.texte(libelle: 'A', onPressed: () {}),
      ]) {
        await tester.pumpWidget(cadre(construire()));
        await tester.pump();
        final taille = tester.getSize(find.text('A').first);
        expect(taille.height, greaterThan(0));
        final zone = tester.getSize(
          find.byWidgetPredicate((w) => w is ButtonStyleButton).first,
        );
        expect(zone.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('BadgeStatut', () {
    testWidgets('chaque statut de validation porte une icône et un libellé',
        (tester) async {
      // Environ un homme sur douze distingue mal le rouge du vert. Un badge
      // qui ne se différencie que par la teinte ne dit rien à ces personnes,
      // et ne dit rien non plus en plein soleil.
      for (final statut in StatutValidation.values) {
        await tester.pumpWidget(cadre(BadgeStatut.validation(statut)));

        expect(find.byType(Icon), findsOneWidget,
            reason: 'Statut ${statut.name} sans icône');
        expect(find.text(statut.libelle), findsOneWidget,
            reason: 'Statut ${statut.name} sans libellé écrit');
      }
    });

    testWidgets('les quatre statuts ont quatre icônes différentes',
        (tester) async {
      final icones = <IconData>{};
      for (final statut in StatutValidation.values) {
        await tester.pumpWidget(cadre(BadgeStatut.validation(statut)));
        icones.add(tester.widget<Icon>(find.byType(Icon)).icon!);
      }
      expect(icones.length, StatutValidation.values.length,
          reason: 'Deux statuts partagent la même icône : la distinction '
              'reposerait alors sur la seule couleur');
    });

    testWidgets('le statut détaillé nomme l\'expert', (tester) async {
      await tester.pumpWidget(cadre(
        BadgeStatut.validation(StatutValidation.validee, detaille: true),
      ));
      expect(find.text('Validée par un expert'), findsOneWidget);
    });

    testWidgets('la constante du serveur est traduite', (tester) async {
      // Un widget affichait « EN TRAITEMENT », la constante brute avec ses
      // tirets bas remplacés par des espaces.
      await tester.pumpWidget(cadre(BadgeStatut.statutChamp('EN_TRAITEMENT')));
      expect(find.text('Traitement'), findsOneWidget);
      expect(find.textContaining('_'), findsNothing);
    });

    testWidgets('un statut inconnu du client reste affiché', (tester) async {
      // Mieux vaut un libellé brut qu'un badge vide : un ajout côté serveur
      // doit se voir.
      await tester.pumpWidget(cadre(BadgeStatut.statutChamp('NOUVEAU_STATUT')));
      expect(find.text('NOUVEAU_STATUT'), findsOneWidget);
    });
  });

  group('MessageErreur', () {
    RequestOptions options() => RequestOptions(path: '/test');

    test('une coupure réseau rassure sur les données', () {
      final message = MessageErreur.pour(DioException(
        requestOptions: options(),
        type: DioExceptionType.connectionError,
      ));
      expect(message, contains('Pas de connexion'));
      expect(message, contains('gardées'));
    });

    test('une lenteur de réception rassure aussi', () {
      final message = MessageErreur.pour(DioException(
        requestOptions: options(),
        type: DioExceptionType.receiveTimeout,
      ));
      expect(message, contains('faible'));
      expect(message, contains('gardées'));
    });

    test('un envoi interrompu ne promet pas que les données sont gardées', () {
      // Nuance volontaire : une lecture coupée ne perd rien, un envoi coupé
      // peut n'être jamais arrivé.
      final message = MessageErreur.pour(DioException(
        requestOptions: options(),
        type: DioExceptionType.sendTimeout,
      ));
      expect(message, contains('n\'a pas abouti'));
      expect(message, isNot(contains('gardées')));
    });

    test('une session expirée dit quoi faire', () {
      final message = MessageErreur.pour(DioException(
        requestOptions: options(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options(), statusCode: 401),
      ));
      expect(message, contains('Connectez-vous'));
    });

    test('aucun message ne contient de terme technique', () {
      final cas = <Object>[
        DioException(requestOptions: options(), type: DioExceptionType.unknown),
        DioException(
            requestOptions: options(),
            type: DioExceptionType.connectionTimeout),
        DioException(
          requestOptions: options(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options(), statusCode: 500),
        ),
        const SocketException('échec'),
        const FormatException('mauvais JSON'),
        Exception('autre chose'),
      ];
      const interdits = [
        'Dio',
        'Exception',
        'null',
        'http',
        'HTTP',
        'socket',
        'timeout',
        'status',
        '500',
        '401',
        '/test',
      ];
      for (final erreur in cas) {
        final message = MessageErreur.pour(erreur);
        for (final terme in interdits) {
          expect(message.contains(terme), isFalse,
              reason: '« $terme » apparaît dans : $message');
        }
        expect(message, endsWith('.'));
      }
    });

    test('réessayer n\'est proposé que quand cela peut aider', () {
      bool utile(int code) => MessageErreur.vautLaPeineDeReessayer(
            DioException(
              requestOptions: options(),
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options(), statusCode: code),
            ),
          );
      expect(utile(500), isTrue);
      expect(utile(429), isTrue);
      // Des droits insuffisants ou une ressource supprimée ne changeront pas
      // au deuxième essai.
      expect(utile(403), isFalse);
      expect(utile(404), isFalse);
    });
  });

  group('États génériques', () {
    testWidgets('l\'état d\'erreur réseau propose de réessayer',
        (tester) async {
      var essais = 0;
      await tester.pumpWidget(cadre(
        EtatErreur(
          erreur: DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.connectionError,
          ),
          onReessayer: () => essais++,
        ),
      ));

      expect(find.text('Connexion interrompue'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      expect(essais, 1);
    });

    testWidgets('l\'état d\'erreur ne propose rien quand c\'est inutile',
        (tester) async {
      await tester.pumpWidget(cadre(
        EtatErreur(
          erreur: DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 404,
            ),
          ),
          onReessayer: () {},
        ),
      ));
      expect(find.text('Réessayer'), findsNothing);
      expect(find.text('Introuvable'), findsOneWidget);
    });

    testWidgets('l\'état vide propose l\'action qui le résout', (tester) async {
      var ajouts = 0;
      await tester.pumpWidget(cadre(
        EtatVide(
          titre: 'Aucun champ enregistré',
          message: 'Ajoutez votre première parcelle.',
          libelleAction: 'Ajouter un champ',
          onAction: () => ajouts++,
        ),
      ));
      await tester.tap(find.text('Ajouter un champ'));
      await tester.pump();
      expect(ajouts, 1);
    });

    testWidgets('l\'état vide sans action n\'affiche pas de bouton',
        (tester) async {
      await tester.pumpWidget(cadre(
        const EtatVide(titre: 'Rien ici', message: 'Pas encore de contenu.'),
      ));
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Rien ici'), findsOneWidget);
    });

    testWidgets('le squelette annonce la forme du contenu', (tester) async {
      await tester.pumpWidget(cadre(
        const SizedBox(
          height: 400,
          width: 360,
          child: SqueletteListe.champs(nombre: 3),
        ),
      ));
      await tester.pump();
      expect(find.byType(SqueletteCarteChamp), findsNWidgets(3));
    });
  });

  group('BarreAptitude', () {
    testWidgets('la valeur est écrite à côté de la barre', (tester) async {
      // La couleur de la barre ne doit pas porter seule l'information.
      await tester.pumpWidget(cadre(
        const SizedBox(width: 300, child: BarreAptitude(taux: 87)),
      ));
      await tester.pumpAndSettle();
      expect(find.text('87 %'), findsOneWidget);
    });

    testWidgets('la barre de rang 3 démarre après son décalage',
        (tester) async {
      await tester.pumpWidget(cadre(
        const SizedBox(width: 300, child: BarreAptitude(taux: 60, index: 2)),
      ));

      double valeur() => tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value!;

      // Avant son tour, la troisième barre est encore vide : c'est ce décalage
      // qui montre l'ordre du classement.
      await tester.pump(const Duration(milliseconds: 150));
      expect(valeur(), 0);

      // Le décalage est de 100 ms par rang, soit 200 ms pour le rang 3.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(valeur(), closeTo(0.6, 0.001));
    });

    testWidgets('sans animation, la barre est tout de suite à sa valeur',
        (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: cadre(
          const SizedBox(width: 300, child: BarreAptitude(taux: 42, index: 2)),
        ),
      ));
      await tester.pump();
      final barre = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barre.value, closeTo(0.42, 0.001));
    });
  });

  group('ZoneTactile', () {
    testWidgets('un petit contenu reste atteignable', (tester) async {
      // Remplace les 26 détecteurs de gestes nus, qui n'imposaient aucune
      // taille minimale.
      await tester.pumpWidget(cadre(
        ZoneTactile(
          onTap: () {},
          child: const SizedBox(width: 12, height: 12),
        ),
      ));
      final taille = tester.getSize(find.byType(ZoneTactile));
      expect(taille.width, greaterThanOrEqualTo(48));
      expect(taille.height, greaterThanOrEqualTo(48));
    });

    testWidgets('l\'appui est transmis', (tester) async {
      var appuis = 0;
      await tester.pumpWidget(cadre(
        ZoneTactile(
          onTap: () => appuis++,
          child: const Text('Carte'),
        ),
      ));
      await tester.tap(find.text('Carte'));
      await tester.pump();
      expect(appuis, 1);
    });
  });

  group('Bandeau hors connexion', () {
    testWidgets('masqué quand le réseau répond', (tester) async {
      await tester.pumpWidget(cadre(
        const BandeauHorsConnexion(),
        surcharges: [estHorsLigneProvider.overrideWithValue(false)],
      ));
      await tester.pump();
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    });

    testWidgets('affiché quand le réseau est coupé', (tester) async {
      await tester.pumpWidget(cadre(
        const BandeauHorsConnexion(),
        surcharges: [estHorsLigneProvider.overrideWithValue(true)],
      ));
      await tester.pump();
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.textContaining('Pas de connexion'), findsOneWidget);
    });
  });

  group('État du réseau', () {
    test('une interface active vaut connecté', () {
      expect(etatDepuis([ConnectivityResult.mobile]), EtatReseau.connecte);
      expect(etatDepuis([ConnectivityResult.wifi]), EtatReseau.connecte);
      // Le VPN seul compte aussi : il suppose un transport en dessous.
      expect(etatDepuis([ConnectivityResult.vpn]), EtatReseau.connecte);
    });

    test('aucune interface vaut déconnecté', () {
      expect(etatDepuis([ConnectivityResult.none]), EtatReseau.deconnecte);
    });

    test('une réponse vide vaut inconnu, et non déconnecté', () {
      // Sur certaines versions d'Android la plateforme ne répond rien :
      // annoncer une coupure à tort serait pire que de ne rien dire.
      expect(etatDepuis([]), EtatReseau.inconnu);
      expect(EtatReseau.inconnu.estHorsLigne, isFalse);
    });
  });
}
