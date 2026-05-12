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

  factory MeteoModel.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List?)?.first as Map<String, dynamic>? ?? {};
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};
    final desc = (weather['description'] as String? ?? 'inconnu').toLowerCase();
    final iconCode = (weather['icon'] as String? ?? '');
    final icone = iconCode.startsWith('01') ? 'sunny'
        : iconCode.startsWith('09') || iconCode.startsWith('10') ? 'rainy'
        : iconCode.startsWith('11') ? 'stormy'
        : 'cloudy';
    return MeteoModel(
      ville: json['name'] as String? ?? '',
      temperature: ((main['temp'] as num?) ?? 0).toDouble(),
      temperatureMin: ((main['temp_min'] as num?) ?? 0).toDouble(),
      temperatureMax: ((main['temp_max'] as num?) ?? 0).toDouble(),
      humidite: (main['humidity'] as int?) ?? 0,
      description: desc,
      icone: icone,
      pluviometrie: ((rain['1h'] as num?) ?? 0).toDouble(),
      vitesseVent: ((wind['speed'] as num?) ?? 0).toDouble(),
    );
  }
}
