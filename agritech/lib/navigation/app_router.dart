import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Agriculteur ──────────────────────────────────────────────────────────────
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/champs/presentation/screens/champs_list_screen.dart';
import '../features/champs/presentation/screens/champ_detail_screen.dart';
import '../features/champs/presentation/screens/champ_form_screen.dart';
import '../features/recommandations/presentation/screens/recommandations_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/alertes/presentation/screens/alertes_screen.dart';
import '../features/alertes/presentation/screens/alerte_detail_screen.dart';
import '../features/suivi/presentation/screens/suivi_screen.dart';
import '../features/profil/presentation/screens/profil_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/shared/presentation/screens/non_autorise_screen.dart';

// ── Expert ───────────────────────────────────────────────────────────────────
import '../features/expert/presentation/screens/expert_dashboard_screen.dart';
import '../features/expert/presentation/screens/supervision_champs_screen.dart';
import '../features/expert/presentation/screens/champ_dashboard_expert_screen.dart';
import '../features/expert/presentation/screens/historique_champ_screen.dart';
import '../features/expert/presentation/screens/planifier_intervention_screen.dart';
import '../features/expert/presentation/screens/conseils_screen.dart';
import '../features/expert/presentation/screens/nouveau_conseil_screen.dart';
import '../features/expert/presentation/screens/rapport_screen.dart';
import '../features/expert/presentation/screens/profil_expert_screen.dart';
import '../features/expert/presentation/screens/recommandations_expert_screen.dart';
import '../features/expert/presentation/screens/recommandation_detail_expert_screen.dart';

// ── Admin ────────────────────────────────────────────────────────────────────
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/gestion_utilisateurs_screen.dart';
import '../features/admin/presentation/screens/assignation_experts_screen.dart';
import '../features/admin/presentation/screens/statistiques_screen.dart';
import '../features/admin/presentation/screens/historique_systeme_screen.dart';
import '../features/admin/presentation/screens/profil_admin_screen.dart';
import '../features/admin/presentation/screens/creer_user_screen.dart';
import '../features/admin/presentation/screens/modifier_user_screen.dart';
import '../features/admin/presentation/screens/nouvelle_assignation_screen.dart';
import '../features/admin/presentation/screens/gestion_champs_admin_screen.dart';
import '../features/admin/presentation/screens/creer_champ_admin_screen.dart';

// ── Navigation scaffolds ─────────────────────────────────────────────────────
import 'bottom_nav_bar.dart';
import 'expert_scaffold.dart';
import 'expert_router.dart';
import 'admin_scaffold.dart';
import 'admin_router.dart';
import 'transitions.dart';

/// Routes nommées de l'application
class AppRoutes {
  // Auth & onboarding
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const nonAutorise = '/non-autorise';
  static const home = '/home';

  // Shell Agriculteur (onglets avec BottomNavBar)
  static const dashboard = '/home/dashboard';
  static const champs = '/home/champs';
  static const champDetail = '/home/champs/:id';
  static const champForm = '/home/champs/form';
  static const recommandations = '/home/dashboard/recommandations';

  /// L'assistant a son propre onglet. Il vivait sous l'accueil, à deux
  /// niveaux de profondeur, et n'était atteignable que par une carte placée
  /// en bas du tableau de bord.
  static const assistant = '/home/assistant';

  /// Les alertes ne sont plus un onglet : elles s'ouvrent en plein écran
  /// depuis la cloche de l'accueil, et le bouton retour y ramène.
  static const alertes = '/home/alertes';
  static const alerteDetail = '/home/alertes/:id';

  /// Sous-page de l'accueil, et non une racine : la constante annonçait
  /// `/home/suivi` alors que la route déclarée est `/home/dashboard/suivi`.
  /// Personne ne s'en servait, le tableau de bord écrivant le chemin à la
  /// main ; la constante aurait mené à une page introuvable au premier usage.
  static const suivi = '/home/dashboard/suivi';
  static const profil = '/home/profil';

