import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_form_helpers.dart';

/// Formulaire de création d'un nouvel utilisateur
class CreerUserScreen extends ConsumerStatefulWidget {
  const CreerUserScreen({super.key});

  @override
  ConsumerState<CreerUserScreen> createState() => _CreerUserScreenState();
}

class _CreerUserScreenState extends ConsumerState<CreerUserScreen> {
  static const Color _adminPrimary = Color(0xFF534AB7);
  static const List<String> _regions = [
    'Dakar',
    'Thiès',
    'Kaolack',
    'Saint-Louis',
    'Ziguinchor',
    'Tambacounda',
    'Diourbel',
    'Louga',
    'Fatick',
    'Kaffrine',
    'Kédougou',
    'Kolda',
    'Matam',
    'Sédhiou',
  ];

  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _zoneGeoCtrl = TextEditingController();

  RoleUtilisateur _role = RoleUtilisateur.agriculteur;
  String? _regionSelectionnee;
  String? _specialiteSelectionnee;
  int _anneesExperience = 1;
  double _niveauAcces = 1;
  bool _afficherMdp = false;
  bool _afficherConfirm = false;
  bool _enChargement = false;

  @override
  void dispose() {
    for (final c in [
      _prenomCtrl,
      _nomCtrl,
      _emailCtrl,
      _telCtrl,
      _mdpCtrl,
      _confirmMdpCtrl,
      _villeCtrl,
      _zoneGeoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enChargement = true);

    final erreur = await ref
        .read(gestionUtilisateursProvider.notifier)
        .creerUtilisateur(
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _telCtrl.text.trim(),
          motDePasse: _mdpCtrl.text,
          role: _role,
          region: _regionSelectionnee ?? '',
          ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
          specialite:
              _role == RoleUtilisateur.expert ? _specialiteSelectionnee : null,
          anneesExperience:
              _role == RoleUtilisateur.expert ? _anneesExperience : null,
          niveauAcces:
              _role == RoleUtilisateur.admin ? _niveauAcces.toInt() : null,
        );

    setState(() => _enChargement = false);
    if (!mounted) return;

    if (erreur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Utilisateur ${_prenomCtrl.text} ${_nomCtrl.text} créé avec succès',
          ),
          backgroundColor: context.couleurs.primaire,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erreur),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Créer un utilisateur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Identité ────────────────────────────────────────
              const AdminSectionTitre(
                  titre: 'Identité', icone: Icons.person_outline),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Champ(
                      ctrl: _prenomCtrl,
                      label: 'Prénom',
                      icone: Icons.badge_outlined,
                      validateur: (v) =>
                          v!.trim().isEmpty ? 'Champ requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Champ(
                      ctrl: _nomCtrl,
                      label: 'Nom',
                      icone: Icons.badge_outlined,
                      validateur: (v) =>
                          v!.trim().isEmpty ? 'Champ requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Champ(
                ctrl: _emailCtrl,
                label: 'Email',
                icone: Icons.email_outlined,
                clavier: TextInputType.emailAddress,
                validateur: (v) {
                  if (v!.trim().isEmpty) return 'Champ requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _Champ(
                ctrl: _telCtrl,
                label: 'Téléphone (+221XXXXXXXX)',
                icone: Icons.phone_outlined,
                clavier: TextInputType.phone,
                validateur: (v) {
                  if (v!.trim().isEmpty) return 'Champ requis';
                  if (!v.startsWith('+221')) return 'Format : +221XXXXXXXX';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _ChampMdp(
                ctrl: _mdpCtrl,
                label: 'Mot de passe',
                afficher: _afficherMdp,
                onToggle: () => setState(() => _afficherMdp = !_afficherMdp),
                validateur: (v) {
                  if (v!.isEmpty) return 'Champ requis';
                  if (v.length < 8) return 'Minimum 8 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _ChampMdp(
                ctrl: _confirmMdpCtrl,
                label: 'Confirmer le mot de passe',
                afficher: _afficherConfirm,
                onToggle: () =>
                    setState(() => _afficherConfirm = !_afficherConfirm),
                validateur: (v) {
                  if (v != _mdpCtrl.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── Rôle ────────────────────────────────────────────
              const AdminSectionTitre(
                  titre: 'Rôle', icone: Icons.admin_panel_settings_outlined),
              const SizedBox(height: 12),
              SegmentedButton<RoleUtilisateur>(
                segments: const [
                  ButtonSegment(
                    value: RoleUtilisateur.agriculteur,
                    label: Text('Agriculteur'),
                    icon: Icon(Icons.agriculture_outlined),
                  ),
                  ButtonSegment(
                    value: RoleUtilisateur.expert,
                    label: Text('Expert'),
                    icon: Icon(Icons.verified_user_outlined),
                  ),
                  ButtonSegment(
                    value: RoleUtilisateur.admin,
                    label: Text('Admin'),
                    icon: Icon(Icons.shield_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _adminPrimary;
                    }
                    return null;
                  }),
                ),
              ),

              // ── Champs spécifiques au rôle ───────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _ChampsRoleSpecifiques(
                  role: _role,
                  zoneGeoCtrl: _zoneGeoCtrl,
                  specialite: _specialiteSelectionnee,
                  onSpecialiteChange: (v) =>
                      setState(() => _specialiteSelectionnee = v),
                  anneesExperience: _anneesExperience,
                  onAnneesChange: (v) => setState(() => _anneesExperience = v),
                  niveauAcces: _niveauAcces,
                  onNiveauChange: (v) => setState(() => _niveauAcces = v),
                ),
              ),

              const SizedBox(height: 24),

              // ── Localisation ────────────────────────────────────
              const AdminSectionTitre(
                  titre: 'Localisation', icone: Icons.location_on_outlined),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _regionSelectionnee,
                decoration:
                    adminDecorChamp(context, 'Région', Icons.map_outlined),
                hint: const Text('Sélectionner une région'),
                items: _regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _regionSelectionnee = v),
                validator: (v) =>
                    v == null ? 'Veuillez sélectionner une région' : null,
              ),
              const SizedBox(height: 12),
              _Champ(
                ctrl: _villeCtrl,
                label: 'Ville / Village',
                icone: Icons.location_city_outlined,
              ),

              const SizedBox(height: 32),

              // ── Bouton créer ─────────────────────────────────────
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
                          'Créer l\'utilisateur',
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
      ),
    );
  }
}

