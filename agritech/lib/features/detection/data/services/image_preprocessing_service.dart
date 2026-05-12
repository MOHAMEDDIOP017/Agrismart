import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service de prétraitement d'image avant envoi au modèle IA
class ImagePreprocessingService {
  /// Redimensionne et compresse l'image à 224x224 (standard CNN)
  Future<File> preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) throw Exception('Impossible de décoder l\'image');

    final resized = img.copyResize(image, width: 224, height: 224);
    final compressed = img.encodeJpg(resized, quality: 85);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressed);

    return tempFile;
  }

  /// Évalue la qualité de l'image avant analyse
  Future<ImageQualityResult> evaluerQualite(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        return ImageQualityResult.mauvaise('Format non supporté');
      }

      if (image.width < 100 || image.height < 100) {
        return ImageQualityResult.mauvaise('Image trop petite');
      }

      final luminosite = _calculerLuminosite(image);
      if (luminosite < 0.15) {
        return ImageQualityResult.mauvaise('Image trop sombre');
      }
      if (luminosite > 0.95) {
        return ImageQualityResult.mauvaise('Image surexposée');
      }

      final nettete = _calculerNettete(image);
      if (nettete < 0.008) {
        return ImageQualityResult.avertissement('Image floue — restez immobile');
      }

      return ImageQualityResult.bonne(luminosite: luminosite, nettete: nettete);
    } catch (e) {
      return ImageQualityResult.avertissement('Impossible d\'évaluer la qualité');
    }
  }

  double _calculerLuminosite(img.Image image) {
    double total = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        // API image ^4.x : accès via .rNormalized, .gNormalized, .bNormalized
        total += (pixel.rNormalized + pixel.gNormalized + pixel.bNormalized) / 3;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  double _calculerNettete(img.Image image) {
    double variance = 0;
    int count = 0;
    for (int y = 1; y < image.height - 1; y += 5) {
      for (int x = 1; x < image.width - 1; x += 5) {
        final center = img.getLuminanceNormalized(image.getPixel(x, y));
        final top = img.getLuminanceNormalized(image.getPixel(x, y - 1));
        final bottom = img.getLuminanceNormalized(image.getPixel(x, y + 1));
        final left = img.getLuminanceNormalized(image.getPixel(x - 1, y));
        final right = img.getLuminanceNormalized(image.getPixel(x + 1, y));
        final laplacian = (4 * center - top - bottom - left - right).abs();
        variance += laplacian;
        count++;
      }
    }
    return count > 0 ? variance / count : 0;
  }
}

/// Résultat de l'évaluation de qualité d'une image
class ImageQualityResult {
  const ImageQualityResult._({
    required this.estBonne,
    required this.estAvertissement,
    required this.message,
    this.luminosite,
    this.nettete,
  });

  final bool estBonne;
  final bool estAvertissement;
  final String message;
  final double? luminosite;
  final double? nettete;

  bool get estMauvaise => !estBonne && !estAvertissement;
  bool get peutAnalyser => estBonne || estAvertissement;

  factory ImageQualityResult.bonne({
    required double luminosite,
    required double nettete,
  }) =>
      ImageQualityResult._(
        estBonne: true,
        estAvertissement: false,
        message: 'Image de bonne qualité',
        luminosite: luminosite,
        nettete: nettete,
      );

  factory ImageQualityResult.avertissement(String message) =>
      ImageQualityResult._(
        estBonne: false,
        estAvertissement: true,
        message: message,
      );

  factory ImageQualityResult.mauvaise(String message) =>
      ImageQualityResult._(
        estBonne: false,
        estAvertissement: false,
        message: message,
      );
}
