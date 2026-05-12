import 'package:equatable/equatable.dart';
import '../enums/type_traitement.dart';

/// Entité représentant un traitement recommandé pour une maladie
class TraitementEntity extends Equatable {
  const TraitementEntity({
    required this.id,
    required this.nomProduit,
    required this.dosage,
    required this.frequenceApplication,
    required this.dureeDays,
    required this.type,
    required this.coutFcfa,
    this.instructionsDetaillees,
    this.precautions,
    this.disponibleEnAfrique = true,
  });

  final String id;
  final String nomProduit;
  final String dosage;
  final String frequenceApplication;
  final int dureeDays;
  final TypeTraitement type;
  final int coutFcfa;
  final String? instructionsDetaillees;
  final String? precautions;
  final bool disponibleEnAfrique;

  String get dureeFormatee => '$dureeDays jours';
  String get coutFormate => '${coutFcfa.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  List<Object?> get props => [id, nomProduit, type];
}
