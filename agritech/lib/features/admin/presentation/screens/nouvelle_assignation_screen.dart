import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assignation_entity.dart';
import '../providers/admin_provider.dart';
import '../widgets/expert_selection_card_admin.dart';
import '../../../../shared/widgets/widgets.dart';

/// Formulaire de création d'une nouvelle assignation (Stepper 3 étapes)
class NouvelleAssignationScreen extends ConsumerStatefulWidget {
  const NouvelleAssignationScreen({super.key});

  @override
  ConsumerState<NouvelleAssignationScreen> createState() =>
      _NouvelleAssignationScreenState();
}

class _NouvelleAssignationScreenState
    extends ConsumerState<NouvelleAssignationScreen> {
  static const Color _adminPrimary = Color(0xFF534AB7);

  int _etape = 0;
  AssignationEntity? _interventionSelectionnee;
  ExpertDisponibleEntity? _expertSelectionne;
  DateTime? _dateSouhaitee;
  final _messageCtrl = TextEditingController();
  bool _notifier = true;
  bool _enChargement = false;
  bool _succes = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_succes) return _EcranSucces(onRetour: () => Navigator.pop(context));

    final assignationsAsync = ref.watch(assignationProvider);
    final expertsAsync = ref.watch(expertsDisponiblesProvider(null));

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Nouvelle assignation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Indicateur d'étapes
          _IndicateurEtapes(etapeCourante: _etape),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _etape == 0
                  ? _EtapeIntervention(
                      assignationsAsync: assignationsAsync,
                      selectionne: _interventionSelectionnee,
                      onSelectionner: (a) =>
                          setState(() => _interventionSelectionnee = a),
                    )
                  : _etape == 1
                      ? _EtapeExpert(
                          expertsAsync: expertsAsync,
                          selectionne: _expertSelectionne,
                          onSelectionner: (e) =>
                              setState(() => _expertSelectionne = e),
                        )
                      : _EtapeConfirmation(
                          intervention: _interventionSelectionnee!,
                          expert: _expertSelectionne!,
                          dateSouhaitee: _dateSouhaitee,
                          onDateChange: (d) =>
                              setState(() => _dateSouhaitee = d),
                          messageCtrl: _messageCtrl,
                          notifier: _notifier,
                          onNotifierChange: (v) =>
                              setState(() => _notifier = v),
                        ),
            ),
          ),
          // Navigation entre étapes
          _BoutonNavigationEtapes(
            etape: _etape,
            peutSuivre: _peutSuivre(),
            enChargement: _enChargement,
            onRetour: () => setState(() => _etape--),
            onSuivant: () => setState(() => _etape++),
            onConfirmer: _confirmer,
          ),
        ],
      ),
    );
  }

  bool _peutSuivre() {
    if (_etape == 0) return _interventionSelectionnee != null;
    if (_etape == 1) return _expertSelectionne != null;
    return _dateSouhaitee != null;
  }

  Future<void> _confirmer() async {
    if (_interventionSelectionnee == null ||
        _expertSelectionne == null ||
        _dateSouhaitee == null) {
      return;
    }

    setState(() => _enChargement = true);

    final ok = await ref.read(assignationProvider.notifier).creerAssignation(
          interventionId: _interventionSelectionnee!.id,
          expertId: _expertSelectionne!.id,
          dateSouhaitee: _dateSouhaitee!,
          messageExpert: _messageCtrl.text.trim().isEmpty
              ? null
              : _messageCtrl.text.trim(),
          notifierExpert: _notifier,
        );

    setState(() {
      _enChargement = false;
      _succes = ok;
    });
  }
}

// ── Étapes ────────────────────────────────────────────────────────────────

class _EtapeIntervention extends StatelessWidget {
  const _EtapeIntervention({
    required this.assignationsAsync,
    required this.selectionne,
    required this.onSelectionner,
  });

