import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Écran profil agriculteur
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _notificationsActives = true;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await DeconnexionService.deconnecter(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // En-tête avec fond vert et avatar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Avatar cliquable
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Modifier la photo de profil')),
                          ),
                          child: Stack(
                            children: [
                              const CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user?.nomComplet ?? 'Agriculteur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          user?.zoneGeographique ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // Statistiques animées
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatsGrid(user: user),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Informations personnelles
              const _SectionHeader(title: 'Informations'),
              _ProfileTile(
                icon: Icons.person_outline,
                label: 'Nom complet',
                value: user?.nomComplet ?? '—',
              ),
              _ProfileTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user?.email ?? '—',
              ),
              _ProfileTile(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: user?.telephone ?? '—',
              ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                label: 'Zone géographique',
                value: user?.zoneGeographique ?? '—',
              ),

              const SizedBox(height: 16),

              // Paramètres
              const _SectionHeader(title: 'Paramètres'),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: Switch(
                  value: _notificationsActives,
                  onChanged: (v) => setState(() => _notificationsActives = v),
                  activeColor: AppColors.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.language_outlined,
                label: 'Langue',
                trailing: const Text(
                  'Français',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'À propos d\'AgriSmart',
                onTap: () => _showAbout(context),
              ),

              const SizedBox(height: 8),

              // Déconnexion
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('AgriSmart'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text(
              'Application d\'assistance agricole intelligente pour les agriculteurs d\'Afrique subsaharienne.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.terrain_rounded, 'Champs', user?.nombreChamps ?? 0, AppColors.primary),
      (Icons.camera_alt_rounded, 'Diagnostics', user?.nombreDiagnostics ?? 0, AppColors.teal),
      (Icons.psychology_rounded, 'Recommandations', user?.nombreRecommandations ?? 0, AppColors.amber),
      (Icons.star_rounded, 'Évaluations', user?.nombreEvaluations ?? 0, AppColors.coral),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: stats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: s.$4.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: s.$4.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(s.$1, color: s.$4, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: s.$3 as int),
                    duration: Duration(milliseconds: 800 + i * 200),
                    builder: (_, v, __) => Text(
                      '$v',
                      style: TextStyle(
                        color: s.$4,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Text(
                    s.$2,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleSmall),
      dense: true,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
      onTap: onTap,
      dense: true,
    );
  }
}
