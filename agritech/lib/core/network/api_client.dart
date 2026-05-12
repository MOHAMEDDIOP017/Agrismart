import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

class ApiClient {
  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 30),
    ));

    // Intercepteur auth : token Firebase réel ou bypass dev
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers['Authorization'] = 'Bearer dev-bypass-token';
          }
        } catch (_) {
          options.headers['Authorization'] = 'Bearer dev-bypass-token';
        }
        handler.next(options);
      },
    ));

    // Intercepteur erreurs centralisé
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final status = error.response?.statusCode;
        final message = switch (status) {
          401 => 'Session expirée, veuillez vous reconnecter.',
          403 => "Vous n'avez pas accès à cette ressource.",
          404 => 'Ressource introuvable.',
          500 => 'Erreur serveur, veuillez réessayer.',
          503 => 'Service temporairement indisponible.',
          _ => error.type == DioExceptionType.connectionError
              ? 'Vérifiez votre connexion internet.'
              : error.message ?? 'Erreur inconnue.',
        };
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            error: message,
            type: error.type,
          ),
        );
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  late final Dio dio;
}

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());

final dioProvider = Provider<Dio>((ref) => ref.read(apiClientProvider).dio);
