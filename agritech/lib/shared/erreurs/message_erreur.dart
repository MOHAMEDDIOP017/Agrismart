import 'dart:io';

import 'package:dio/dio.dart';

/// Traduit une exception technique en une phrase compréhensible.
///
/// L'audit avait relevé 21 écrans affichant littéralement
/// `Center(child: Text('Erreur : $e'))`. L'agriculteur y lisait la trace d'une
/// exception Dio, avec l'URL de l'API et le code HTTP. Dans le meilleur des
/// cas il n'y comprenait rien, dans le pire il croyait avoir cassé quelque
/// chose.
///
/// Trois règles tiennent les formulations.
///
/// Dire ce qui se passe, pas ce qui a échoué. « La connexion est lente »
/// décrit une situation que la personne peut reconnaître et attendre ;
/// « DioException: connectionTimeout » décrit un événement technique.
///
/// Rassurer sur les données quand c'est vrai. Une coupure réseau pendant une
/// lecture ne perd rien, et le dire évite de ressaisir par précaution. La
/// phrase ne l'affirme que là où c'est exact : un envoi interrompu, lui, peut
/// avoir été perdu, et le message invite alors à vérifier.
///
/// Rester court. Ces phrases seront traduites en wolof, et chaque mot gagné
/// en français laisse de la place à la traduction.
///
/// Cette classe est le seul endroit de la couche présentation qui connaisse
/// Dio. C'est un compromis assumé : l'alternative, inspecter le texte du
/// message dans chaque écran, revient à ce que l'audit a trouvé.
class MessageErreur {
  MessageErreur._();

  /// Phrase à montrer à l'utilisateur.
  static String pour(Object? erreur) {
    if (erreur is DioException) return _depuisDio(erreur);
    if (erreur is SocketException) return _sansConnexion;
    if (erreur is HttpException) return _serviceIndisponible;
    if (erreur is FormatException) return _reponseIllisible;
    return _generique;
  }

  /// Titre court, pour l'en-tête d'un état d'erreur.
  static String titrePour(Object? erreur) {
    if (estReseau(erreur)) return 'Connexion interrompue';
    if (erreur is DioException) {
      final code = erreur.response?.statusCode;
      if (code == 401 || code == 403) return 'Session expirée';
      if (code == 404) return 'Introuvable';
    }
    return 'Quelque chose a bloqué';
  }

  /// Vrai quand l'erreur vient du réseau et non du serveur.
  ///
  /// Sert à choisir l'illustration et à savoir si proposer « Réessayer » a du
  /// sens : réessayer une requête refusée pour cause de droits insuffisants ne
  /// produira jamais autre chose.
  static bool estReseau(Object? erreur) {
    if (erreur is SocketException) return true;
    if (erreur is! DioException) return false;
    switch (erreur.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        return erreur.error is SocketException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return false;
    }
  }

  /// Vrai quand réessayer peut changer le résultat.
  static bool vautLaPeineDeReessayer(Object? erreur) {
    if (estReseau(erreur)) return true;
    if (erreur is DioException) {
      final code = erreur.response?.statusCode ?? 0;
      return code == 0 || code >= 500 || code == 408 || code == 429;
    }
    return true;
  }

  static String _depuisDio(DioException erreur) {
    switch (erreur.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La connexion est faible. Vos données sont gardées, '
            'réessayez dans un instant.';

      case DioExceptionType.sendTimeout:
        // Un envoi coupé en cours de route peut n'être jamais arrivé : la
        // phrase ne promet pas que les données sont gardées.
        return 'L\'envoi n\'a pas abouti. Vérifiez votre réseau, '
            'puis réessayez.';

      case DioExceptionType.connectionError:
        return _sansConnexion;

      case DioExceptionType.badCertificate:
        return 'La connexion au serveur n\'est pas sûre. '
            'Prévenez votre encadrant.';

      case DioExceptionType.cancel:
        return 'Demande arrêtée.';

      case DioExceptionType.badResponse:
        return _depuisCodeHttp(erreur.response?.statusCode);

      case DioExceptionType.unknown:
        if (erreur.error is SocketException) return _sansConnexion;
        return _generique;
    }
  }

  static String _depuisCodeHttp(int? code) {
    switch (code) {
      case 400:
      case 422:
        return 'Certaines informations ne sont pas acceptées. '
            'Vérifiez ce que vous avez saisi.';
      case 401:
      case 403:
        return 'Votre session a expiré. Connectez-vous à nouveau.';
      case 404:
        return 'Cette information n\'existe plus.';
      case 408:
        return 'Le serveur a mis trop de temps. Réessayez dans un instant.';
      case 429:
        return 'Trop de demandes d\'un coup. Patientez un instant.';
      default:
        if (code != null && code >= 500) return _serviceIndisponible;
        return _generique;
    }
  }

  static const String _sansConnexion =
      'Pas de connexion. Vos données sont gardées, '
      'réessayez quand le réseau revient.';

  static const String _serviceIndisponible =
      'Le service est momentanément arrêté. Réessayez dans un instant.';

  static const String _reponseIllisible =
      'La réponse du serveur est incomplète. Réessayez dans un instant.';

  static const String _generique =
      'Quelque chose a bloqué. Réessayez dans un instant.';
}
