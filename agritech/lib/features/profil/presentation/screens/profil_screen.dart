import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../providers/profil_provider.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/theme/app_radius.dart';

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
              backgroundColor: context.couleurs.erreur,
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
          final ok = await ref.read(profilProvider.notifier).mettreAJour(
                nom: nom,
                prenom: prenom,
                telephone: tel,
                adresse: adresse,
                villageVille: ville,
                zoneGeographique: zone,
              );
          if (!context.mounted) return;
          if (ok) {
            RetourAction.succes(context, 'Profil mis à jour');
          } else {
            RetourAction.echec(context, null);
          }
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
        loading: () => const SqueletteListe.champs(nombre: 5),
        error: (e, _) =>
            _ErrorView(onRetry: ref.read(profilProvider.notifier).rafraichir),
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
                  backgroundColor: context.couleurs.primaireFonce,
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
                          decoration: BoxDecoration(
                            gradient: context.couleurs.degradePrimaire,
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
                                        child: Icon(
                                          Icons.camera_alt_rounded,
                                          size: 16,
                                          color: context.couleurs.primaire,
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
                    ),

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
                    _SettingsTile(
                      icon: Icons.language_outlined,
                      label: 'Langue',
                      trailing: Text(
                        'Français',
                        style:
                            TextStyle(color: context.couleurs.texteSecondaire),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'À propos de AgriSmart',
                      onTap: () => _showAbout(context),
                    ),

                    const SizedBox(height: 16),

                    // ─── Déconnexion ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: Icon(Icons.logout_rounded,
                            color: context.couleurs.erreur),
                        label: Text(
                          'Se déconnecter',
                          style: TextStyle(color: context.couleurs.erreur),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.couleurs.erreur),
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
                gradient: context.couleurs.degradePrimaire,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
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
          color: context.couleurs.primaire,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.psychology_rounded,
          label: 'Recommandations',
          value: '$nbRecommandations',
          color: context.couleurs.secondaire,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'Membre depuis',
          value: dateInscription != null
              ? DateFormatter.formatMonthYear(dateInscription!)
              : '—',
          color: context.couleurs.info,
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
                  ?.copyWith(color: context.couleurs.texteSecondaire),
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
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: AppRayons.brFeuille,
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
                      color: context.couleurs.bordure,
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

                AppChampTexte(
                  libelle: 'Nom',
                  controleur: _nomCtrl,
                  icone: Icons.person_outline,
                  validateur: (v) => (v == null || v.trim().length < 2)
                      ? 'Nom requis (min. 2 caractères)'
                      : null,
                  actionClavier: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                AppChampTexte(
                  libelle: 'Prénom',
                  controleur: _prenomCtrl,
                  icone: Icons.person_outline,
                  validateur: (v) => (v == null || v.trim().length < 2)
                      ? 'Prénom requis'
                      : null,
                  actionClavier: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                AppChampTexte(
                  libelle: 'Téléphone',
                  controleur: _telCtrl,
                  icone: Icons.phone_outlined,
                  clavier: TextInputType.phone,
                  formateurs: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s+\-()]'))
                  ],
                  validateur: (v) => (v == null || v.trim().isEmpty)
                      ? 'Téléphone requis'
                      : null,
                  actionClavier: TextInputAction.next,
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

                AppChampTexte(
                  libelle: 'Ville / Village',
                  controleur: _villeCtrl,
                  icone: Icons.home_outlined,
                  actionClavier: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                AppChampTexte(
                  libelle: 'Adresse',
                  controleur: _adresseCtrl,
                  icone: Icons.map_outlined,
                  actionClavier: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                AppBouton.principal(
                  libelle: 'Enregistrer',
                  onPressed: _save,
                  icone: Icons.save_rounded,
                  enChargement: _isLoading,
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
              color: context.couleurs.texteSecondaire,
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
      leading: Icon(icon, color: context.couleurs.primaire, size: 22),
      title: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: context.couleurs.texteSecondaire),
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
      leading: Icon(icon, color: context.couleurs.texteSecondaire, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              color: context.couleurs.texteSecondaire),
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
          Icon(Icons.error_outline, color: context.couleurs.erreur, size: 48),
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
