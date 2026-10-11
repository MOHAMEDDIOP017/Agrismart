import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../domain/enums/statut_assignation.dart';
import '../../domain/enums/statut_utilisateur.dart';

/// Badge du statut d'un compte utilisateur.
///
/// Adaptateur vers [BadgeStatut] : l'énumération reste dans la couche métier
/// de l'administration, le dessin vient du composant partagé.
class StatutUtilisateurBadge extends StatelessWidget {
  const StatutUtilisateurBadge({super.key, required this.statut});

  final StatutUtilisateur statut;

  @override
  Widget build(BuildContext context) {
    final ton = switch (statut) {
      StatutUtilisateur.actif => TonBadge.succes,
      StatutUtilisateur.suspendu => TonBadge.erreur,
      StatutUtilisateur.enAttente => TonBadge.avertissement,
    };

    return BadgeStatut(
      libelle: _enPhrase(statut.libelle),
      icone: statut.icone,
      ton: ton,
    );
  }
}

/// Badge du statut d'une assignation entre un expert et une intervention.
class StatutAssignationBadge extends StatelessWidget {
  const StatutAssignationBadge({super.key, required this.statut});

  final StatutAssignation statut;

  @override
  Widget build(BuildContext context) {
    final ton = switch (statut) {
      StatutAssignation.nonAssignee => TonBadge.neutre,
      StatutAssignation.planifiee => TonBadge.info,
      StatutAssignation.enCours => TonBadge.primaire,
      StatutAssignation.realisee => TonBadge.succes,
      StatutAssignation.annulee => TonBadge.erreur,
    };

    return BadgeStatut(
      libelle: _enPhrase(statut.libelle),
      icone: statut.icone,
      ton: ton,
      intensite: IntensiteBadge.douce,
    );
  }
}

/// Remet en casse de phrase un libellé que l'énumération donne en capitales.
///
/// Les énumérations de l'administration renvoient « ACTIF », « EN ATTENTE ».
/// Un mot tout en capitales se lit plus lentement, parce que les lettres
/// perdent leur silhouette haute et basse. La donnée métier n'est pas touchée,
/// seul l'affichage l'est.
String _enPhrase(String libelle) {
  if (libelle.isEmpty) return libelle;
  final minuscules = libelle.toLowerCase();
  return minuscules[0].toUpperCase() + minuscules.substring(1);
}
