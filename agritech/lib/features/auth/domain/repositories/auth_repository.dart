import '../entities/user_entity.dart';

/// Contrat du repository d'authentification
abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String zoneGeographique,
    required String password,
    String? adresse,
    String? villageVille,
  });
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
}
