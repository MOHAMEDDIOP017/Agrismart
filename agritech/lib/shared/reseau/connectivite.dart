import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État du réseau, tel que le téléphone le rapporte.
enum EtatReseau {
  /// Au moins une interface réseau est active.
  connecte,

  /// Aucune interface active.
  deconnecte,

  /// Impossible de savoir : la plateforme ne répond pas, ou le greffon n'est
  /// pas disponible, ce qui arrive dans les tests et sur certaines versions
  /// d'Android. Dans ce cas, l'interface ne montre rien plutôt que d'annoncer
  /// à tort une coupure.
  inconnu;

  bool get estHorsLigne => this == EtatReseau.deconnecte;
}

/// Suit l'état du réseau du téléphone.
///
/// `connectivity_plus` figurait dans les dépendances du projet sans qu'aucune
/// ligne ne l'appelle : l'application n'avait aucun moyen de savoir qu'elle
/// avait perdu le réseau.
///
/// Limite à connaître, et c'est pour cela que le libellé du bandeau reste
/// prudent : ce que rapporte le système, c'est l'état des interfaces, pas
/// l'accès réel à Internet. Un téléphone accroché à une antenne sans données
/// utilisables se déclare `mobile`. Dans les zones visées, c'est le cas
/// fréquent. Le bandeau ne s'affiche donc que sur une coupure franche, et
/// c'est le message d'erreur de l'écran, lui déclenché par un vrai échec de
/// requête, qui couvre le cas de la connexion faible.
///
/// Ce provider ne fait que lire un état du système. Il ne touche ni aux
/// données métier ni aux appels au serveur.
final connectiviteProvider = StreamProvider<EtatReseau>((ref) async* {
  final connectivite = Connectivity();

  // Premier état, pour ne pas attendre un changement avant de savoir.
  try {
    yield etatDepuis(await connectivite.checkConnectivity());
  } catch (_) {
    yield EtatReseau.inconnu;
  }

  yield* connectivite.onConnectivityChanged
      .map(etatDepuis)
      .handleError((_) => EtatReseau.inconnu);
});

/// Raccourci booléen pour les widgets qui n'ont besoin que de savoir si le
/// réseau est tombé. Une erreur ou une absence de réponse valent « en ligne » :
/// mieux vaut ne rien annoncer que signaler une coupure qui n'existe pas.
final estHorsLigneProvider = Provider<bool>((ref) {
  return ref.watch(connectiviteProvider).maybeWhen(
        data: (etat) => etat.estHorsLigne,
        orElse: () => false,
      );
});

/// Traduit la réponse de la plateforme en état lisible.
///
/// Exposé plutôt que privé pour être couvert par les tests : c'est la seule
/// logique de ce fichier, et c'est elle qui décide si un bandeau annonce une
/// coupure. Une réponse vide vaut « inconnu » et non « déconnecté », parce que
/// sur certaines versions d'Android la plateforme ne répond rien : annoncer
/// une coupure à tort serait pire que de ne rien dire.
EtatReseau etatDepuis(List<ConnectivityResult> resultats) {
  if (resultats.isEmpty) return EtatReseau.inconnu;
  final actif = resultats.any((r) => r != ConnectivityResult.none);
  return actif ? EtatReseau.connecte : EtatReseau.deconnecte;
}
