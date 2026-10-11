import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/auth/deconnexion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expert_entity.dart';
import '../providers/expert_provider.dart';
import '../widgets/animated_counter.dart';
import '../../../../shared/widgets/widgets.dart';

/// Profil de l'expert avec mode édition (nom, prénom, téléphone)
class ProfilExpertScreen extends ConsumerStatefulWidget {
  const ProfilExpertScreen({super.key});

  @override
  ConsumerState<ProfilExpertScreen> createState() => _ProfilExpertScreenState();
}

class _ProfilExpertScreenState extends ConsumerState<ProfilExpertScreen> {
  bool _notificationsActives = true;
  bool _editMode = false;
  bool _enSauvegarde = false;

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

  void _entrerEdition(ExpertEntity expert) {
    _prenomCtrl.text = expert.prenom;
    _nomCtrl.text = expert.nom;
    _telCtrl.text = expert.telephone;
    setState(() => _editMode = true);
  }

  Future<void> _sauvegarder(ExpertEntity expert) async {
    final prenom = _prenomCtrl.text.trim();
    final nom = _nomCtrl.text.trim();
    final tel = _telCtrl.text.trim();

    if (prenom.isEmpty || nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le prénom et le nom sont obligatoires.'),
          backgroundColor: context.couleurs.erreur,
        ),
      );
      return;
    }

    setState(() => _enSauvegarde = true);

    try {
      await ref.read(profilExpertProvider.notifier).updateProfil(
            expert.copyWith(prenom: prenom, nom: nom, telephone: tel),
          );
      if (mounted) {
        setState(() {
          _editMode = false;
          _enSauvegarde = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour.',
                style: AppTypography.police(color: Colors.white)),
            backgroundColor: context.couleurs.primaire,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _enSauvegarde = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la sauvegarde.'),
            backgroundColor: context.couleurs.erreur,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilExpertProvider);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(profilExpertProvider),
        ),
        data: (expert) => CustomScrollView(
          slivers: [
            // ── En-tête ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: context.couleurs.primaireFonce,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: context.couleurs.primaireFonce,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
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
                                style: AppTypography.police(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: context.couleurs.secondaire,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(expert.nomComplet,
                          style: AppTypography.police(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(
                        '${expert.specialite.libelle} · ${expert.regionCouverture}',
                        style: AppTypography.police(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (_enSauvegarde)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                else if (_editMode) ...[
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() => _editMode = false),
                    tooltip: 'Annuler',
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: () => _sauvegarder(expert),
                    tooltip: 'Sauvegarder',
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => _entrerEdition(expert),
                    tooltip: 'Modifier le profil',
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
                  _editMode
                      ? _FormulaireEdition(
                          prenomCtrl: _prenomCtrl,
                          nomCtrl: _nomCtrl,
                          telCtrl: _telCtrl,
                          email: expert.email,
                        )
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: context.couleurs.bordure),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                _infoRow(Icons.person_outline, 'Nom complet',
                                    expert.nomComplet),
                                _infoRow(Icons.email_outlined, 'Email',
                                    expert.email),
                                _infoRow(Icons.phone_outlined, 'Téléphone',
                                    expert.telephone),
                                _infoRow(Icons.location_on_outlined, 'Région',
                                    expert.regionCouverture),
                                _infoRow(Icons.science_outlined, 'Spécialité',
                                    expert.specialite.libelle),
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
                      _statCard(
                          'Interventions réalisées',
                          expert.nombreInterventions,
                          context.couleurs.primaire),
                      _statCard(
                          'Corrections apportées',
                          expert.nombreCorrections,
                          context.couleurs.secondaire),
                      _statCard('Interventions réalisées',
                          expert.nombreInterventions, context.couleurs.info),
                      _statCard('Conseils envoyés', expert.nombreConseils,
                          context.couleurs.alerteElevee),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.couleurs.primaire.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              context.couleurs.primaire.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Taux de précision IA corrigée',
                            style: AppTypography.police(
                                fontSize: 13,
                                color: context.couleurs.texteSecondaire)),
                        Text(expert.tauxPrecisionFormate,
                            style: AppTypography.police(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: context.couleurs.primaire)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Paramètres ────────────────────────────────
                  _sectionTitle('Paramètres'),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: context.couleurs.bordure),
                    ),
                    child: Column(
                      children: [
                        _paramTile(
                          Icons.notifications_outlined,
                          'Notifications',
                          trailing: Switch.adaptive(
                            value: _notificationsActives,
                            activeColor: context.couleurs.primaire,
                            onChanged: (v) =>
                                setState(() => _notificationsActives = v),
                          ),
                        ),
                        const Divider(height: 1),
                        _paramTile(Icons.language_outlined, 'Langue',
                            trailing: Text('Français',
                                style: AppTypography.police(
                                    fontSize: 12,
                                    color: context.couleurs.texteSecondaire))),
                        const Divider(height: 1),
                        _paramTile(Icons.info_outline, 'À propos',
                            trailing: Icon(Icons.chevron_right,
                                color: context.couleurs.texteSecondaire),
                            onTap: () {}),
                        const Divider(height: 1),
                        _paramTile(
                          Icons.logout_outlined,
                          'Déconnexion',
                          couleur: context.couleurs.erreur,
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
        style: AppTypography.police(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.couleurs.textePrincipal),
      );

  Widget _infoRow(IconData icon, String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.couleurs.texteSecondaire),
            const SizedBox(width: 8),
            Text('$label : ',
                style: AppTypography.police(
                    fontSize: 12, color: context.couleurs.texteSecondaire)),
            Expanded(
              child: Text(valeur,
                  style: AppTypography.police(
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
              style: AppTypography.police(
                  fontSize: 22, fontWeight: FontWeight.bold, color: couleur),
            ),
            Text(label,
                style: AppTypography.police(
                    fontSize: 11, color: context.couleurs.texteSecondaire),
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
        leading: Icon(icon,
            color: couleur ?? context.couleurs.texteSecondaire, size: 20),
        title: Text(label,
            style: AppTypography.police(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: couleur ?? context.couleurs.textePrincipal)),
        trailing: trailing,
        onTap: onTap,
      );

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Déconnexion',
            style: AppTypography.police(fontWeight: FontWeight.bold)),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: AppTypography.police(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler',
                style: AppTypography.police(
                    color: context.couleurs.texteSecondaire)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DeconnexionService.deconnecter(ref);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: context.couleurs.erreur),
            child: Text('Déconnexion',
                style: AppTypography.police(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Formulaire d'édition ────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.couleurs.primaire, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ChampEdition(
                      label: 'Prénom',
                      controller: prenomCtrl,
                      icone: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChampEdition(
                      label: 'Nom',
                      controller: nomCtrl,
                      icone: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Email en lecture seule
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Email (non modifiable)',
                  prefixIcon: Icon(Icons.email_outlined,
                      size: 18, color: context.couleurs.texteSecondaire),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.couleurs.bordure),
                  ),
                  filled: true,
                  fillColor: context.couleurs.fond,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Text(email,
                    style: AppTypography.police(
                        fontSize: 13, color: context.couleurs.texteSecondaire)),
              ),
              const SizedBox(height: 12),
              _ChampEdition(
                label: 'Téléphone',
                controller: telCtrl,
                icone: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      );
}

class _ChampEdition extends StatelessWidget {
  const _ChampEdition({
    required this.label,
    required this.controller,
    required this.icone,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final IconData icone;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: AppTypography.police(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.police(
              fontSize: 12, color: context.couleurs.texteSecondaire),
          prefixIcon:
              Icon(icone, size: 18, color: context.couleurs.texteSecondaire),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.couleurs.bordure),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: context.couleurs.primaireFonce, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}
