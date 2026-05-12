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
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

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
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
    state = const AsyncLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AsyncData(AuthState(user: user, isAuthenticated: true));
      return true;
    } catch (e) {
      state = AsyncData(AuthState(error: e.toString()));
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
      await _repo.register(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        zoneGeographique: zoneGeographique,
        password: password,
        adresse: adresse,
        villageVille: villageVille,
      );
      // Ne pas authentifier après inscription — l'utilisateur doit se connecter manuellement
      state = const AsyncData(AuthState(isAuthenticated: false));
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
