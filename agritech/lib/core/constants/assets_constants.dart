/// Chemins et URL des ressources graphiques de l'application.
///
/// Les 14 animations Lottie et les 3 images locales déclarées auparavant ici
/// n'existaient pas sur le disque : `assets/lottie/` et `assets/images/` sont
/// vides, et le paquet `lottie` n'était appelé nulle part. Toute lecture de
/// ces constantes levait une exception d'asset manquant. Elles ont été
/// retirées avec la dépendance, pour que ce fichier ne décrive que des
/// ressources réellement disponibles.
///
/// Les états vides et de chargement sont dessinés avec des formes vectorielles
/// et des icônes Material plutôt qu'avec des animations Lottie : sur un
/// téléphone d'entrée de gamme, un fichier Lottie se décode à chaque affichage
/// et coûte plus cher qu'un rendu de formes simples.
class AssetsConstants {
  AssetsConstants._();

  /// Visuel de repli d'une parcelle sans photo.
  static const String fieldPlaceholder =
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=600';

  /// Visuel de repli d'un avatar sans photo de profil.
  static const String avatarPlaceholder =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200';
}
