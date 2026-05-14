import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/admin_router.dart';
import '../providers/admin_provider.dart';

/// Écran de gestion des champs agricoles — vue Administrateur
class GestionChampsAdminScreen extends ConsumerWidget {
  const GestionChampsAdminScreen({super.key});

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAsync = ref.watch(champsAdminProvider);
    final notifier = ref.read(champsAdminProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Gestion des champs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AdminRoutes.creerChampNom),
        backgroundColor: _adminPrimary,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text(
          'Créer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Barre de recherche ─────────────────────────────────────
          Container(
            color: _adminPrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: notifier.setRecherche,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, culture, type de sol...',
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

          // ── Liste des champs ───────────────────────────────────────
          Expanded(
            child: etatAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _EtatErreur(
                message: err.toString(),
                onRetry: () => ref.invalidate(champsAdminProvider),
              ),
              data: (etat) {
                final liste = etat.filtres;
                if (liste.isEmpty) {
                  return _EtatVide(recherche: etat.recherche);
                }
                return RefreshIndicator(
                  color: _adminPrimary,
                  onRefresh: () => notifier.rafraichir(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: liste.length,
                    itemBuilder: (context, index) {
                      final champ = liste[index];
                      return _ChampAdminCard(
                        champ: champ,
                        onSupprimer: () => _confirmerSuppression(
                          context,
                          ref,
                          champ.id,
                          champ.nom,
                          notifier,
                        ),
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

  void _confirmerSuppression(
    BuildContext context,
    WidgetRef ref,
    String id,
    String nomChamp,
    ChampsAdminNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le champ ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$nomChamp" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await notifier.supprimerChamp(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$nomChamp" supprimé'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ── Card d'un champ ───────────────────────────────────────────────────────

class _ChampAdminCard extends StatelessWidget {
  const _ChampAdminCard({required this.champ, required this.onSupprimer});

  final dynamic champ;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy', 'fr_FR').format(champ.dateCreation);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.terrain_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    champ.nom as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Info(icone: Icons.straighten_rounded, texte: champ.superficieFormatee as String),
                      _Info(icone: Icons.layers_outlined, texte: champ.typeSol as String),
                      if (champ.culture != null)
                        _Info(icone: Icons.grass_rounded, texte: champ.culture as String),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Info(
                    icone: Icons.calendar_today_outlined,
                    texte: 'Créé le $dateStr',
                    couleur: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Bouton supprimer
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
              tooltip: 'Supprimer',
              onPressed: onSupprimer,
            ),

            // Badge statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statutCouleur(champ.statut as String).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statutLibelle(champ.statut as String),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statutCouleur(champ.statut as String),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statutCouleur(String statut) => switch (statut.toUpperCase()) {
        'EN_COURS' => AppColors.primary,
        'PREVU' => AppColors.amber,
        'TERMINE' => AppColors.textSecondary,
        _ => AppColors.textSecondary,
      };

  String _statutLibelle(String statut) => switch (statut.toUpperCase()) {
        'EN_COURS' => 'En cours',
        'PREVU' => 'Prévu',
        'TERMINE' => 'Terminé',
        _ => statut,
      };
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texte, this.couleur});

  final IconData icone;
  final String texte;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final color = couleur ?? AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: color),
        const SizedBox(width: 3),
        Text(texte, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

// ── États vide / erreur ───────────────────────────────────────────────────

class _EtatVide extends StatelessWidget {
  const _EtatVide({required this.recherche});
  final String recherche;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terrain_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            recherche.isEmpty ? 'Aucun champ enregistré' : 'Aucun résultat pour "$recherche"',
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EtatErreur extends StatelessWidget {
  const _EtatErreur({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          const Text('Erreur de chargement',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
