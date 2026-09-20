/// Modèle d'une alerte/notification agriculteur.
/// Mappe depuis la réponse GET /notifications/utilisateur/{id}.
class AlerteModel {
  const AlerteModel({
    required this.id,
    required this.titre,
    required this.description,
    this.champId = '',
    this.champNom = '',
    required this.niveau,
    this.maladieDetectee = '',
    this.traitementConseille = '',
    required this.dateCreation,
    this.imageUrl,
    this.isLue = false,
  });

  final String id;
  final String titre;
  final String description;
  final String champId;
  final String champNom;
  final String niveau;
  final String maladieDetectee;
  final String traitementConseille;
  final DateTime dateCreation;
  final String? imageUrl;
  final bool isLue;

  /// Construit depuis une notification du backend.
  factory AlerteModel.fromNotificationJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'RECOMMANDATION').toString().toUpperCase();
    final niveau = switch (type) {
      'INTERVENTION_PLANIFIEE' => 'ÉLEVÉ',
      'CONSEIL_EXPERT' => 'MODÉRÉ',
      _ => 'FAIBLE',
    };
    final corps = (json['corps'] ?? json['message'] ?? '') as String;
    return AlerteModel(
      id: (json['id'] ?? '') as String,
      titre: (json['titre'] ?? 'Notification') as String,
      description: corps,
      champId: (json['referenceId'] ?? '') as String,
      champNom: 'Votre champ',
      niveau: niveau,
      maladieDetectee: '',
      traitementConseille: corps,
      dateCreation: json['dateEnvoi'] != null
          ? DateTime.tryParse(json['dateEnvoi'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isLue: (json['estLue'] ?? json['lu'] ?? false) as bool,
    );
  }

  AlerteModel copyWith({bool? isLue}) => AlerteModel(
        id: id,
        titre: titre,
        description: description,
        champId: champId,
        champNom: champNom,
        niveau: niveau,
        maladieDetectee: maladieDetectee,
        traitementConseille: traitementConseille,
        dateCreation: dateCreation,
        imageUrl: imageUrl,
        isLue: isLue ?? this.isLue,
      );
}
