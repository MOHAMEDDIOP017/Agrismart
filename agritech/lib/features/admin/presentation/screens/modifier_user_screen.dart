import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/utilisateur_admin_entity.dart';
import '../../domain/enums/statut_utilisateur.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_form_helpers.dart';

/// Formulaire de modification d'un utilisateur existant
class ModifierUserScreen extends ConsumerStatefulWidget {
  const ModifierUserScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ModifierUserScreen> createState() =>
      _ModifierUserScreenState();
}

class _ModifierUserScreenState extends ConsumerState<ModifierUserScreen> {
  static const Color _adminPrimary = Color(0xFF534AB7);
  static const List<String> _regions = [
    'Dakar', 'Thiès', 'Kaolack', 'Saint-Louis', 'Ziguinchor',
    'Tambacounda', 'Diourbel', 'Louga', 'Fatick', 'Kaffrine',
    'Kédougou', 'Kolda', 'Matam', 'Sédhiou',
  ];

  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();

  UtilisateurAdminEntity? _utilisateur;
  String? _regionSelectionnee;
  RoleUtilisateur? _roleSelectionne;
  bool _compteActif = true;
  bool _enChargement = false;
  bool _initialise = false;

  @override
  void dispose() {
    for (final c in [
      _prenomCtrl, _nomCtrl, _emailCtrl, _telCtrl, _villeCtrl, _mdpCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initialiserDepuis(UtilisateurAdminEntity u) {
    if (_initialise) return;
    _prenomCtrl.text = u.prenom;
    _nomCtrl.text = u.nom;
    _emailCtrl.text = u.email;
    _telCtrl.text = u.telephone;
    _villeCtrl.text = u.ville ?? '';
    _regionSelectionnee = u.region;
    _roleSelectionne = u.role;
    _compteActif = u.statut == StatutUtilisateur.actif;
    _utilisateur = u;
    _initialise = true;
  }

  Future<void> _confirmerChangementRole(RoleUtilisateur nouveauRole) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer le rôle ?'),
        content: Text(
          'Le rôle de ${_utilisateur?.nomComplet ?? "cet utilisateur"} '
          'sera changé en "${nouveauRole.libelle}".\n\n'
          'L\'utilisateur devra se reconnecter pour que le changement prenne effet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF534AB7),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirme != true || _utilisateur == null) {
      setState(() => _roleSelectionne = _utilisateur?.role);
      return;
    }
    setState(() => _enChargement = true);
    final ok = await ref
        .read(gestionUtilisateursProvider.notifier)
        .changerRole(_utilisateur!.id, nouveauRole);
    setState(() {
      _enChargement = false;
      if (ok) {
        _utilisateur = _utilisateur!.copyWith(role: nouveauRole);
      } else {
        _roleSelectionne = _utilisateur?.role;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Rôle changé avec succès' : 'Erreur lors du changement de rôle'),
          backgroundColor: ok ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate() || _utilisateur == null) return;
    setState(() => _enChargement = true);

    final mis = _utilisateur!.copyWith(
      prenom: _prenomCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      region: _regionSelectionnee ?? _utilisateur!.region,
      ville: _villeCtrl.text.trim(),
      statut: _compteActif
          ? StatutUtilisateur.actif
          : StatutUtilisateur.suspendu,
    );

    final ok = await ref
        .read(gestionUtilisateursProvider.notifier)
        .modifierUtilisateur(mis);

    setState(() => _enChargement = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${mis.nomComplet} mis à jour avec succès'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmerSuppression() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer définitivement ?'),
        content: const Text(
          'Cette action est irréversible. L\'utilisateur sera supprimé de la plateforme.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme == true && mounted) {
      await ref
          .read(gestionUtilisateursProvider.notifier)
          .supprimerUtilisateur(widget.userId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateurAsync =
        ref.watch(utilisateurDetailProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: Text(
          utilisateurAsync.valueOrNull != null
              ? 'Modifier ${utilisateurAsync.valueOrNull!.prenom}'
              : 'Modifier utilisateur',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: utilisateurAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (utilisateur) {
          _initialiserDepuis(utilisateur);
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Identité ───────────────────────────────────
                  const AdminSectionTitre(
                      titre: 'Identité', icone: Icons.person_outline),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prenomCtrl,
                          decoration:
                              adminDecorChamp('Prénom', Icons.badge_outlined),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nomCtrl,
                          decoration:
                              adminDecorChamp('Nom', Icons.badge_outlined),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        adminDecorChamp('Email', Icons.email_outlined),
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        adminDecorChamp('Téléphone', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 12),
                  // Mot de passe optionnel
                  TextFormField(
                    controller: _mdpCtrl,
                    obscureText: true,
                    decoration: adminDecorChamp(
                      'Nouveau mot de passe (laisser vide = inchangé)',
                      Icons.lock_outline,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Localisation ──────────────────────────────
                  const AdminSectionTitre(
                    titre: 'Localisation',
                    icone: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _regionSelectionnee,
                    decoration:
                        adminDecorChamp('Région', Icons.map_outlined),
                    items: _regions
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _regionSelectionnee = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _villeCtrl,
                    decoration: adminDecorChamp(
                        'Ville / Village', Icons.location_city_outlined),
                  ),

                  const SizedBox(height: 24),

                  // ── Rôle ─────────────────────────────────────
                  const AdminSectionTitre(
                      titre: 'Rôle', icone: Icons.manage_accounts_outlined),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RoleUtilisateur>(
                    value: _roleSelectionne,
                    decoration: adminDecorChamp('Rôle', Icons.badge_outlined),
                    items: RoleUtilisateur.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.libelle),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null && v != _roleSelectionne) {
                        setState(() => _roleSelectionne = v);
                        _confirmerChangementRole(v);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Actions compte ────────────────────────────
                  const AdminSectionTitre(
                      titre: 'Statut du compte',
                      icone: Icons.settings_outlined),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Compte actif'),
                          subtitle: Text(
                            _compteActif
                                ? 'L\'utilisateur peut se connecter'
                                : 'Compte suspendu',
                          ),
                          value: _compteActif,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _compteActif = v),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_outlined,
                              color: AppColors.danger),
                          title: const Text(
                            'Supprimer définitivement',
                            style: TextStyle(color: AppColors.danger),
                          ),
                          onTap: _confirmerSuppression,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Bouton enregistrer ─────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _enChargement ? null : _soumettre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _adminPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _enChargement
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
