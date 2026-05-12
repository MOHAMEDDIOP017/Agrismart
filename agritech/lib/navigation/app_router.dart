import 'dart:io';
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
import '../features/donnees_agro/presentation/screens/donnees_agro_screen.dart';
import '../features/recommandations/presentation/screens/recommandations_screen.dart';
import '../features/alertes/presentation/screens/alertes_screen.dart';
import '../features/alertes/presentation/screens/alerte_detail_screen.dart';
import '../features/suivi/presentation/screens/suivi_screen.dart';
import '../features/profil/presentation/screens/profil_screen.dart';
import '../features/detection/domain/entities/diagnostic_entity.dart';
import '../features/detection/presentation/screens/detection_home_screen.dart';
import '../features/detection/presentation/screens/camera_screen.dart';
import '../features/detection/presentation/screens/image_preview_screen.dart';
import '../features/detection/presentation/screens/analyse_en_cours_screen.dart';
import '../features/detection/presentation/screens/diagnostic_result_screen.dart';
import '../features/detection/presentation/screens/diagnostic_historique_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/shared/presentation/screens/non_autorise_screen.dart';

// ── Expert ───────────────────────────────────────────────────────────────────
import '../features/expert/presentation/screens/expert_dashboard_screen.dart';
import '../features/expert/presentation/screens/diagnostics_en_attente_screen.dart';
import '../features/expert/presentation/screens/diagnostic_detail_expert_screen.dart';
import '../features/expert/presentation/screens/supervision_champs_screen.dart';
import '../features/expert/presentation/screens/champ_dashboard_expert_screen.dart';
import '../features/expert/presentation/screens/historique_champ_screen.dart';
import '../features/expert/presentation/screens/planifier_intervention_screen.dart';
import '../features/expert/presentation/screens/conseils_screen.dart';
import '../features/expert/presentation/screens/nouveau_conseil_screen.dart';
import '../features/expert/presentation/screens/alertes_zone_screen.dart';
import '../features/expert/presentation/screens/rapport_screen.dart';
import '../features/expert/presentation/screens/profil_expert_screen.dart';

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
  static const donneesAgro = '/home/donnees-agro';
  static const recommandations = '/home/dashboard/recommandations';
  static const alertes = '/home/alertes';
  static const alerteDetail = '/home/alertes/:id';
  static const suivi = '/home/suivi';
  static const profil = '/home/profil';

  // Module Détection — dans le shell
  static const detection = '/home/detection';
  static const diagnosticHistorique = '/home/detection/historique';

  // Notifications
  static const notifications = '/notifications';

  // Module Détection — plein écran (hors shell, poussés par-dessus)
  static const camera = '/camera';
  static const imagePreview = '/image-preview';
  static const analyseEnCours = '/analyse-en-cours';
  static const diagnosticResult = '/diagnostic-result';
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

