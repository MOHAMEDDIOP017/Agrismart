class AlerteModel {
  const AlerteModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.champId,
    required this.champNom,
    required this.niveau,
    required this.maladieDetectee,
    required this.traitementConseille,
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
