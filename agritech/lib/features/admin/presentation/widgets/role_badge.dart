import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Badge du rôle d'un utilisateur.
///
/// Adaptateur : il traduit une donnée métier de la fonctionnalité
/// d'administration en arguments pour [BadgeStatut]. Le dessin, les tailles et
/// les contrastes sont décidés une seule fois, dans le composant partagé, mais
/// ce composant n'a pas à connaître l'énumération des rôles. C'est ce qui
/// garde `shared/` indépendant des fonctionnalités.
///
/// Le violet `#534AB7` qui servait au rôle expert a disparu : il était écrit en
/// dur ici et dans la barre de navigation de l'administration, et n'existait
/// nulle part dans la palette. Le rôle expert prend la couleur
/// d'information, qui est déjà celle de la validation d'expert ailleurs dans
/// l'application.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.compact = false});

  final RoleUtilisateur role;

  /// En liste, le badge s'allège pour ne pas concurrencer le nom de la
  /// personne. En fiche, il est plein.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icone, ton) = switch (role) {
      RoleUtilisateur.agriculteur => (
          Icons.agriculture_outlined,
          TonBadge.primaire
        ),
      RoleUtilisateur.expert => (Icons.verified_user_outlined, TonBadge.info),
      RoleUtilisateur.admin => (
          Icons.admin_panel_settings_outlined,
          TonBadge.neutre
        ),
    };

    return BadgeStatut(
      // Le libellé n'est plus mis en capitales : un mot en capitales se lit
      // plus lentement, les lettres perdant leur silhouette.
      libelle: role.libelle,
      icone: icone,
      ton: ton,
      intensite: compact ? IntensiteBadge.douce : IntensiteBadge.pleine,
    );
  }
}
