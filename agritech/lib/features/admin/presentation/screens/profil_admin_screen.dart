import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/admin_provider.dart';
import '../widgets/kpi_admin_card.dart';

/// Écran de profil de l'Administrateur connecté
class ProfilAdminScreen extends ConsumerWidget {
  const ProfilAdminScreen({super.key});

  static const Color _adminPrimary = Color(0xFF534AB7);
  static const Color _adminDark = Color(0xFF3D3491);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminConnecteProvider);
    if (admin == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final statsAsync = ref.watch(statistiquesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── En-tête avec avatar ────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _adminPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_adminDark, _adminPrimary],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              (admin.prenom.isNotEmpty ? admin.prenom[0] : admin.email.isNotEmpty ? admin.email[0] : 'A').toUpperCase() +
                              (admin.nom.isNotEmpty ? admin.nom[0] : '').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: _adminPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        admin.nomComplet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Niveau d\'accès ${admin.niveauAcces ?? 1} • Administrateur',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Statistiques Admin ───────────────────────────
                  Text(
                    'Mes statistiques',
                    style: AppTypography.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  statsAsync.when(
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Impossible de charger les statistiques',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    data: (state) {
                      final s = state.statistiques;
                      return GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          KpiAdminCard(
                            titre: 'Utilisateurs',
                            valeur: '${s.totalUtilisateurs}',
                            icone: Icons.people_outline,
                            couleur: _adminPrimary,
                          ),
                          KpiAdminCard(
                            titre: 'Experts actifs',
                            valeur: '${s.totalExperts}',
                            icone: Icons.verified_user_outlined,
                            couleur: AppColors.amber,
                          ),
                          KpiAdminCard(
                            titre: 'Diagnostics IA',
                            valeur: '${s.totalDiagnostics}',
                            icone: Icons.biotech_outlined,
                            couleur: AppColors.teal,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Informations du compte ───────────────────────
                  Text(
                    'Informations du compte',
                    style: AppTypography.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CarteInfo(
                    enfants: [
                      _InfoLigne(
                        icone: Icons.person_outline,
                        label: 'Nom complet',
                        valeur: admin.nomComplet,
                      ),
                      _InfoLigne(
                        icone: Icons.email_outlined,
                        label: 'Email',
                        valeur: admin.email,
                      ),
                      _InfoLigne(
                        icone: Icons.phone_outlined,
                        label: 'Téléphone',
                        valeur: admin.telephone,
                      ),
                      _InfoLigne(
                        icone: Icons.location_on_outlined,
                        label: 'Région',
                        valeur: admin.region,
                      ),
                      _InfoLigne(
                        icone: Icons.calendar_today_outlined,
                        label: 'Membre depuis',
                        valeur: _dateFormatee(admin.dateInscription),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Paramètres ────────────────────────────────────
                  Text(
                    'Paramètres',
                    style: AppTypography.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CarteInfo(
                    enfants: [
                      _SwitchLigne(
                        icone: Icons.notifications_outlined,
                        label: 'Notifications système',
                        valeur: true,
                        onChanged: (_) {},
                      ),
                      _TileLigne(
                        icone: Icons.lock_outline,
                        label: 'Changer le mot de passe',
                        onTap: () => _afficherChangementMdp(context),
                      ),
                      _TileLigne(
                        icone: Icons.info_outline,
                        label: 'À propos d\'AgriSmart',
                        onTap: () => _afficherAPropos(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Déconnexion ───────────────────────────────────
                  _CarteInfo(
                    enfants: [
                      _TileLigne(
                        icone: Icons.logout,
                        label: 'Déconnexion',
                        couleur: AppColors.danger,
                        onTap: () => _confirmerDeconnexion(context, ref),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherChangementMdp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mot de passe actuel'),
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _adminPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _afficherAPropos(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'AgriSmart',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.agriculture, color: AppColors.primary, size: 32),
      ),
      children: const [
        Text(
          'AgriSmart est une application mobile d\'assistance agricole intelligente '
          'dédiée à l\'Afrique subsaharienne.',
        ),
      ],
    );
  }

  void _confirmerDeconnexion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DeconnexionService.deconnecter(ref);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  String _dateFormatee(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Widgets locaux ────────────────────────────────────────────────────────

class _CarteInfo extends StatelessWidget {
  const _CarteInfo({required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: enfants
            .asMap()
            .entries
            .expand((e) => [
                  e.value,
                  if (e.key < enfants.length - 1)
                    const Divider(height: 1, indent: 52),
                ])
            .toList(),
      ),
    );
  }
}

class _InfoLigne extends StatelessWidget {
  const _InfoLigne({
    required this.icone,
    required this.label,
    required this.valeur,
  });

  final IconData icone;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(
        label,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
      subtitle: Text(
        valeur,
        style: AppTypography.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _TileLigne extends StatelessWidget {
  const _TileLigne({
    required this.icone,
    required this.label,
    required this.onTap,
    this.couleur,
  });

  final IconData icone;
  final String label;
  final VoidCallback onTap;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final c = couleur ?? AppColors.textPrimary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, size: 18, color: c),
      ),
      title: Text(
        label,
        style: AppTypography.textTheme.bodyMedium!.copyWith(color: c),
      ),
      trailing: Icon(Icons.chevron_right, color: c.withValues(alpha: 0.5)),
      onTap: onTap,
    );
  }
}

class _SwitchLigne extends StatefulWidget {
  const _SwitchLigne({
    required this.icone,
    required this.label,
    required this.valeur,
    required this.onChanged,
  });

  final IconData icone;
  final String label;
  final bool valeur;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchLigne> createState() => _SwitchLigneState();
}

class _SwitchLigneState extends State<_SwitchLigne> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.valeur;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icone, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(
        widget.label,
        style: AppTypography.textTheme.bodyMedium,
      ),
      value: _val,
      activeColor: const Color(0xFF534AB7),
      onChanged: (v) {
        setState(() => _val = v);
        widget.onChanged(v);
      },
    );
  }
}
