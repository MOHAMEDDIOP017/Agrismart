class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.titre,
    required this.corps,
    required this.type,
    required this.dateEnvoi,
    this.estLue = false,
    this.referenceId,
  });

  final String id;
  final String titre;
  final String corps;
  final String type;
  final DateTime dateEnvoi;
  final bool estLue;
  final String? referenceId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: (json['id'] ?? '') as String,
        titre: (json['titre'] ?? '') as String,
        corps: (json['corps'] ?? json['message'] ?? '') as String,
        type: (json['type'] ?? 'INFO') as String,
        dateEnvoi: json['dateEnvoi'] != null
            ? DateTime.tryParse(json['dateEnvoi'].toString()) ?? DateTime.now()
            : DateTime.now(),
        estLue: (json['estLue'] ?? json['lu'] ?? false) as bool,
        referenceId: json['referenceId'] as String?,
      );
}
