class MeteoModel {
  const MeteoModel({
    required this.ville,
    required this.temperature,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.humidite,
    required this.description,
    required this.icone,
    required this.pluviometrie,
    required this.vitesseVent,
  });

  final String ville;
  final double temperature;
  final double temperatureMin;
  final double temperatureMax;
  final int humidite;
  final String description;
  final String icone; // 'sunny', 'rainy', 'cloudy', 'stormy'
  final double pluviometrie;
  final double vitesseVent;

  String get temperatureLabel => '${temperature.toInt()}°C';
  String get humiditeLabel => '$humidite%';
  String get pluviometrieLabel => '${pluviometrie.toInt()} mm';
  String get ventLabel => '${vitesseVent.toInt()} km/h';

  /// Parse le format renvoyé par le backend AgriSmart (champs plats).
  factory MeteoModel.fromJson(Map<String, dynamic> json) {
    final desc = (json['description'] as String? ?? 'inconnu').toLowerCase();
    final String icone;
    if (desc.contains('dégagé') || desc.contains('soleil') || desc.contains('ensoleillé')) {
      icone = 'sunny';
    } else if (desc.contains('pluie') || desc.contains('pluvieux') || desc.contains('averse') || desc.contains('bruine')) {
      icone = 'rainy';
    } else if (desc.contains('orage') || desc.contains('tempête')) {
      icone = 'stormy';
    } else {
      icone = 'cloudy';
    }
    return MeteoModel(
      ville: json['ville'] as String? ?? '',
      temperature: ((json['temperature'] as num?) ?? 0).toDouble(),
      temperatureMin: ((json['temperature_min'] as num?) ?? 0).toDouble(),
      temperatureMax: ((json['temperature_max'] as num?) ?? 0).toDouble(),
      humidite: ((json['humidite'] as num?) ?? 0).toInt(),
      description: desc,
      icone: icone,
      pluviometrie: ((json['pluviometrie'] as num?) ?? 0).toDouble(),
      vitesseVent: ((json['vitesse_vent'] as num?) ?? 0).toDouble(),
    );
  }
}
