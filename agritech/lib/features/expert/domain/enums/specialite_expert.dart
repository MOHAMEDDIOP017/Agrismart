/// Spécialités d'un expert agronome
enum SpecialiteExpert {
  phytopathologie,
  agronomie,
  pedologie,
  entomologie,
  generaliste;

  String get libelle {
    switch (this) {
      case SpecialiteExpert.phytopathologie:
        return 'Phytopathologie';
      case SpecialiteExpert.agronomie:
        return 'Agronomie';
      case SpecialiteExpert.pedologie:
        return 'Pédologie';
      case SpecialiteExpert.entomologie:
        return 'Entomologie';
      case SpecialiteExpert.generaliste:
        return 'Généraliste';
    }
  }

  static SpecialiteExpert fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PHYTOPATHOLOGIE':
        return SpecialiteExpert.phytopathologie;
      case 'AGRONOMIE':
        return SpecialiteExpert.agronomie;
      case 'PEDOLOGIE':
        return SpecialiteExpert.pedologie;
      case 'ENTOMOLOGIE':
        return SpecialiteExpert.entomologie;
      default:
        return SpecialiteExpert.generaliste;
    }
  }
}