  final AsyncValue<AssignationState> assignationsAsync;
  final AssignationEntity? selectionne;
  final ValueChanged<AssignationEntity> onSelectionner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionner une intervention',
          style: AppTypography.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez l\'intervention à confier à un expert.',
          style: AppTypography.textTheme.bodySmall!.copyWith(
            color: context.couleurs.texteSecondaire,
          ),
        ),
        const SizedBox(height: 16),
        assignationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // Pas de bouton « Réessayer » ici : ce bloc vit dans un widget qui
          // reçoit son état en paramètre et n'a pas accès aux providers. Le
          // rafraîchissement se fait depuis l'écran parent.
          error: (e, _) => BandeauErreur(erreur: e),
          data: (etat) {
            final nonAssignees =
                etat.assignations.where((a) => a.statut.estEnAttente).toList();
            if (nonAssignees.isEmpty) {
              return Center(
                child: Text(
                  'Aucune intervention en attente',
                  style: AppTypography.textTheme.bodyMedium!.copyWith(
                    color: context.couleurs.texteSecondaire,
                  ),
                ),
              );
            }
            return Column(
              children: nonAssignees.map((a) {
                final sel = selectionne?.id == a.id;
                return GestureDetector(
                  onTap: () => onSelectionner(a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF534AB7).withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? const Color(0xFF534AB7)
                            : context.couleurs.bordure,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: a.id,
                          groupValue: selectionne?.id,
                          onChanged: (_) => onSelectionner(a),
                          activeColor: const Color(0xFF534AB7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.agriculteurNom,
                                style: AppTypography.textTheme.titleSmall!
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${a.champNom} • ${a.region}',
                                style: AppTypography.textTheme.bodySmall!
                                    .copyWith(
                                        color:
                                            context.couleurs.texteSecondaire),
                              ),
                              Row(
                                children: [
                                  _Chip(
                                    texte: a.typeIntervention,
                                    couleur: context.couleurs.info,
                                  ),
                                  const SizedBox(width: 6),
                                  _Chip(
                                    texte: a.niveauUrgence.libelle,
                                    couleur: a.niveauUrgence.couleur,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EtapeExpert extends StatelessWidget {
  const _EtapeExpert({
    required this.expertsAsync,
    required this.selectionne,
    required this.onSelectionner,
  });

  final AsyncValue<List<ExpertDisponibleEntity>> expertsAsync;
  final ExpertDisponibleEntity? selectionne;
  final ValueChanged<ExpertDisponibleEntity> onSelectionner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionner un expert',
          style: AppTypography.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez l\'expert le plus adapté.',
          style: AppTypography.textTheme.bodySmall!
              .copyWith(color: context.couleurs.texteSecondaire),
        ),
        const SizedBox(height: 16),
        expertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => BandeauErreur(erreur: e),
          data: (experts) => Column(
            children: experts.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpertSelectionCardAdmin(
                  expert: e,
                  estSelectionne: selectionne?.id == e.id,
                  onSelectionner: () => onSelectionner(e),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _EtapeConfirmation extends StatelessWidget {
  const _EtapeConfirmation({
    required this.intervention,
    required this.expert,
    required this.dateSouhaitee,
    required this.onDateChange,
    required this.messageCtrl,
    required this.notifier,
    required this.onNotifierChange,
  });

  final AssignationEntity intervention;
  final ExpertDisponibleEntity expert;
  final DateTime? dateSouhaitee;
  final ValueChanged<DateTime> onDateChange;
  final TextEditingController messageCtrl;
  final bool notifier;
  final ValueChanged<bool> onNotifierChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmation',
          style: AppTypography.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        // Récapitulatif intervention
        _CarteRecap(
          titre: 'Intervention',
          icone: Icons.engineering_outlined,
          couleur: context.couleurs.secondaire,
          lignes: [
            'Agriculteur : ${intervention.agriculteurNom}',
            'Champ : ${intervention.champNom}',
            'Type : ${intervention.typeIntervention}',
            'Région : ${intervention.region}',
          ],
        ),
        const SizedBox(height: 12),
        // Récapitulatif expert
        _CarteRecap(
          titre: 'Expert sélectionné',
          icone: Icons.verified_user_outlined,
          couleur: const Color(0xFF534AB7),
          lignes: [
            'Nom : ${expert.nomComplet}',
            'Spécialité : ${expert.specialite}',
            'Région : ${expert.region}',
          ],
        ),
        const SizedBox(height: 16),
        // DatePicker
        Text(
          'Date souhaitée *',
          style: AppTypography.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) onDateChange(date);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dateSouhaitee != null
                    ? const Color(0xFF534AB7)
                    : context.couleurs.bordure,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Color(0xFF534AB7)),
                const SizedBox(width: 12),
                Text(
                  dateSouhaitee != null
                      ? '${dateSouhaitee!.day}/${dateSouhaitee!.month}/${dateSouhaitee!.year}'
                      : 'Choisir une date',
                  style: AppTypography.textTheme.bodyMedium!.copyWith(
                    color: dateSouhaitee != null
                        ? context.couleurs.textePrincipal
                        : context.couleurs.texteSecondaire,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Message optionnel
        TextField(
          controller: messageCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Message pour l\'expert (optionnel)',
            prefixIcon: const Icon(Icons.message_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.couleurs.bordure),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.couleurs.bordure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Switch notification
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.couleurs.bordure),
          ),
          child: SwitchListTile(
            title: const Text('Notifier l\'expert immédiatement'),
            value: notifier,
            activeColor: const Color(0xFF534AB7),
            onChanged: onNotifierChange,
          ),
        ),
      ],
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────

class _IndicateurEtapes extends StatelessWidget {
  const _IndicateurEtapes({required this.etapeCourante});

  final int etapeCourante;

  static const List<String> _etapes = [
    'Intervention',
    'Expert',
    'Confirmation',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _etapes.asMap().entries.map((e) {
          final actif = e.key == etapeCourante;
          final fait = e.key < etapeCourante;
          return Row(
            children: [
              if (e.key > 0)
                Container(
                  width: 30,
                  height: 2,
                  color:
                      fait ? const Color(0xFF534AB7) : context.couleurs.bordure,
                ),
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: actif || fait
                          ? const Color(0xFF534AB7)
                          : context.couleurs.bordure,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: fait
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                color: actif
                                    ? Colors.white
                                    : context.couleurs.texteSecondaire,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.value,
                    style: AppTypography.textTheme.labelSmall!.copyWith(
                      color: actif
                          ? const Color(0xFF534AB7)
                          : context.couleurs.texteSecondaire,
                      fontWeight: actif ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _BoutonNavigationEtapes extends StatelessWidget {
  const _BoutonNavigationEtapes({
    required this.etape,
    required this.peutSuivre,
    required this.enChargement,
    required this.onRetour,
    required this.onSuivant,
    required this.onConfirmer,
  });

  final int etape;
  final bool peutSuivre;
  final bool enChargement;
  final VoidCallback onRetour;
  final VoidCallback onSuivant;
  final VoidCallback onConfirmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: context.couleurs.bordure)),
      ),
      child: Row(
        children: [
          if (etape > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onRetour,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retour'),
              ),
            ),
          if (etape > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: peutSuivre && !enChargement
                  ? (etape == 2 ? onConfirmer : onSuivant)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: enChargement
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      etape == 2 ? 'Confirmer l\'assignation' : 'Suivant',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteRecap extends StatelessWidget {
  const _CarteRecap({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.lignes,
  });

  final String titre;
  final IconData icone;
  final Color couleur;
  final List<String> lignes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: couleur),
              const SizedBox(width: 6),
              Text(
                titre,
                style: AppTypography.textTheme.titleSmall!
                    .copyWith(color: couleur, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lignes.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l,
                style: AppTypography.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texte, required this.couleur});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texte,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: couleur,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EcranSucces extends StatelessWidget {
  const _EcranSucces({required this.onRetour});

  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.couleurs.primaire.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: context.couleurs.primaire,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Assignation créée !',
              style: AppTypography.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: context.couleurs.primaire,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'expert a été notifié de sa nouvelle intervention.',
              style: AppTypography.textTheme.bodyMedium!.copyWith(
                color: context.couleurs.texteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetour,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Retour',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
