import 'dart:io';
import '../entities/diagnostic_entity.dart';

/// Contrat du repository de détection de maladies
abstract class DetectionRepository {
  /// Lance l'analyse IA sur une image
  Future<DiagnosticEntity> analyserImage({
    required File imageFile,
    String? champId,
  });

  /// Récupère l'historique des diagnostics de l'utilisateur
  Future<List<DiagnosticEntity>> getHistoriqueDiagnostics();

  /// Récupère un diagnostic par son ID
  Future<DiagnosticEntity?> getDiagnosticById(String id);

  /// Enregistre l'évaluation de l'utilisateur sur un diagnostic
  Future<void> soumettreEvaluation({
    required String diagnosticId,
    required String choix,
    String? commentaire,
  });

  /// Archive un diagnostic
  Future<void> archiverDiagnostic(String id);

  /// Supprime un diagnostic de l'historique
  Future<void> supprimerDiagnostic(String id);
}