// ── Widgets utilitaires du formulaire ────────────────────────────────────

class _Champ extends StatelessWidget {
  const _Champ({
    required this.ctrl,
    required this.label,
    required this.icone,
    this.clavier,
    this.validateur,
    this.optionnel = false,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icone;
  final TextInputType? clavier;
  final String? Function(String?)? validateur;
  final bool optionnel;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: clavier,
      decoration: adminDecorChamp(context, label, icone),
      validator: validateur,
    );
  }
}

class _ChampMdp extends StatelessWidget {
  const _ChampMdp({
    required this.ctrl,
    required this.label,
    required this.afficher,
    required this.onToggle,
    required this.validateur,
  });

  final TextEditingController ctrl;
  final String label;
  final bool afficher;
  final VoidCallback onToggle;
  final String? Function(String?)? validateur;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: !afficher,
      decoration: adminDecorChamp(context, label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            afficher ? Icons.visibility_off : Icons.visibility,
            color: context.couleurs.texteSecondaire,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validateur,
    );
  }
}

/// Champs supplémentaires selon le rôle sélectionné
class _ChampsRoleSpecifiques extends StatelessWidget {
  const _ChampsRoleSpecifiques({
    required this.role,
    required this.zoneGeoCtrl,
    required this.specialite,
    required this.onSpecialiteChange,
    required this.anneesExperience,
    required this.onAnneesChange,
    required this.niveauAcces,
    required this.onNiveauChange,
  });

  final RoleUtilisateur role;
  final TextEditingController zoneGeoCtrl;
  final String? specialite;
  final ValueChanged<String?> onSpecialiteChange;
  final int anneesExperience;
  final ValueChanged<int> onAnneesChange;
  final double niveauAcces;
  final ValueChanged<double> onNiveauChange;

  static const List<String> _specialites = [
    'Phytopathologie',
    'Agronomie tropicale',
    'Entomologie',
    'Pédologie',
    'Riziculture',
    'Maraîchage',
    'Arboriculture',
    'Élevage',
  ];

  @override
  Widget build(BuildContext context) {
    if (role == RoleUtilisateur.agriculteur) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: _Champ(
          ctrl: zoneGeoCtrl,
          label: 'Zone géographique / Adresse',
          icone: Icons.location_on_outlined,
          optionnel: true,
        ),
      );
    }
    if (role == RoleUtilisateur.expert) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: specialite,
              decoration: adminDecorChamp(
                  context, 'Spécialité', Icons.science_outlined),
              hint: const Text('Choisir une spécialité'),
              items: _specialites
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: onSpecialiteChange,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.work_history_outlined,
                    size: 18, color: context.couleurs.texteSecondaire),
                const SizedBox(width: 8),
                Text(
                  'Années d\'expérience : $anneesExperience',
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ],
            ),
            Slider(
              value: anneesExperience.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$anneesExperience ans',
              activeColor: const Color(0xFF534AB7),
              onChanged: (v) => onAnneesChange(v.toInt()),
            ),
          ],
        ),
      );
    }
    // Admin
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_outlined,
                  size: 18, color: context.couleurs.texteSecondaire),
              const SizedBox(width: 8),
              Text(
                'Niveau d\'accès : ${niveauAcces.toInt()}',
                style: AppTypography.textTheme.bodyMedium,
              ),
            ],
          ),
          Slider(
            value: niveauAcces,
            min: 1,
            max: 3,
            divisions: 2,
            label: 'Niveau ${niveauAcces.toInt()}',
            activeColor: const Color(0xFF534AB7),
            onChanged: onNiveauChange,
          ),
        ],
      ),
    );
  }
}
