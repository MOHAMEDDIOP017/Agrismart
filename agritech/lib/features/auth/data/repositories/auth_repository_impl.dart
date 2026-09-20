import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _keyUser = 'user_data';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = ApiClient().dio;

  // ─── Login ────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw FirebaseAuthException(
              code: 'network-request-failed',
              message:
                  'Délai dépassé. Vérifiez votre connexion et réessayez.',
            ),
          );
      // Obtient le token initial
      final token = await credential.user!.getIdToken(true);

      // Crée/met à jour le profil Firestore + pose les Custom Claims côté serveur
      await _dio.post(
        '/auth/verify-token',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Force un second refresh pour que le SDK cache le token avec les nouveaux Claims
      // (indispensable pour que require_admin() fonctionne sur les appels suivants)
      final freshToken = await credential.user!.getIdToken(true);

      // Récupère le profil enrichi depuis le backend avec le token à jour
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $freshToken'}),
      );
      final user = UserModel.fromBackendJson(response.data as Map<String, dynamic>);
      await _persistUser(user);
      return user;
    } on FirebaseAuthException catch (e) {
      if (_isUserError(e)) throw Exception(_mapFirebaseError(e));
      // Erreur infra Firebase (réseau, reCAPTCHA, timeout…)
      // 1) Si une session Firebase est déjà ouverte, on l'utilise
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        final fallback = await _userFromFirebase(fbUser);
        await _persistUser(fallback);
        return fallback;
      }
      // 2) Tentative backend en mode DEV_BYPASS_AUTH (token 'dev-bypass-token'
      //    envoyé automatiquement par l'intercepteur quand currentUser == null)
      try {
        final resp = await _dio.get('/auth/me');
        final user = UserModel.fromBackendJson(resp.data as Map<String, dynamic>);
        await _persistUser(user);
        return user;
      } catch (_) {}
      throw Exception(_mapFirebaseError(e));
    } on DioException catch (e) {
      // Firebase OK mais backend inaccessible → lit le rôle depuis les Custom Claims
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        final fallback = await _userFromFirebase(fbUser);
        await _persistUser(fallback);
        return fallback;
      }
      throw Exception(e.error?.toString() ?? 'Erreur réseau');
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String zoneGeographique,
    required String password,
    String? adresse,
    String? villageVille,
  }) async {
    try {
      // 1. Création du compte Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;
      await fbUser.updateDisplayName('$prenom $nom');

      // 2. Écriture du profil dans Firestore (collection users/{uid})
      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .set({
        'id': fbUser.uid,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'zone_geographique': zoneGeographique,
        'role': 'AGRICULTEUR',
        'actif': true,
        'date_inscription': FieldValue.serverTimestamp(),
        'nombre_champs': 0,
        'nombre_recommandations': 0,
        'nombre_evaluations': 0,
        'notifications_actives': true,
        if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
        if (villageVille != null && villageVille.isNotEmpty)
          'village_ville': villageVille,
      });

      // 3. Tenter de poser les Custom Claims via verify-token + récupérer le profil enrichi
      try {
        final token = await fbUser.getIdToken(true);
        await _dio.post(
          '/auth/verify-token',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        final freshToken = await fbUser.getIdToken(true);
        final response = await _dio.get(
          '/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $freshToken'}),
        );
        final user =
            UserModel.fromBackendJson(response.data as Map<String, dynamic>);
        await _persistUser(user);
        return user;
      } catch (_) {
        // Backend inaccessible → construire l'entité depuis les données locales
        final user = UserModel(
          id: fbUser.uid,
          nom: nom,
          prenom: prenom,
          email: email,
          telephone: telephone,
          zoneGeographique: zoneGeographique,
          role: RoleUtilisateur.agriculteur,
          adresse: adresse,
          villageVille: villageVille,
          actif: true,
          dateInscription: now,
        );
        await _persistUser(user);
        return user;
      }
    } on FirebaseAuthException catch (e) {
      if (_isUserError(e)) throw Exception(_mapFirebaseError(e));
      throw Exception('Erreur lors de la création du compte. Réessayez.');
    } catch (e) {
      throw Exception('Erreur inattendue : $e');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keyUser);
    if (userData == null) return null;
    return UserModel.fromJson(jsonDecode(userData) as Map<String, dynamic>);
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUser);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel> _userFromFirebase(User fbUser) async {
    // Lit le rôle depuis les Custom Claims Firebase
    final tokenResult = await fbUser.getIdTokenResult();
    final roleStr = tokenResult.claims?['role'] as String? ?? 'AGRICULTEUR';
    final parts = (fbUser.displayName ?? '').split(' ');
    return UserModel(
      id: fbUser.uid,
      nom: parts.length > 1 ? parts.last : '',
      prenom: parts.isNotEmpty ? parts.first : '',
      email: fbUser.email ?? '',
      telephone: fbUser.phoneNumber ?? '',
      zoneGeographique: 'Sénégal',
      role: RoleUtilisateur.fromString(roleStr),
      photoUrl: fbUser.photoURL,
    );
  }

  // Retourne true si l'erreur vient de l'utilisateur (mauvais mdp, email invalide...)
  bool _isUserError(FirebaseAuthException e) {
    const userErrors = {
      'user-not-found',
      'wrong-password',
      'invalid-email',
      'user-disabled',
      'email-already-in-use',
      'weak-password',
      'invalid-credential',
    };
    return userErrors.contains(e.code);
  }

  String _mapFirebaseError(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' => 'Aucun compte trouvé avec cet email.',
        'wrong-password' => 'Mot de passe incorrect.',
        'invalid-email' => 'Adresse email invalide.',
        'user-disabled' => 'Ce compte a été désactivé.',
        'email-already-in-use' => 'Un compte existe déjà avec cet email.',
        'weak-password' => 'Le mot de passe doit contenir au moins 6 caractères.',
        'network-request-failed' => 'Vérifiez votre connexion internet.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        'invalid-credential' => 'Email ou mot de passe incorrect.',
        _ => e.message ?? 'Erreur d\'authentification.',
      };
}
