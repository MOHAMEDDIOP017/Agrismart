import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilNotifier extends AsyncNotifier<UserEntity?> {
  late Dio _dio;

  @override
  Future<UserEntity?> build() async {
    _dio = ref.read(dioProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return _charger(user.id);
  }

  Future<UserEntity?> _charger(String userId) async {
    try {
      final resp = await _dio.get('/utilisateurs/$userId');
      return UserModel.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback sur les données Firebase Auth si backend indisponible
      return ref.read(currentUserProvider);
    }
  }

  Future<void> rafraichir() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _charger(user.id));
  }

  Future<bool> mettreAJour({
    required String nom,
    required String prenom,
    required String telephone,
    String? adresse,
    String? villageVille,
    String? zoneGeographique,
  }) async {
    final user = state.valueOrNull;
    if (user == null) return false;

    try {
      await _dio.put(
        '/utilisateurs/${user.id}',
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
          if (villageVille != null && villageVille.isNotEmpty)
            'villageVille': villageVille,
          if (zoneGeographique != null && zoneGeographique.isNotEmpty)
            'zoneGeographique': zoneGeographique,
        },
      );

      state = AsyncData(UserModel(
        id: user.id,
        nom: nom,
        prenom: prenom,
        email: user.email,
        telephone: telephone,
        zoneGeographique:
            (zoneGeographique?.isNotEmpty == true) ? zoneGeographique! : user.zoneGeographique,
        role: user.role,
        photoUrl: user.photoUrl,
        nombreChamps: user.nombreChamps,
        nombreRecommandations: user.nombreRecommandations,
        adresse: (adresse?.isNotEmpty == true) ? adresse : user.adresse,
        villageVille:
            (villageVille?.isNotEmpty == true) ? villageVille : user.villageVille,
        dateInscription: user.dateInscription,
        actif: user.actif,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final profilProvider = AsyncNotifierProvider<ProfilNotifier, UserEntity?>(
  ProfilNotifier.new,
);
