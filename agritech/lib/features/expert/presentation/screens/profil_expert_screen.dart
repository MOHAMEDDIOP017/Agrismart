import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/expert_provider.dart';
import '../widgets/animated_counter.dart';

/// Profil complet de l'Expert avec statistiques et paramètres
class ProfilExpertScreen extends ConsumerStatefulWidget {
  const ProfilExpertScreen({super.key});

  @override
  ConsumerState<ProfilExpertScreen> createState() => _ProfilExpertScreenState();
}

class _ProfilExpertScreenState extends ConsumerState<ProfilExpertScreen> {
  bool _notificationsActives = true;
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilExpertProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (expert) => CustomScrollView(
          slivers: [
            // ── En-tête vert foncé ──────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.primaryDark,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      // Avatar cliquable
                      GestureDetector(
                        onTap: () {/* image picker */},
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white24,
                              child: Text(
                                expert.prenom[0] + expert.nom[0],
                                style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(expert.nomComplet,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(
                        '${expert.specialite.libelle} · ${expert.regionCouverture}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(_editMode ? Icons.check : Icons.edit_outlined,
                      color: Colors.white),
                  onPressed: () => setState(() => _editMode = !_editMode),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Informations ──────────────────────────────
                  _sectionTitle('Informations personnelles'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _infoRow(Icons.person_outline, 'Nom complet', expert.nomComplet),
                          _infoRow(Icons.email_outlined, 'Email', expert.email),
                          _infoRow(Icons.phone_outlined, 'Téléphone', expert.telephone),
                          _infoRow(Icons.location_on_outlined, 'Région', expert.regionCouverture),
                          _infoRow(Icons.science_outlined, 'Spécialité', expert.specialite.libelle),
                          _infoRow(Icons.work_outline, 'Expérience',
                              '${expert.anneesExperience} ans'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Statistiques ──────────────────────────────
                  _sectionTitle('Mes statistiques'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _statCard('Diagnostics validés',
                          expert.nombreDiagnosticsValides, AppColors.primary),
                      _statCard('Corrections apportées',
                          expert.nombreCorrections, AppColors.amber),
                      _statCard('Interventions réalisées',
                          expert.nombreInterventions, AppColors.info),
                      _statCard('Conseils envoyés',
                          expert.nombreConseils, AppColors.coral),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Taux précision IA
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Taux de précision IA corrigée',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textSecondary)),
                        Text(expert.tauxPrecisionFormate,
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Paramètres ────────────────────────────────
                  _sectionTitle('Paramètres'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _paramTile(
                          Icons.notifications_outlined,
                          'Notifications',
                          trailing: Switch.adaptive(
                            value: _notificationsActives,
                            activeColor: AppColors.primary,
                            onChanged: (v) =>
                                setState(() => _notificationsActives = v),
                          ),
                        ),
                        const Divider(height: 1),
                        _paramTile(Icons.language_outlined, 'Langue',
                            trailing: Text('Français',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary))),
                        const Divider(height: 1),
                        _paramTile(Icons.info_outline, 'À propos',
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                            onTap: () {}),
                        const Divider(height: 1),
                        _paramTile(
                          Icons.logout_outlined,
                          'Déconnexion',
                          couleur: AppColors.danger,
                          onTap: () => _confirmerDeconnexion(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );

  Widget _infoRow(IconData icon, String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('$label : ',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            Expanded(
              child: Text(valeur,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _statCard(String label, int valeur, Color couleur) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: couleur.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCounter(
              value: valeur,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: couleur),
            ),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _paramTile(
    IconData icon,
    String label, {
    Widget? trailing,
    Color? couleur,
    VoidCallback? onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: couleur ?? AppColors.textSecondary, size: 20),
        title: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: couleur ?? AppColors.textPrimary)),
        trailing: trailing,
        onTap: onTap,
      );

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Déconnexion',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DeconnexionService.deconnecter(ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('Déconnexion',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
