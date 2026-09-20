class CultureEnChampModel {
  const CultureEnChampModel({
    required this.id,
    required this.champId,
    required this.cultureName,
    required this.datePlantation,
    required this.statutCycle,
    this.dureeCycleDays,
    this.notes,
    this.agriculteurId,
  });

  final String id;
  final String champId;
  final String cultureName;
  final DateTime datePlantation;
  final String statutCycle;
  final int? dureeCycleDays;
  final String? notes;
  final String? agriculteurId;

  factory CultureEnChampModel.fromJson(Map<String, dynamic> json) {
    return CultureEnChampModel(
      id: json['id'] as String? ?? '',
      champId: json['champId'] as String? ?? '',
      cultureName: json['cultureName'] as String? ?? '',
      datePlantation: _parseDate(json['datePlantation']),
      statutCycle: json['statutCycle'] as String? ?? 'EN_COURS',
      dureeCycleDays: json['dureeCycleDays'] as int?,
      notes: json['notes'] as String?,
      agriculteurId: json['agriculteurId'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // Firestore Timestamp
    if (value is Map) {
      final seconds = (value['_seconds'] ?? value['seconds']) as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }

  String get statutLabel {
    switch (statutCycle) {
      case 'EN_COURS':
        return 'En cours';
      case 'RECOLTE':
        return 'Récolté';
      case 'ABANDONNE':
        return 'Abandonné';
      default:
        return statutCycle;
    }
  }

  /// Pourcentage d'avancement du cycle (0.0 à 1.0).
  double get progression {
    if (dureeCycleDays == null || dureeCycleDays! <= 0) return 0;
    final elapsed = DateTime.now().difference(datePlantation).inDays;
    return (elapsed / dureeCycleDays!).clamp(0.0, 1.0);
  }

  int get joursEcoules =>
      DateTime.now().difference(datePlantation).inDays.clamp(0, 9999);
}
