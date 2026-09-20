import '../../domain/entities/culture_entity.dart';

class CultureModel extends CultureEntity {
  const CultureModel({
    required super.id,
    required super.nom,
    required super.variete,
    required super.cycleMaturation,
    required super.besoinsHydriques,
    required super.rendementMoyen,
    required super.phOptimal,
    required super.nOptimal,
    required super.pOptimal,
    required super.kOptimal,
    required super.tempMin,
    required super.tempMax,
    required super.humiditeMin,
    required super.humiditeMax,
    required super.pluvioMin,
    required super.pluvioMax,
    required super.prixMoyenMarche,
  });

  factory CultureModel.fromJson(Map<String, dynamic> json) => CultureModel(
        id: (json['id'] ?? '') as String,
        nom: (json['nom'] ?? '') as String,
        variete: (json['variete'] ?? '') as String,
        cycleMaturation:
            (json['cycle_maturation'] ?? json['cycleMaturation'] ?? 0) as int,
        besoinsHydriques:
            (json['besoins_hydriques'] ?? json['besoinsHydriques'] ?? '') as String,
        rendementMoyen:
            ((json['rendement_moyen'] ?? json['rendementMoyen']) as num? ?? 0.0)
                .toDouble(),
        phOptimal:
            ((json['ph_optimal'] ?? json['phOptimal']) as num? ?? 7.0).toDouble(),
        nOptimal: ((json['n_optimal'] ?? json['nOptimal'] ?? json['N_optimal'])
                    as num? ??
                0.0)
            .toDouble(),
        pOptimal: ((json['p_optimal'] ?? json['pOptimal'] ?? json['P_optimal'])
                    as num? ??
                0.0)
            .toDouble(),
        kOptimal: ((json['k_optimal'] ?? json['kOptimal'] ?? json['K_optimal'])
                    as num? ??
                0.0)
            .toDouble(),
        tempMin:
            ((json['temp_min'] ?? json['tempMin']) as num? ?? 15.0).toDouble(),
        tempMax:
            ((json['temp_max'] ?? json['tempMax']) as num? ?? 40.0).toDouble(),
        humiditeMin:
            ((json['humidite_min'] ?? json['humiditeMin']) as num? ?? 40.0)
                .toDouble(),
        humiditeMax:
            ((json['humidite_max'] ?? json['humiditeMax']) as num? ?? 90.0)
                .toDouble(),
        pluvioMin:
            ((json['pluvio_min'] ?? json['pluvioMin']) as num? ?? 200.0)
                .toDouble(),
        pluvioMax:
            ((json['pluvio_max'] ?? json['pluvioMax']) as num? ?? 1000.0)
                .toDouble(),
        prixMoyenMarche:
            ((json['prix_moyen_marche'] ?? json['prixMoyenMarche']) as num? ?? 0.0)
                .toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'variete': variete,
        'cycle_maturation': cycleMaturation,
        'besoins_hydriques': besoinsHydriques,
        'rendement_moyen': rendementMoyen,
        'ph_optimal': phOptimal,
        'n_optimal': nOptimal,
        'p_optimal': pOptimal,
        'k_optimal': kOptimal,
        'temp_min': tempMin,
        'temp_max': tempMax,
        'humidite_min': humiditeMin,
        'humidite_max': humiditeMax,
        'pluvio_min': pluvioMin,
        'pluvio_max': pluvioMax,
        'prix_moyen_marche': prixMoyenMarche,
      };
}
