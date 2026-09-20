import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../navigation/app_router.dart';

/// Provider du repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepositoryImpl(),
);

/// État de l'authentification
class AuthState {
  static const int maxTentatives = 3;
  static const Duration dureeVerrouillage = Duration(seconds: 30);

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.tentativesEchouees = 0,
    this.isLocked = false,
  });

  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  /// Nombre de tentatives de connexion échouées consécutives
  final int tentativesEchouees;

  /// Vrai si le compte est temporairement verrouillé après trop d'échecs
  final bool isLocked;

  int get tentativesRestantes =>
      (maxTentatives - tentativesEchouees).clamp(0, maxTentatives);

  /// Route d'accueil selon le rôle de l'utilisateur connecté
  String get routeInitiale {
    if (user == null) return AppRoutes.login;
    return user!.routeHome;
  }

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    int? tentativesEchouees,
    bool? isLocked,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        tentativesEchouees: tentativesEchouees ?? this.tentativesEchouees,
        isLocked: isLocked ?? this.isLocked,
      );
}

/// Notifier de l'authentification
class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final user = await _repo.getCurrentUser();
    return AuthState(
      user: user,
      isAuthenticated: user != null,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    final current = state.valueOrNull ?? const AuthState();

    // Accès verrouillé → refus immédiat
    if (current.isLocked) return false;

    state = const AsyncLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AsyncData(AuthState(user: user, isAuthenticated: true));
      return true;
    } catch (e) {
      final nouvelles = current.tentativesEchouees + 1;
      final locked = nouvelles >= AuthState.maxTentatives;
      state = AsyncData(AuthState(
        error: e.toString(),
        tentativesEchouees: nouvelles,
        isLocked: locked,
      ));
      // Déverrouillage automatique après la durée configurée
      if (locked) {
        Future.delayed(AuthState.dureeVerrouillage, () {
          if (state.valueOrNull?.isLocked == true) {
            state = const AsyncData(AuthState());
          }
        });
      }
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String zoneGeographique,
    required String password,
    String? adresse,
    String? villageVille,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.register(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        zoneGeographique: zoneGeographique,
        password: password,
        adresse: adresse,
        villageVille: villageVille,
      );
      state = AsyncData(AuthState(user: user, isAuthenticated: true));
      return true;
    } catch (e) {
      state = AsyncData(AuthState(error: e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(AuthState(isAuthenticated: false));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Utilisateur connecté (null si non authentifié)
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).valueOrNull?.user;
});

/// Provider du rôle de l'utilisateur connecté
final roleUtilisateurProvider = Provider<RoleUtilisateur>((ref) {
  return ref.watch(currentUserProvider)?.role ?? RoleUtilisateur.agriculteur;
});

/// Vrai si l'utilisateur connecté est un Expert
final estExpertProvider = Provider<bool>((ref) {
  return ref.watch(roleUtilisateurProvider) == RoleUtilisateur.expert;
});
