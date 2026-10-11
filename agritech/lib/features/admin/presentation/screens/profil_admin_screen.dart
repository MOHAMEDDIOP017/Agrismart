import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/admin_provider.dart';
import '../widgets/kpi_admin_card.dart';

/// Écran de profil de l'Administrateur connecté — affichage + édition inline
class ProfilAdminScreen extends ConsumerStatefulWidget {
  const ProfilAdminScreen({super.key});

  @override
  ConsumerState<ProfilAdminScreen> createState() => _ProfilAdminScreenState();
}

class _ProfilAdminScreenState extends ConsumerState<ProfilAdminScreen> {
  static const Color _adminPrimary = Color(0xFF534AB7);
  static const Color _adminDark = Color(0xFF3D3491);

  bool _enEdition = false;
  bool _enChargement = false;

  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  void _entrerEdition() {
    final admin = ref.read(adminConnecteProvider);
    if (admin == null) return;
    _prenomCtrl.text = admin.prenom;
    _nomCtrl.text = admin.nom;
    _telCtrl.text = admin.telephone;
    setState(() => _enEdition = true);
  }

  void _annulerEdition() => setState(() => _enEdition = false);

  Future<void> _sauvegarder() async {
    final admin = ref.read(adminConnecteProvider);
    if (admin == null) return;

    final prenom = _prenomCtrl.text.trim();
    final nom = _nomCtrl.text.trim();
    final telephone = _telCtrl.text.trim();

    if (prenom.isEmpty || nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prénom et nom sont requis'),
          backgroundColor: context.couleurs.erreur,
        ),
      );
      return;
    }

    setState(() => _enChargement = true);

    final mis = admin.copyWith(
      prenom: prenom,
      nom: nom,
      telephone: telephone,
    );

    final ok = await ref
        .read(gestionUtilisateursProvider.notifier)
        .modifierUtilisateur(mis);

    if (!mounted) return;
    setState(() {
      _enChargement = false;
      if (ok) _enEdition = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Profil mis à jour avec succès'
            : 'Erreur lors de la sauvegarde'),
        backgroundColor:
            ok ? context.couleurs.primaire : context.couleurs.erreur,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminConnecteProvider);
    if (admin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final statsAsync = ref.watch(statistiquesProvider);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      body: CustomScrollView(
        slivers: [
          // ── En-tête avec avatar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _adminPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (!_enEdition)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Modifier le profil',
                  onPressed: _entrerEdition,
                )
              else ...[
                TextButton(
                  onPressed: _annulerEdition,
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.white70)),
                ),
                _enChargement
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: _sauvegarder,
                        child: const Text('Enregistrer',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
              ],
            ],
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
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          ((admin.prenom.isNotEmpty
                                      ? admin.prenom[0]
                                      : admin.email.isNotEmpty
                                          ? admin.email[0]
                                          : 'A')
                                  .toUpperCase()) +
                              (admin.nom.isNotEmpty
                                  ? admin.nom[0].toUpperCase()
                                  : ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
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
                  // ── Statistiques Admin ─────────────────────────────
                  Text(
                    'Mes statistiques',
                    style: AppTypography.textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  statsAsync.when(
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Impossible de charger les statistiques',
                          style: TextStyle(
                              color: context.couleurs.texteSecondaire),
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
                            couleur: context.couleurs.secondaire,
                          ),
                          KpiAdminCard(
                            titre: 'Interventions',
                            valeur: '${s.totalInterventions}',
                            icone: Icons.engineering_outlined,
                            couleur: context.couleurs.info,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Informations du compte ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Informations du compte',
                          style: AppTypography.textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_enEdition)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _adminPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Mode édition',
                            style: TextStyle(
                              color: _adminPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _enEdition
                      ? _FormulaireEdition(
                          prenomCtrl: _prenomCtrl,
                          nomCtrl: _nomCtrl,
                          telCtrl: _telCtrl,
                          email: admin.email,
                        )
                      : _CarteInfo(
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
                              valeur: admin.telephone.isNotEmpty
                                  ? admin.telephone
                                  : '—',
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

                  // ── Paramètres ─────────────────────────────────────
                  if (!_enEdition) ...[
                    Text(
                      'Paramètres',
                      style: AppTypography.textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w700),
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

                    // ── Déconnexion ──────────────────────────────────
                    _CarteInfo(
                      enfants: [
                        _TileLigne(
                          icone: Icons.logout,
                          label: 'Déconnexion',
                          couleur: context.couleurs.erreur,
                          onTap: () => _confirmerDeconnexion(context, ref),
                        ),
                      ],
                    ),
                  ],

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
          color: context.couleurs.primaire.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            Icon(Icons.agriculture, color: context.couleurs.primaire, size: 32),
      ),
      children: const [
        Text(
          'AgriSmart est une application mobile d\'assistance agricole '
          'intelligente dédiée à l\'Afrique subsaharienne.',
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
              backgroundColor: context.couleurs.erreur,
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

// ── Formulaire d'édition inline ──────────────────────────────────────────

class _FormulaireEdition extends StatelessWidget {
  const _FormulaireEdition({
    required this.prenomCtrl,
    required this.nomCtrl,
    required this.telCtrl,
    required this.email,
  });

  final TextEditingController prenomCtrl;
  final TextEditingController nomCtrl;
  final TextEditingController telCtrl;
  final String email;

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _adminPrimary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ChampEdition(
                    ctrl: prenomCtrl,
                    label: 'Prénom',
                    icone: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChampEdition(
                    ctrl: nomCtrl,
                    label: 'Nom',
                    icone: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Email — lecture seule
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Email (lecture seule)',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: context.couleurs.bordure.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                email,
                style: AppTypography.textTheme.bodyMedium!
                    .copyWith(color: context.couleurs.texteSecondaire),
              ),
            ),
            const SizedBox(height: 12),
            _ChampEdition(
              ctrl: telCtrl,
              label: 'Téléphone',
              icone: Icons.phone_outlined,
              clavier: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampEdition extends StatelessWidget {
  const _ChampEdition({
    required this.ctrl,
    required this.label,
    required this.icone,
    this.clavier,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icone;
  final TextInputType? clavier;

  static const Color _adminPrimary = Color(0xFF534AB7);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: clavier,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _adminPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ── Widgets locaux (affichage) ───────────────────────────────────────────

class _CarteInfo extends StatelessWidget {
  const _CarteInfo({required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.couleurs.bordure),
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
          color: context.couleurs.bordure,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, size: 18, color: context.couleurs.texteSecondaire),
      ),
      title: Text(
        label,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: context.couleurs.texteSecondaire,
          fontSize: 11,
        ),
      ),
      subtitle: Text(
        valeur,
        style: AppTypography.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: context.couleurs.textePrincipal,
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
    final c = couleur ?? context.couleurs.textePrincipal;
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
          color: context.couleurs.bordure,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icone,
            size: 18, color: context.couleurs.texteSecondaire),
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