  // Notifications
  static const notifications = '/notifications';
}

// ── Notifier pour rafraîchir le router quand l'auth change ──────────────────

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

// ── Helpers de classification des routes ────────────────────────────────────

bool _estRouteAgriculteur(String path) => path.startsWith('/home');

bool _estRouteExpert(String path) => path.startsWith('/expert');

bool _estRouteAdmin(String path) => path.startsWith('/admin');

// ── Routes publiques (accessibles sans authentification) ────────────────────

bool _estRoutePublique(String path) =>
    path == AppRoutes.splash ||
    path == AppRoutes.onboarding ||
    path == AppRoutes.login ||
    path == AppRoutes.register ||
    path == AppRoutes.nonAutorise;

// ── Provider principal du router ─────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: listenable,

    // ── Garde d'accès par rôle ───────────────────────────────────────────
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);

      // Auth encore en chargement → pas de redirection
      if (authAsync.isLoading) return null;

      final authState = authAsync.valueOrNull;
      final isAuthenticated = authState?.isAuthenticated ?? false;
      final user = authState?.user;
      final loc = state.matchedLocation;

      // Non connecté → login (sauf routes publiques)
      if (!isAuthenticated && !_estRoutePublique(loc)) {
        return AppRoutes.login;
      }

      // Déjà connecté sur login/register → accueil selon rôle
      if (isAuthenticated &&
          (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return user?.routeHome ?? AppRoutes.dashboard;
      }

      // Route racine /home → accueil selon rôle
      if (isAuthenticated && loc == AppRoutes.home) {
        return user?.routeHome ?? AppRoutes.dashboard;
      }

      // Garde d'accès : vérification du rôle sur les routes protégées
      if (isAuthenticated && user != null) {
        if (_estRouteAgriculteur(loc) &&
            user.role != RoleUtilisateur.agriculteur) {
          return AppRoutes.nonAutorise;
        }
        if (_estRouteExpert(loc) && user.role != RoleUtilisateur.expert) {
          return AppRoutes.nonAutorise;
        }
        if (_estRouteAdmin(loc) && user.role != RoleUtilisateur.admin) {
          return AppRoutes.nonAutorise;
        }
      }

      return null; // Pas de redirection
    },

    routes: [
      // ── Splash ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (c, s) => pageFondu(s, const SplashScreen()),
      ),

      // ── Onboarding ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (c, s) => pageFondu(s, const OnboardingScreen()),
      ),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (c, s) => pageFondu(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (c, s) => pageFondu(s, const RegisterScreen()),
      ),

      // ── Accès non autorisé ────────────────────────────────
      GoRoute(
        path: AppRoutes.nonAutorise,
        name: 'non-autorise',
        pageBuilder: (c, s) => pageFondu(s, const NonAutoriseScreen()),
      ),

      // ════════════════════════════════════════════════════════════
      // SHELL AGRICULTEUR — Accueil, Champs, Assistant, Profil
      // ════════════════════════════════════════════════════════════
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, onglets) =>
            ConteneurOnglets(
          navigationShell: navigationShell,
          onglets: onglets,
        ),
        branches: [
          // Onglet 0 — Accueil / Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (c, s) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'suivi',
                  name: 'suivi',
                  builder: (c, s) => const SuiviScreen(),
                ),
                GoRoute(
                  path: 'recommandations',
                  name: 'recommandations',
                  // ?champId=... : la parcelle est déjà choisie, parce que
                  // l'écran de détail d'un champ emmène ici avec elle. Sans
                  // ce paramètre, il fallait la resélectionner alors qu'on
                  // venait justement de la consulter.
                  builder: (c, s) => RecommandationsScreen(
                    champId: s.uri.queryParameters['champId'],
                  ),
                ),
              ],
            ),
          ]),

          // Onglet 1 — Champs
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.champs,
              name: 'champs',
              builder: (c, s) => const ChampsListScreen(),
              routes: [
                GoRoute(
                  path: 'form',
                  name: 'champ-form',
                  builder: (c, s) {
                    final champId = s.uri.queryParameters['id'];
                    return ChampFormScreen(champId: champId);
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: 'champ-detail',
                  builder: (c, s) {
                    final id = s.pathParameters['id']!;
                    return ChampDetailScreen(champId: id);
                  },
                ),
              ],
            ),
          ]),

          // Onglet 2 — Assistant conversationnel
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.assistant,
              name: 'assistant',
              // ?champId=... : ouvre l'assistant sur une parcelle précise,
              // l'agent recommande alors à l'échelle de cette parcelle.
              builder: (c, s) => ChatScreen(
                champId: s.uri.queryParameters['champId'],
              ),
            ),
          ]),

          // Onglet 3 — Profil Agriculteur
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profil,
              name: 'profil',
              builder: (c, s) => const ProfilScreen(),
            ),
          ]),
        ],
      ),

      // ── Alertes de l'agriculteur, en plein écran ─────────────────
      //
      // Ouvertes depuis la cloche de l'accueil plutôt que depuis un onglet :
      // la liste des alertes et celle des notifications interrogeaient le même
      // point d'entrée du serveur, et occupaient deux entrées de navigation
      // pour les mêmes données.
      GoRoute(
        path: AppRoutes.alertes,
        name: 'alertes',
        pageBuilder: (c, s) => pageGlissement(s, const AlertesScreen()),
        routes: [
          GoRoute(
            path: ':id',
            name: 'alerte-detail',
            pageBuilder: (c, s) {
              final id = s.pathParameters['id']!;
              return pageGlissement(s, AlerteDetailScreen(alerteId: id));
            },
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════════
      // SHELL EXPERT — À valider, Champs, Conseils, Profil
      // ════════════════════════════════════════════════════════════
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            ExpertScaffold(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, onglets) =>
            ConteneurOnglets(
          navigationShell: navigationShell,
          onglets: onglets,
        ),
        branches: [
          // Onglet 0 — File de validation.
          //
          // Elle était déclarée hors de la coquille : elle n'appartenait à
          // aucun onglet, et l'ouvrir faisait disparaître la barre de
          // navigation. C'est pourtant la tâche première de l'expert.
          StatefulShellBranch(routes: [
            GoRoute(
              path: ExpertRoutes.expertRecommandations,
              name: ExpertRoutes.recommandationsNom,
              builder: (c, s) => const RecommandationsExpertScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: ExpertRoutes.recommandationDetailNom,
                  builder: (c, s) {
                    final id = s.pathParameters['id']!;
                    return RecommandationDetailExpertScreen(recoId: id);
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: ExpertRoutes.expertChamps,
              name: ExpertRoutes.champsNom,
              builder: (c, s) => const SupervisionChampsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: ExpertRoutes.champDashboardNom,
                  builder: (c, s) {
                    final id = s.pathParameters['id']!;
                    return ChampDashboardExpertScreen(champId: id);
                  },
                  routes: [
                    GoRoute(
                      path: 'historique',
                      name: ExpertRoutes.historiqueChampNom,
                      builder: (c, s) {
                        final id = s.pathParameters['id']!;
                        return HistoriqueChampScreen(champId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: ExpertRoutes.expertConseils,
              name: ExpertRoutes.conseilsNom,
              builder: (c, s) => const ConseilsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: ExpertRoutes.expertProfil,
              name: ExpertRoutes.profilNom,
              builder: (c, s) => const ProfilExpertScreen(),
            ),
          ]),
        ],
      ),

      // ── Routes plein écran hors shell Expert ─────────────────────
      GoRoute(
        path: ExpertRoutes.expertNouveauConseil,
        name: ExpertRoutes.nouveauConseilNom,
        pageBuilder: (c, s) => pageGlissement(s, const NouveauConseilScreen()),
      ),
      GoRoute(
        path: ExpertRoutes.expertRapport,
        name: ExpertRoutes.rapportNom,
        pageBuilder: (c, s) => pageGlissement(s, const RapportScreen()),
      ),
      GoRoute(
        path: ExpertRoutes.expertPlanifierIntervention,
        name: ExpertRoutes.planifierInterventionNom,
        pageBuilder: (c, s) {
          final champId = s.uri.queryParameters['champId'];
          return pageGlissement(
            s,
            PlanifierInterventionScreen(preselectedChampId: champId),
          );
        },
      ),
      // Ancien tableau de bord de l'expert, conservé en plein écran et
      // atteignable depuis le profil. Son contenu se résumait à trois
      // indicateurs et aux trois premières parcelles supervisées, que l'onglet
      // Champs montre déjà en entier ; le seul chiffre qui manquait, le nombre
      // de recommandations en attente, est désormais en pastille sur l'onglet.
      GoRoute(
        path: ExpertRoutes.expertDashboard,
        name: ExpertRoutes.dashboardNom,
        pageBuilder: (c, s) => pageGlissement(s, const ExpertDashboardScreen()),
      ),

      // ════════════════════════════════════════════════════════════
      // SHELL ADMIN — BottomNavBar 4 onglets Administrateur
      // ════════════════════════════════════════════════════════════
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            AdminScaffold(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, onglets) =>
            ConteneurOnglets(
          navigationShell: navigationShell,
          onglets: onglets,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AdminRoutes.adminDashboard,
              name: AdminRoutes.dashboardNom,
              builder: (c, s) => const AdminDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AdminRoutes.adminUtilisateurs,
              name: AdminRoutes.utilisateursNom,
              builder: (c, s) => const GestionUtilisateursScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AdminRoutes.adminAssignation,
              name: AdminRoutes.assignationNom,
              builder: (c, s) => const AssignationExpertsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AdminRoutes.adminStatistiques,
              name: AdminRoutes.statistiquesNom,
              builder: (c, s) => const StatistiquesScreen(),
            ),
          ]),
        ],
      ),

      // ── Routes plein écran hors shell Admin ──────────────────────
      GoRoute(
        path: AdminRoutes.adminHistorique,
        name: AdminRoutes.historiqueNom,
        pageBuilder: (c, s) =>
            pageGlissement(s, const HistoriqueSystemeScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminProfil,
        name: AdminRoutes.profilNom,
        pageBuilder: (c, s) => pageGlissement(s, const ProfilAdminScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminCreerUser,
        name: AdminRoutes.creerUserNom,
        pageBuilder: (c, s) => pageGlissement(s, const CreerUserScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminModifierUser,
        name: AdminRoutes.modifierUserNom,
        pageBuilder: (c, s) {
          final userId = s.pathParameters['userId']!;
          return pageGlissement(s, ModifierUserScreen(userId: userId));
        },
      ),
      GoRoute(
        path: AdminRoutes.adminNouvelleAssignation,
        name: AdminRoutes.nouvelleAssignationNom,
        pageBuilder: (c, s) =>
            pageGlissement(s, const NouvelleAssignationScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminChamps,
        name: AdminRoutes.champsNom,
        pageBuilder: (c, s) =>
            pageGlissement(s, const GestionChampsAdminScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminCreerChamp,
        name: AdminRoutes.creerChampNom,
        pageBuilder: (c, s) => pageGlissement(s, const CreerChampAdminScreen()),
      ),

      // ── Notifications ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (c, s) => pageGlissement(s, const NotificationsScreen()),
      ),

      // ── Redirections ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        redirect: (_, __) => AppRoutes.dashboard,
      ),
      GoRoute(
        path: ExpertRoutes.expertHome,
        redirect: (_, __) => ExpertRoutes.expertRecommandations,
      ),
      GoRoute(
        path: AdminRoutes.adminHome,
        redirect: (_, __) => AdminRoutes.adminDashboard,
      ),
    ],
  );
});
