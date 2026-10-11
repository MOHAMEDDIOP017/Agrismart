import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/utilisateur_admin_entity.dart';
import '../../domain/enums/statut_utilisateur.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_admin_card.dart';

/// Écran de gestion complète des utilisateurs de la plateforme
class GestionUtilisateursScreen extends ConsumerWidget {
  const GestionUtilisateursScreen({super.key});

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAsync = ref.watch(gestionUtilisateursProvider);
    final notifier = ref.read(gestionUtilisateursProvider.notifier);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Gestion des utilisateurs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('creerUser'),
        backgroundColor: _adminPrimary,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text(
          'Créer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Barre de recherche ──────────────────────────────────
          Container(
            color: _adminPrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: notifier.setRecherche,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email, téléphone...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // ── FilterChip par rôle/statut ──────────────────────────
          etatAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (etat) => Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: FiltreUtilisateur.values.map((f) {
                    final selectionne = etat.filtre == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.libelle),
                        selected: selectionne,
                        onSelected: (_) => notifier.setFiltre(f),
                        selectedColor: _adminPrimary.withValues(alpha: 0.15),
                        checkmarkColor: _adminPrimary,
                        labelStyle: TextStyle(
                          color: selectionne
                              ? _adminPrimary
                              : context.couleurs.texteSecondaire,
                          fontWeight:
                              selectionne ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── Liste des utilisateurs ──────────────────────────────
          Expanded(
            child: etatAsync.when(
              loading: () => _ShimmerListe(),
              error: (err, _) => _Erreur(
                message: err.toString(),
                onRetry: () => ref.invalidate(gestionUtilisateursProvider),
              ),
              data: (etat) {
                final liste = etat.filtres;
                if (liste.isEmpty) {
                  return _EtatVide(filtre: etat.filtre.libelle);
                }
                return RefreshIndicator(
                  color: _adminPrimary,
                  onRefresh: () => notifier.rafraichir(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: liste.length,
                    itemBuilder: (context, index) {
                      final u = liste[index];
                      return UserAdminCard(
                        utilisateur: u,
                        onModifier: () => context.pushNamed(
                          'modifierUser',
                          pathParameters: {'userId': u.id},
                        ),
                        onChangerRole: () =>
                            _changerRole(context, ref, u, notifier),
                        onSuspendre: () => _confirmerSuspension(
                            context, ref, u.id, u.estSuspendu, notifier),
                        onSupprimer: () => _confirmerSuppression(
                            context, ref, u.id, u.nomComplet, notifier),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog pour changer le rôle d'un utilisateur
  void _changerRole(
    BuildContext context,
    WidgetRef ref,
    UtilisateurAdminEntity utilisateur,
    GestionUtilisateursNotifier notifier,
  ) {
    RoleUtilisateur roleChoisi = utilisateur.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              'Changer le rôle de ${utilisateur.prenom} ${utilisateur.nom}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rôle actuel : ${utilisateur.role.libelle}',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...RoleUtilisateur.values
                  .map((r) => RadioListTile<RoleUtilisateur>(
                        title: Text(r.libelle),
                        subtitle: Text(
                          r == RoleUtilisateur.agriculteur
                              ? 'Gestion des champs et diagnostics'
                              : r == RoleUtilisateur.expert
                                  ? 'Validation des diagnostics IA'
                                  : 'Administration de la plateforme',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: r,
                        groupValue: roleChoisi,
                        activeColor: const Color(0xFF534AB7),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setDialogState(() => roleChoisi = v!),
                      )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok =
                    await notifier.changerRole(utilisateur.id, roleChoisi);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Rôle modifié : ${roleChoisi.libelle}'
                        : 'Erreur lors du changement de rôle'),
                    backgroundColor: ok
                        ? context.couleurs.primaire
                        : context.couleurs.erreur,
                  ));
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog de confirmation avant suspension/réactivation
  void _confirmerSuspension(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool estSuspendu,
    GestionUtilisateursNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          estSuspendu ? 'Réactiver le compte ?' : 'Suspendre le compte ?',
        ),
        content: Text(
          estSuspendu
              ? 'L\'utilisateur pourra de nouveau se connecter.'
              : 'L\'utilisateur ne pourra plus se connecter à la plateforme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: estSuspendu
                  ? context.couleurs.primaire
                  : context.couleurs.secondaire,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await notifier.changerStatut(
                id,
                estSuspendu
                    ? StatutUtilisateur.actif
                    : StatutUtilisateur.suspendu,
              );
            },
            child: Text(estSuspendu ? 'Réactiver' : 'Suspendre'),
          ),
        ],
      ),
    );
  }

  /// Dialog de confirmation avant suppression définitive
  void _confirmerSuppression(
    BuildContext context,
    WidgetRef ref,
    String id,
    String nomComplet,
    GestionUtilisateursNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le compte de $nomComplet ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.couleurs.erreur,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await notifier.supprimerUtilisateur(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? '$nomComplet a été supprimé avec succès'
                          : 'Erreur lors de la suppression de $nomComplet',
                    ),
                    backgroundColor: ok
                        ? context.couleurs.erreur
                        : context.couleurs.secondaire,
                  ),
                );
              }
            },
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────

class _ShimmerListe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: context.couleurs.erreur, size: 48),
          const SizedBox(height: 12),
          Text(
            'Erreur de chargement',
            style: AppTypography.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  const _EtatVide({required this.filtre});

  final String filtre;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 64,
              color: context.couleurs.texteSecondaire.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur',
            style: AppTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Aucun résultat pour "$filtre"',
            style: AppTypography.textTheme.bodySmall!.copyWith(
              color: context.couleurs.texteSecondaire,
            ),
          ),
        ],
      ),
    );
  }
}