bool _estRouteAgriculteur(String path) =>
    path.startsWith('/home') ||
    path == AppRoutes.camera ||
    path == AppRoutes.imagePreview ||
    path == AppRoutes.analyseEnCours ||
    path == AppRoutes.diagnosticResult;

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
        pageBuilder: (c, s) => _fadePage(s, const SplashScreen()),
      ),

      // ── Onboarding ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (c, s) => _fadePage(s, const OnboardingScreen()),
      ),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (c, s) => _fadePage(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (c, s) => _fadePage(s, const RegisterScreen()),
      ),

      // ── Accès non autorisé ────────────────────────────────
      GoRoute(
        path: AppRoutes.nonAutorise,
        name: 'non-autorise',
        pageBuilder: (c, s) => _fadePage(s, const NonAutoriseScreen()),
      ),

      // ════════════════════════════════════════════════════════════
      // SHELL AGRICULTEUR — BottomNavBar 5 onglets
      // ════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          // Onglet 0 — Accueil / Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (c, s) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'donnees-agro',
                  name: 'donnees-agro',
                  builder: (c, s) => const DonneesAgroScreen(),
                ),
                GoRoute(
                  path: 'suivi',
                  name: 'suivi',
                  builder: (c, s) => const SuiviScreen(),
                ),
                GoRoute(
                  path: 'recommandations',
                  name: 'recommandations',
                  builder: (c, s) => const RecommandationsScreen(),
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

          // Onglet 2 — Détection IA
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.detection,
              name: 'detection',
              builder: (c, s) => const DetectionHomeScreen(),
              routes: [
                GoRoute(
                  path: 'historique',
                  name: 'diagnostic-historique',
                  builder: (c, s) => const DiagnosticHistoriqueScreen(),
                ),
              ],
            ),
          ]),

          // Onglet 3 — Alertes
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.alertes,
              name: 'alertes',
              builder: (c, s) => const AlertesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'alerte-detail',
                  builder: (c, s) {
                    final id = s.pathParameters['id']!;
                    return AlerteDetailScreen(alerteId: id);
                  },
                ),
              ],
            ),
          ]),

          // Onglet 4 — Profil Agriculteur
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profil,
              name: 'profil',
              builder: (c, s) => const ProfilScreen(),
            ),
          ]),
        ],
      ),

      // ════════════════════════════════════════════════════════════
      // SHELL EXPERT — BottomNavBar 5 onglets Expert
      // ════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ExpertScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: ExpertRoutes.expertDashboard,
              name: ExpertRoutes.dashboardNom,
              builder: (c, s) => const ExpertDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: ExpertRoutes.expertDiagnostics,
              name: ExpertRoutes.diagnosticsNom,
              builder: (c, s) => const DiagnosticsEnAttenteScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: ExpertRoutes.diagnosticDetailNom,
                  builder: (c, s) {
                    final id = s.pathParameters['id']!;
                    return DiagnosticDetailExpertScreen(diagnosticId: id);
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

      // ── Routes plein écran hors shell Agriculteur ────────────────
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        pageBuilder: (c, s) => _fadePage(s, const CameraScreen()),
      ),
      GoRoute(
        path: AppRoutes.imagePreview,
        name: 'image-preview',
        pageBuilder: (c, s) {
          final file = s.extra as File;
          return _fadePage(s, ImagePreviewScreen(imageFile: file));
        },
      ),
      GoRoute(
        path: AppRoutes.analyseEnCours,
        name: 'analyse-en-cours',
        pageBuilder: (c, s) {
          final args = s.extra as Map<String, dynamic>;
          return _fadePage(
            s,
            AnalyseEnCoursScreen(
              imageFile: args['imageFile'] as File,
              champId: args['champId'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.diagnosticResult,
        name: 'diagnostic-result',
        pageBuilder: (c, s) {
          final diagnostic = s.extra as DiagnosticEntity;
          return _fadePage(s, DiagnosticResultScreen(diagnostic: diagnostic));
        },
      ),

      // ── Routes plein écran hors shell Expert ─────────────────────
      GoRoute(
        path: ExpertRoutes.expertNouveauConseil,
        name: ExpertRoutes.nouveauConseilNom,
        pageBuilder: (c, s) => _fadePage(s, const NouveauConseilScreen()),
      ),
      GoRoute(
        path: ExpertRoutes.expertAlertes,
        name: ExpertRoutes.alertesNom,
        pageBuilder: (c, s) => _fadePage(s, const AlertesZoneScreen()),
      ),
      GoRoute(
        path: ExpertRoutes.expertRapport,
        name: ExpertRoutes.rapportNom,
        pageBuilder: (c, s) => _fadePage(s, const RapportScreen()),
      ),
      GoRoute(
        path: ExpertRoutes.expertPlanifierIntervention,
        name: ExpertRoutes.planifierInterventionNom,
        pageBuilder: (c, s) {
          final champId = s.uri.queryParameters['champId'];
          return _fadePage(
            s,
            PlanifierInterventionScreen(preselectedChampId: champId),
          );
        },
      ),

      // ════════════════════════════════════════════════════════════
      // SHELL ADMIN — BottomNavBar 4 onglets Administrateur
      // ════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminScaffold(navigationShell: navigationShell),
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
        pageBuilder: (c, s) => _fadePage(s, const HistoriqueSystemeScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminProfil,
        name: AdminRoutes.profilNom,
        pageBuilder: (c, s) => _fadePage(s, const ProfilAdminScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminCreerUser,
        name: AdminRoutes.creerUserNom,
        pageBuilder: (c, s) => _fadePage(s, const CreerUserScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminModifierUser,
        name: AdminRoutes.modifierUserNom,
        pageBuilder: (c, s) {
          final userId = s.pathParameters['userId']!;
          return _fadePage(s, ModifierUserScreen(userId: userId));
        },
      ),
      GoRoute(
        path: AdminRoutes.adminNouvelleAssignation,
        name: AdminRoutes.nouvelleAssignationNom,
        pageBuilder: (c, s) => _fadePage(s, const NouvelleAssignationScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminChamps,
        name: AdminRoutes.champsNom,
        pageBuilder: (c, s) => _fadePage(s, const GestionChampsAdminScreen()),
      ),
      GoRoute(
        path: AdminRoutes.adminCreerChamp,
        name: AdminRoutes.creerChampNom,
        pageBuilder: (c, s) => _fadePage(s, const CreerChampAdminScreen()),
      ),

      // ── Notifications ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (c, s) => _fadePage(s, const NotificationsScreen()),
      ),

      // ── Redirections ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        redirect: (_, __) => AppRoutes.dashboard,
      ),
      GoRoute(
        path: ExpertRoutes.expertHome,
        redirect: (_, __) => ExpertRoutes.expertDashboard,
      ),
      GoRoute(
        path: AdminRoutes.adminHome,
        redirect: (_, __) => AdminRoutes.adminDashboard,
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );
}
