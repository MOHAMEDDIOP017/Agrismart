import 'package:agritech/core/theme/app_theme.dart';
import 'package:agritech/features/auth/domain/entities/user_entity.dart';
import 'package:agritech/navigation/app_router.dart';
import 'package:agritech/navigation/destinations_notifications.dart';
import 'package:agritech/navigation/expert_router.dart';
import 'package:agritech/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Vérifie les règles de navigation que le cahier des charges impose.
void main() {
  Widget cadre(Widget enfant) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: enfant),
      );

  group('Destination des notifications', () {
    // Charge utile telle que `notification_service.py` la construit.
    Map<String, String> charge(String type,
            {String reference = '', String notif = 'n-1'}) =>
        {
          'type': type,
          'referenceId': reference,
          'urgent': 'false',
          'notifId': notif,
        };

    test('l\'agriculteur arrive sur ses recommandations', () {
      expect(
        routeNotification(
            charge('RECOMMANDATION'), RoleUtilisateur.agriculteur),
        AppRoutes.recommandations,
      );
    });

    test('un conseil mène à l\'alerte correspondante', () {
      // L'identifiant utilisé est celui de la notification, et non la
      // référence : la liste d'alertes de l'agriculteur est construite à
      // partir des notifications elles-mêmes.
      expect(
        routeNotification(
          charge('CONSEIL_EXPERT', reference: 'conseil-77', notif: 'notif-42'),
          RoleUtilisateur.agriculteur,
        ),
        '/home/alertes/notif-42',
      );
    });

    test('sans identifiant, on arrive sur la liste et non nulle part', () {
      expect(
        routeNotification(
          charge('INTERVENTION_PLANIFIEE', notif: ''),
          RoleUtilisateur.agriculteur,
        ),
        AppRoutes.alertes,
      );
    });

    test('l\'expert arrive sur la recommandation à valider', () {
      expect(
        routeNotification(
          charge('RECOMMANDATION', reference: 'reco-9'),
          RoleUtilisateur.expert,
        ),
        '${ExpertRoutes.expertRecommandations}/reco-9',
      );
    });

    test('l\'expert sans référence arrive sur sa file', () {
      expect(
        routeNotification(charge('RECOMMANDATION'), RoleUtilisateur.expert),
        ExpertRoutes.expertRecommandations,
      );
    });

    test('un type inconnu ne laisse jamais sans destination', () {
      // Le serveur peut ajouter un type sans que le client soit mis à jour.
      for (final role in RoleUtilisateur.values) {
        expect(routeNotification(charge('TYPE_FUTUR'), role), isNotNull,
            reason: 'Rôle ${role.name} sans destination de repli');
      }
    });

    test('sans session, aucune destination n\'est choisie', () {
      // Le rôle décide de l'écran : sans lui, mieux vaut ne pas naviguer que
      // d'envoyer vers une section qui sera refusée par la garde de rôle.
      expect(routeNotification(charge('RECOMMANDATION'), null), isNull);
    });

    test('chaque rôle reste dans sa propre section', () {
      // Garde-fou : une erreur de correspondance enverrait un agriculteur sur
      // un écran d'expert, que la garde de rôle du routeur renverrait aussitôt
      // vers « accès refusé ». La notification paraîtrait alors cassée.
      const prefixes = {
        RoleUtilisateur.agriculteur: '/home',
        RoleUtilisateur.expert: '/expert',
        RoleUtilisateur.admin: '/admin',
      };
      const types = [
        'RECOMMANDATION',
        'CONSEIL_EXPERT',
        'INTERVENTION_PLANIFIEE',
        'ALERTE',
        'TYPE_FUTUR',
      ];

      for (final role in RoleUtilisateur.values) {
        for (final type in types) {
          final route =
              routeNotification(charge(type, reference: 'r-1'), role)!;
          expect(route, startsWith(prefixes[role]!),
              reason: '$type pour ${role.name} sort de sa section : $route');
        }
      }
    });
  });

  group('Routes par rôle', () {
    test('l\'expert démarre sur sa file de validation', () {
      // Elle était déclarée hors de la coquille de navigation, donc sans
      // onglet, alors que c'est la tâche première du rôle.
      const expert = UserEntity(
        id: 'e1',
        nom: 'Fall',
        prenom: 'Awa',
        email: 'a@b.sn',
        telephone: '770000000',
        role: RoleUtilisateur.expert,
      );
      expect(expert.routeHome, ExpertRoutes.expertRecommandations);
    });

    test('l\'assistant est un onglet et non une sous-page', () {
      // Il vivait à `/home/dashboard/assistant`, à deux niveaux de profondeur.
      expect(AppRoutes.assistant, '/home/assistant');
      expect(AppRoutes.assistant.split('/').length, 3);
    });
  });

  group('Barre de navigation', () {
    const destinations = [
      DestinationNavigation(
        libelle: 'Accueil',
        icone: Icons.home_outlined,
        iconeActive: Icons.home_rounded,
      ),
      DestinationNavigation(
        libelle: 'Champs',
        icone: Icons.terrain_outlined,
        iconeActive: Icons.terrain_rounded,
      ),
      DestinationNavigation(
        libelle: 'Assistant',
        icone: Icons.forum_outlined,
        iconeActive: Icons.forum_rounded,
      ),
      DestinationNavigation(
        libelle: 'Profil',
        icone: Icons.person_outline,
        iconeActive: Icons.person_rounded,
      ),
    ];

    testWidgets('tous les libellés restent écrits, actifs ou non',
        (tester) async {
      // Material masque volontiers les libellés inactifs. Pour une personne
      // peu à l'aise avec le numérique, cela revient à devoir deviner trois
      // icônes sur quatre.
      await tester.pumpWidget(cadre(
        BarreNavigation(
          destinations: destinations,
          indexActif: 1,
          onChange: (_) {},
        ),
      ));

      for (final d in destinations) {
        expect(find.text(d.libelle), findsOneWidget);
      }
    });

    testWidgets('l\'onglet actif se distingue par plusieurs signaux',
        (tester) async {
      await tester.pumpWidget(cadre(
        BarreNavigation(
          destinations: destinations,
          indexActif: 2,
          onChange: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Icône pleine pour l'actif, contour pour les autres : la distinction ne
      // repose pas sur la seule teinte.
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsNothing);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsNothing);

      // Graisse du libellé plus appuyée sur l'actif.
      final actif = tester.widget<Text>(find.text('Assistant'));
      final inactif = tester.widget<Text>(find.text('Accueil'));
      expect(actif.style!.fontWeight!.value,
          greaterThan(inactif.style!.fontWeight!.value));
      expect(actif.style!.color, isNot(inactif.style!.color));
    });

    testWidgets('l\'onglet actif est annoncé comme sélectionné',
        (tester) async {
      await tester.pumpWidget(cadre(
        BarreNavigation(
          destinations: destinations,
          indexActif: 0,
          onChange: (_) {},
        ),
      ));

      final semantique = tester.getSemantics(find.text('Accueil'));
      expect(semantique.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('la pastille de compteur apparaît et se borne', (tester) async {
      await tester.pumpWidget(cadre(
        BarreNavigation(
          destinations: const [
            DestinationNavigation(
              libelle: 'À valider',
              icone: Icons.fact_check_outlined,
              iconeActive: Icons.fact_check_rounded,
              compteur: 7,
            ),
            DestinationNavigation(
              libelle: 'Profil',
              icone: Icons.person_outline,
              iconeActive: Icons.person_rounded,
            ),
          ],
          indexActif: 0,
          onChange: (_) {},
        ),
      ));
      expect(find.text('7'), findsOneWidget);

      await tester.pumpWidget(cadre(
        BarreNavigation(
          destinations: const [
            DestinationNavigation(
              libelle: 'À valider',
              icone: Icons.fact_check_outlined,
              iconeActive: Icons.fact_check_rounded,
              compteur: 350,
            ),
          ],
          indexActif: 0,
          onChange: (_) {},
        ),
      ));
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('un appui demande le changement d\'onglet', (tester) async {
      var demande = -1;
      await tester.pumpWidget(cadre(
        BarreNavigation(
          destinations: destinations,
          indexActif: 0,
          onChange: (i) => demande = i,
        ),
      ));
      await tester.tap(find.text('Profil'));
      await tester.pump();
      expect(demande, 3);
    });

    testWidgets('les quatre onglets tiennent à 360 dp et à 130 %',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: cadre(
          Align(
            alignment: Alignment.bottomCenter,
            child: BarreNavigation(
              destinations: destinations,
              indexActif: 0,
              onChange: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // `tester.takeException` renverrait l'exception de débordement si la
      // barre dépassait la largeur disponible.
      expect(tester.takeException(), isNull);
      for (final d in destinations) {
        expect(find.text(d.libelle), findsOneWidget);
      }
    });
  });

  group('Barre de titre', () {
    testWidgets('une page empilée montre la flèche de retour', (tester) async {
      final routeur = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => c.push('/detail'),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/detail',
            builder: (c, s) => const Scaffold(
              appBar: BarreTitre(titre: 'Détail', routeRepli: '/'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: routeur,
      ));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsNothing);
    });

    testWidgets('une page atteinte directement montre le retour à l\'accueil',
        (tester) async {
      // Cas de l'écran « accès refusé » : on y arrive par une redirection, il
      // n'y a donc rien à dépiler, et sans ce bouton la personne reste
      // bloquée.
      final routeur = GoRouter(
        initialLocation: '/refus',
        routes: [
          GoRoute(
            path: '/accueil',
            builder: (c, s) => const Scaffold(body: Text('accueil')),
          ),
          GoRoute(
            path: '/refus',
            builder: (c, s) => const Scaffold(
              appBar: BarreTitre(titre: 'Accès refusé', routeRepli: '/accueil'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: routeur,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();
      expect(find.text('accueil'), findsOneWidget);
    });
  });
}
