import 'package:equatable/equatable.dart';
import '../enums/type_conseil.dart';

/// Statut d'un conseil envoyé
enum StatutConseil {
  brouillon,
  envoye,
  lu;

  String get libelle {
    switch (this) {
      case StatutConseil.brouillon:
        return 'Brouillon';
      case StatutConseil.envoye:
        return 'Envoyé';
      case StatutConseil.lu:
        return 'Lu';
    }
  }
}

/// Entité représentant un conseil envoyé par un expert à un agriculteur
class ConseilEntity extends Equatable {
  const ConseilEntity({
    required this.id,
    required this.expertId,
    required this.agriculteurId,
    required this.agriculteurNom,
    required this.champId,
    required this.champNom,
    required this.typeConseil,
    required this.titre,
    required this.corps,
    required this.statut,
    required this.dateCreation,
    this.imageUrl,
    this.estUrgent = false,
    this.dateLecture,
  });

  final String id;
  final String expertId;
  final String agriculteurId;
  final String agriculteurNom;
  final String champId;
  final String champNom;
  final TypeConseil typeConseil;
  final String titre;
  final String corps;
  final StatutConseil statut;
  final DateTime dateCreation;
  final String? imageUrl;
  final bool estUrgent;
  final DateTime? dateLecture;

  bool get estLu => statut == StatutConseil.lu;
  bool get estEnvoye => statut == StatutConseil.envoye || estLu;

  @override
  List<Object?> get props => [id, dateCreation];
}
