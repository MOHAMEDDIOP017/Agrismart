import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/utilisateur_admin_entity.dart';
import 'role_badge.dart';
import 'statut_badge_admin.dart';

/// Carte utilisateur pour la liste de gestion Admin
class UserAdminCard extends StatelessWidget {
  const UserAdminCard({
    super.key,
    required this.utilisateur,
    required this.onModifier,
    required this.onSuspendre,
    required this.onSupprimer,
    required this.onChangerRole,
  });

  final UtilisateurAdminEntity utilisateur;
  final VoidCallback onModifier;
  final VoidCallback onSuspendre;
  final VoidCallback onSupprimer;
  final VoidCallback onChangerRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.couleurs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.couleurs.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne principale : avatar + infos + badges
          Row(
            children: [
              _AvatarInitiales(
                initiales: _initiales(utilisateur),
                couleur: _couleurRole(context, utilisateur),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      utilisateur.nomComplet,
                      style: AppTypography.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      utilisateur.email,
                      style: AppTypography.textTheme.bodySmall!.copyWith(
                        color: context.couleurs.texteSecondaire,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badges rôle + statut
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RoleBadge(role: utilisateur.role, compact: true),
                  const SizedBox(height: 4),
                  StatutUtilisateurBadge(statut: utilisateur.statut),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Ligne secondaire : région, téléphone, date
          Row(
            children: [
              _InfoChip(
                icone: Icons.location_on_outlined,
                texte: utilisateur.region,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icone: Icons.phone_outlined,
                texte: utilisateur.telephone,
              ),
              const Spacer(),
              Text(
                _dateFormatee(utilisateur.dateInscription),
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: context.couleurs.texteSecondaire,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _BoutonAction(
                icone: Icons.edit_outlined,
                couleur: context.couleurs.info,
                tooltip: 'Modifier',
                onTap: onModifier,
              ),
              const SizedBox(width: 6),
              _BoutonAction(
                icone: Icons.manage_accounts_outlined,
                couleur: const Color(0xFF534AB7),
                tooltip: 'Changer le rôle',
                onTap: onChangerRole,
              ),
              const SizedBox(width: 6),
              _BoutonAction(
                icone: utilisateur.estSuspendu
                    ? Icons.check_circle_outline
                    : Icons.block_outlined,
                couleur: utilisateur.estSuspendu
                    ? context.couleurs.primaire
                    : context.couleurs.secondaire,
                tooltip: utilisateur.estSuspendu ? 'Réactiver' : 'Suspendre',
                onTap: onSuspendre,
              ),
              const SizedBox(width: 6),
              _BoutonAction(
                icone: Icons.delete_outline,
                couleur: context.couleurs.erreur,
                tooltip: 'Supprimer',
                onTap: onSupprimer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initiales(UtilisateurAdminEntity u) {
    final p = u.prenom.isNotEmpty ? u.prenom[0].toUpperCase() : '';
    final n = u.nom.isNotEmpty ? u.nom[0].toUpperCase() : '';
    return '$p$n';
  }

  Color _couleurRole(BuildContext context, UtilisateurAdminEntity u) {
    switch (u.role) {
      case _ when u.role.name == 'agriculteur':
        return context.couleurs.primaire;
      case _ when u.role.name == 'expert':
        return const Color(0xFF534AB7);
      default:
        return const Color(0xFF888780);
    }
  }

  String _dateFormatee(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _AvatarInitiales extends StatelessWidget {
  const _AvatarInitiales({required this.initiales, required this.couleur});

  final String initiales;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: couleur.withValues(alpha: 0.15),
      child: Text(
        initiales,
        style: TextStyle(
          color: couleur,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 12, color: context.couleurs.texteSecondaire),
        const SizedBox(width: 3),
        Text(
          texte,
          style: AppTypography.textTheme.labelSmall!.copyWith(
            color: context.couleurs.texteSecondaire,
          ),
        ),
      ],
    );
  }
}

class _BoutonAction extends StatelessWidget {
  const _BoutonAction({
    required this.icone,
    required this.couleur,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icone;
  final Color couleur;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 18, color: couleur),
        ),
      ),
    );
  }
}
