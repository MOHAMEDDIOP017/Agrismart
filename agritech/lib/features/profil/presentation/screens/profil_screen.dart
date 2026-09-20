import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../providers/profil_provider.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeconnexionService.deconnecter(ref);
      });
    }
  }

  void _ouvrirEdition(BuildContext context) {
    final user = ref.read(profilProvider).valueOrNull;
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfilSheet(
        nom: user.nom,
        prenom: user.prenom,
        telephone: user.telephone,
        adresse: user.adresse ?? '',
        villageVille: user.villageVille ?? '',
        zoneGeographique: user.zoneGeographique,
        onSave: (nom, prenom, tel, adresse, ville, zone) async {
          final messenger = ScaffoldMessenger.of(context);
          final ok = await ref.read(profilProvider.notifier).mettreAJour(
                nom: nom,
                prenom: prenom,
                telephone: tel,
                adresse: adresse,
                villageVille: ville,
                zoneGeographique: zone,
              );
          if (!mounted) return;
          messenger.showSnackBar(SnackBar(
            content:
                Text(ok ? 'Profil mis à jour avec succès.' : 'Erreur lors de la mise à jour.'),
            backgroundColor: ok ? AppColors.primary : AppColors.danger,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilProvider);
    final champsAsync = ref.watch(champProvider);
    final nbChamps = champsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      body: profilAsync.when(
        loading: () => const ShimmerList(count: 5, cardHeight: 60),
        error: (e, _) => _ErrorView(onRetry: ref.read(profilProvider.notifier).rafraichir),
        data: (user) {
          if (user == null) {
            return const _ErrorView();
          }

          return RefreshIndicator(
            onRefresh: ref.read(profilProvider.notifier).rafraichir,
            child: CustomScrollView(
              slivers: [
                // ─── En-tête ────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: AppColors.primaryDark,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      tooltip: 'Modifier le profil',
                      onPressed: () => _ouvrirEdition(context),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                        // Cercles décoratifs
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 60,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: Colors.white24,
                                    child: Text(
                                      '${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _ouvrirEdition(context),
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
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user.nomComplet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.role.libelle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
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
                    const SizedBox(height: 16),

                    // ─── Stats ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _StatsRow(
                        nbChamps: nbChamps,
                        nbRecommandations: user.nombreRecommandations,
                        dateInscription: user.dateInscription,
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 20),

                    // ─── Informations personnelles ─────────────────────────
                    const _SectionHeader(title: 'Informations personnelles'),
                    _ProfileTile(
                      icon: Icons.person_outline,
                      label: 'Nom complet',
                      value: user.nomComplet,
                    ),
                    _ProfileTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    _ProfileTile(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: user.telephone.isNotEmpty ? user.telephone : '—',
                    ),
                    if (user.zoneGeographique.isNotEmpty)
                      _ProfileTile(
                        icon: Icons.location_city_outlined,
                        label: 'Zone géographique',
                        value: user.zoneGeographique,
                      ),
                    if (user.villageVille?.isNotEmpty == true)
                      _ProfileTile(
                        icon: Icons.home_outlined,
                        label: 'Ville / Village',
                        value: user.villageVille!,
                      ),
                    if (user.adresse?.isNotEmpty == true)
                      _ProfileTile(
                        icon: Icons.map_outlined,
                        label: 'Adresse',
                        value: user.adresse!,
                      ),

                    const SizedBox(height: 8),

                    // ─── Paramètres ────────────────────────────────────────
                    const _SectionHeader(title: 'Paramètres'),
                    const _SettingsTile(
                      icon: Icons.language_outlined,
                      label: 'Langue',
                      trailing: Text(
                        'Français',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'À propos de KoobalaTech',
                      onTap: () => _showAbout(context),
                    ),

                    const SizedBox(height: 16),

                    // ─── Déconnexion ───────────────────────────────────────
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
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            const Text('KoobalaTech'),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.nbChamps,
    required this.nbRecommandations,
    this.dateInscription,
  });

  final int nbChamps;
  final int nbRecommandations;
  final DateTime? dateInscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.terrain_rounded,
          label: 'Champs',
          value: '$nbChamps',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.psychology_rounded,
          label: 'Recommandations',
          value: '$nbRecommandations',
          color: AppColors.amber,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'Membre depuis',
          value: dateInscription != null
              ? DateFormatter.formatMonthYear(dateInscription!)
              : '—',
          color: AppColors.info,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Bottom Sheet ──────────────────────────────────────────────────────

class _EditProfilSheet extends ConsumerStatefulWidget {
  const _EditProfilSheet({
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.adresse,
    required this.villageVille,
    required this.zoneGeographique,
    required this.onSave,
  });

  final String nom;
  final String prenom;
  final String telephone;
  final String adresse;
  final String villageVille;
  final String zoneGeographique;
  final Future<void> Function(
    String nom,
    String prenom,
    String telephone,
    String adresse,
    String villageVille,
    String zoneGeographique,
  ) onSave;

  @override
  ConsumerState<_EditProfilSheet> createState() => _EditProfilSheetState();
}

class _EditProfilSheetState extends ConsumerState<_EditProfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _villeCtrl;
  String? _zoneSelectionnee;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.nom);
    _prenomCtrl = TextEditingController(text: widget.prenom);
    _telCtrl = TextEditingController(text: widget.telephone);
    _adresseCtrl = TextEditingController(text: widget.adresse);
    _villeCtrl = TextEditingController(text: widget.villageVille);
    _zoneSelectionnee =
        widget.zoneGeographique.isNotEmpty ? widget.zoneGeographique : null;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await widget.onSave(
      _nomCtrl.text.trim(),
      _prenomCtrl.text.trim(),
      _telCtrl.text.trim(),
      _adresseCtrl.text.trim(),
      _villeCtrl.text.trim(),
      _zoneSelectionnee ?? '',
    );
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Modifier mon profil',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                AppTextField(
                  label: 'Nom',
                  controller: _nomCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Nom requis (min. 2 caractères)' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Prénom',
                  controller: _prenomCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Prénom requis' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Téléphone',
                  controller: _telCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-()]'))],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _zoneSelectionnee,
                  hint: const Text('Zone géographique'),
                  decoration: const InputDecoration(
                    labelText: 'Zone géographique',
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  ),
                  items: AppConstants.villesSenegal
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _zoneSelectionnee = v),
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Ville / Village',
                  controller: _villeCtrl,
                  prefixIcon: Icons.home_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Adresse',
                  controller: _adresseCtrl,
                  prefixIcon: Icons.map_outlined,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Enregistrer',
                  onPressed: _save,
                  isLoading: _isLoading,
                  icon: Icons.save_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets utilitaires ───────────────────────────────────────────────────

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
      title: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: onTap,
      dense: true,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          const Text('Impossible de charger le profil'),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}
