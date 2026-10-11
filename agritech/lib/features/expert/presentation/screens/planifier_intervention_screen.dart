import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/type_intervention.dart';
import '../providers/expert_provider.dart';

/// Formulaire Stepper — planifier une intervention terrain
class PlanifierInterventionScreen extends ConsumerStatefulWidget {
  const PlanifierInterventionScreen({super.key, this.preselectedChampId});
  final String? preselectedChampId;

  @override
  ConsumerState<PlanifierInterventionScreen> createState() =>
      _PlanifierInterventionScreenState();
}

class _PlanifierInterventionScreenState
    extends ConsumerState<PlanifierInterventionScreen> {
  int _etape = 0;
  String? _champId;
  String? _champNom;
  TypeIntervention _type = TypeIntervention.diagnostic;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  final String _heure = '08:00';
  final _descCtrl = TextEditingController();
  double _duree = 2.0;
  final List<String> _materiel = [];
  final _materielCtrl = TextEditingController();
  bool _notifier = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedChampId != null) {
      _champId = widget.preselectedChampId;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _materielCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: context.couleurs.primaireFonce,
        foregroundColor: Colors.white,
        title: Text(
          'Planifier une intervention',
          style: AppTypography.police(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Stepper(
        currentStep: _etape,
        onStepContinue: _etape < 2 ? () => setState(() => _etape++) : null,
        onStepCancel: _etape > 0 ? () => setState(() => _etape--) : null,
        connectorColor: WidgetStateProperty.all(context.couleurs.primaire),
        steps: [
          // ── Étape 1 : Champ ──────────────────────────────────
          Step(
            title: Text('Sélectionner le champ',
                style: AppTypography.police(fontWeight: FontWeight.w600)),
            isActive: _etape >= 0,
            state: _etape > 0 ? StepState.complete : StepState.indexed,
            content: Consumer(
              builder: (_, ref, __) {
                final champsAsync = ref.watch(champsSupervisionProvider);
                return champsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Erreur chargement'),
                  data: (champs) => Column(
                    children: champs
                        .map((c) => RadioListTile<String>(
                              value: c.id,
                              groupValue: _champId,
                              title: Text(c.nom,
                                  style: AppTypography.police(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${c.agriculteurNom} · ${c.superficieFormatee}',
                                style: AppTypography.police(fontSize: 11),
                              ),
                              activeColor: context.couleurs.primaire,
                              onChanged: (v) => setState(() {
                                _champId = v;
                                _champNom = c.nom;
                              }),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),

          // ── Étape 2 : Détails ────────────────────────────────
          Step(
            title: Text('Détails de l\'intervention',
                style: AppTypography.police(fontWeight: FontWeight.w600)),
            isActive: _etape >= 1,
            state: _etape > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type
                Text('Type d\'intervention',
                    style: AppTypography.police(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TypeIntervention.values
                      .map((t) => ChoiceChip(
                            label: Text(t.libelle,
                                style: AppTypography.police(fontSize: 11)),
                            selected: _type == t,
                            selectedColor: t.couleur.withValues(alpha: 0.2),
                            onSelected: (_) => setState(() => _type = t),
                            avatar: Icon(t.icone, color: t.couleur, size: 16),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Date
                Text('Date',
                    style: AppTypography.police(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.couleurs.bordure),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 18, color: context.couleurs.primaire),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date),
                          style: AppTypography.police(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                // Durée
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Durée estimée',
                        style: AppTypography.police(fontSize: 12)),
                    Text('${_duree.toStringAsFixed(1)} h',
                        style: AppTypography.police(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.couleurs.primaire)),
                  ],
                ),
                Slider(
                  value: _duree,
                  min: 0.5,
                  max: 8,
                  divisions: 15,
                  activeColor: context.couleurs.primaire,
                  onChanged: (v) => setState(() => _duree = v),
                ),

                // Matériel
                Text('Matériel nécessaire',
                    style: AppTypography.police(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _materielCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ajouter du matériel...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: _ajouterMateriel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _ajouterMateriel(_materielCtrl.text),
                      icon: Icon(Icons.add_circle_outline,
                          color: context.couleurs.primaire),
                    ),
                  ],
                ),
                if (_materiel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _materiel
                        .map((m) => Chip(
                              label: Text(m,
                                  style: AppTypography.police(fontSize: 11)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () =>
                                  setState(() => _materiel.remove(m)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // ── Étape 3 : Confirmation ───────────────────────────
          Step(
            title: Text('Confirmation',
                style: AppTypography.police(fontWeight: FontWeight.w600)),
            isActive: _etape >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _recapRow('Champ', _champNom ?? '—'),
                _recapRow('Type', _type.libelle),
                _recapRow(
                  'Date',
                  DateFormat('d MMMM yyyy', 'fr_FR').format(_date),
                ),
                _recapRow('Durée', '${_duree.toStringAsFixed(1)} h'),
                if (_descCtrl.text.isNotEmpty)
                  _recapRow('Description', _descCtrl.text),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifier l\'agriculteur',
                        style: AppTypography.police(fontSize: 13),
                      ),
                    ),
                    Switch.adaptive(
                      value: _notifier,
                      activeColor: context.couleurs.primaire,
                      onChanged: (v) => setState(() => _notifier = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _planifier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.couleurs.primaire,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: AppTypography.police(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5)
                        : const Text('Planifier l\'intervention'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label : ',
                style: AppTypography.police(
                    fontSize: 13, color: context.couleurs.texteSecondaire)),
            Expanded(
              child: Text(valeur,
                  style: AppTypography.police(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  void _ajouterMateriel(String valeur) {
    final v = valeur.trim();
    if (v.isNotEmpty && !_materiel.contains(v)) {
      setState(() => _materiel.add(v));
      _materielCtrl.clear();
    }
  }

  Future<void> _planifier() async {
    if (_champId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un champ.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(interventionsProvider.notifier).planifier(
          champId: _champId!,
          type: _type,
          date: _date,
          description: _descCtrl.text.trim(),
          heure: _heure,
          duree: _duree,
          materiel: List.from(_materiel),
          notifier: _notifier,
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Intervention planifiée avec succès !'),
            backgroundColor: context.couleurs.primaire,
          ),
        );
        context.pop();
      }
    }
  }
}
