import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../enums/type_log.dart';

/// Entrée dans le journal d'activité du système
class LogSystemeEntity extends Equatable {
  const LogSystemeEntity({
    required this.id,
    required this.type,
    required this.description,
    required this.utilisateurNom,
    required this.utilisateurRole,
    required this.horodatage,
    this.estArchive = false,
    this.details,
  });

  final String id;
  final TypeLog type;
  /// Description courte de l'action effectuée
  final String description;
  final String utilisateurNom;
  final RoleUtilisateur utilisateurRole;
  final DateTime horodatage;
  final bool estArchive;
  /// Détails supplémentaires (JSON ou texte libre)
  final String? details;

  /// Horodatage formaté pour l'affichage : JJ/MM/AAAA à HH:MM:SS
  String get horodatageFormate {
    final d = horodatage;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final heure =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    return '$date à $heure';
  }

  LogSystemeEntity copyWith({bool? estArchive}) {
    return LogSystemeEntity(
      id: id,
      type: type,
      description: description,
      utilisateurNom: utilisateurNom,
      utilisateurRole: utilisateurRole,
      horodatage: horodatage,
      estArchive: estArchive ?? this.estArchive,
      details: details,
    );
  }

  @override
  List<Object?> get props => [id, horodatage];
}
