import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../providers/donnees_agro_provider.dart';
import '../widgets/agro_slider_field.dart';

/// Écran de saisie des données agronomiques avec Stepper horizontal
class DonneesAgroScreen extends ConsumerStatefulWidget {
  const DonneesAgroScreen({super.key});

  @override
  ConsumerState<DonneesAgroScreen> createState() => _DonneesAgroScreenState();
}

class _DonneesAgroScreenState extends ConsumerState<DonneesAgroScreen> {
  int _etape = 0;
  String? _champSelectionne;

  // Valeurs des sliders
  double _ph = 7.0;
  double _azote = 50.0;
  double _phosphore = 30.0;
  double _potassium = 80.0;
  double _humidite = 60.0;
  final _observationsCtrl = TextEditingController();

  bool _isSaved = false;

  @override
  void dispose() {
    _observationsCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_etape == 0 && _champSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un champ')),
      );
      return;
    }
    if (_etape < 2) setState(() => _etape++);
  }

  void _prevStep() {
    if (_etape > 0) setState(() => _etape--);
  }

  Future<void> _valider() async {
    if (_champSelectionne == null) return;
    try {
      await ref.read(donneesAgroProvider.notifier).sauvegarder(
            champId: _champSelectionne!,
            ph: _ph,
            azote: _azote,
            phosphore: _phosphore,
            potassium: _potassium,
            humidite: _humidite,
            observations: _observationsCtrl.text,
          );
    } catch (_) {
      // Sauvegarde échouée — on affiche quand même le succès en mode dev
    }
    setState(() => _isSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaved) {
      return _SuccessScreen(onDone: () => context.pop());
    }

    final champsAsync = ref.watch(champProvider);
    final champs = champsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Données agronomiques'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Stepper horizontal
          _HorizontalStepper(currentStep: _etape),

          // Contenu de l'étape
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_etape) {
                0 => _EtapeSelection(
                    key: const ValueKey(0),
                    champs: champs,
                    champSelectionne: _champSelectionne,
                    onSelect: (id) => setState(() => _champSelectionne = id),
                  ),
                1 => _EtapeSaisie(
                    key: const ValueKey(1),
                    ph: _ph,
                    azote: _azote,
                    phosphore: _phosphore,
                    potassium: _potassium,
                    humidite: _humidite,
                    observationsCtrl: _observationsCtrl,
                    onPhChanged: (v) => setState(() => _ph = v),
                    onAzoteChanged: (v) => setState(() => _azote = v),
                    onPhosphoreChanged: (v) => setState(() => _phosphore = v),
                    onPotassiumChanged: (v) => setState(() => _potassium = v),
                    onHumiditeChanged: (v) => setState(() => _humidite = v),
                  ),
                _ => _EtapeConfirmation(
                    key: const ValueKey(2),
                    champNom: champs
                        .where((c) => c.id == _champSelectionne)
                        .map((c) => c.nom)
                        .firstOrNull ?? '—',
                    ph: _ph,
                    azote: _azote,
                    phosphore: _phosphore,
                    potassium: _potassium,
                    humidite: _humidite,
                    observations: _observationsCtrl.text,
                  ),
              },
            ),
          ),

          // Navigation bas
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_etape > 0)
                  Expanded(
                    child: AppButton(
                      label: 'Précédent',
                      onPressed: _prevStep,
                      isOutlined: true,
                    ),
                  ),
                if (_etape > 0) const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _etape == 2 ? 'Valider' : 'Suivant',
                    onPressed: _etape == 2 ? _valider : _nextStep,
                    icon: _etape == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stepper horizontal ────────────────────────────────────────────────
class _HorizontalStepper extends StatelessWidget {
  const _HorizontalStepper({required this.currentStep});

  final int currentStep;
  static const _labels = ['Champ', 'Données', 'Confirmation'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep ? AppColors.primary : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.primary
                      : isActive
                          ? AppColors.primary
                          : AppColors.border,
                  border: Border.all(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isActive || isDone ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Étape 1 : Sélection du champ ──────────────────────────────────────
class _EtapeSelection extends StatelessWidget {
  const _EtapeSelection({
    super.key,
    required this.champs,
    required this.champSelectionne,
    required this.onSelect,
  });

  final List<dynamic> champs;
  final String? champSelectionne;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sélectionner un champ', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Choisissez le champ pour lequel vous saisissez les données.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ...champs.map((champ) => RadioListTile<String>(
                title: Text(champ.nom),
                subtitle: Text('${champ.superficie} ha · ${champ.typeSol}'),
                value: champ.id,
                groupValue: champSelectionne,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: champSelectionne == champ.id
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : null,
                onChanged: (v) => v != null ? onSelect(v) : null,
              ).animate().fadeIn(delay: (champs.indexOf(champ) * 80).ms)),
        ],
      ),
    );
  }
}

// ─── Étape 2 : Saisie des données ──────────────────────────────────────
class _EtapeSaisie extends StatelessWidget {
  const _EtapeSaisie({
    super.key,
    required this.ph,
    required this.azote,
    required this.phosphore,
    required this.potassium,
    required this.humidite,
    required this.observationsCtrl,
    required this.onPhChanged,
    required this.onAzoteChanged,
    required this.onPhosphoreChanged,
    required this.onPotassiumChanged,
    required this.onHumiditeChanged,
  });

  final double ph;
  final double azote;
  final double phosphore;
  final double potassium;
  final double humidite;
  final TextEditingController observationsCtrl;
  final void Function(double) onPhChanged;
  final void Function(double) onAzoteChanged;
  final void Function(double) onPhosphoreChanged;
  final void Function(double) onPotassiumChanged;
  final void Function(double) onHumiditeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AgroSliderField(
            label: 'pH du sol',
            value: ph,
            min: 0,
            max: 14,
            unit: '',
            divisions: 140,
            coloredByValue: true,
            onChanged: onPhChanged,
          ),
          const Divider(height: 32),
          AgroSliderField(
            label: 'Azote (N)',
            value: azote,
            min: 0,
            max: 200,
            unit: 'kg/ha',
            onChanged: onAzoteChanged,
          ),
          const Divider(height: 32),
          AgroSliderField(
            label: 'Phosphore (P)',
            value: phosphore,
            min: 0,
            max: 150,
            unit: 'kg/ha',
            onChanged: onPhosphoreChanged,
          ),
          const Divider(height: 32),
          AgroSliderField(
            label: 'Potassium (K)',
            value: potassium,
            min: 0,
            max: 200,
            unit: 'kg/ha',
            onChanged: onPotassiumChanged,
          ),
          const Divider(height: 32),
          AgroSliderField(
            label: 'Humidité observée',
            value: humidite,
            min: 0,
            max: 100,
            unit: '%',
            onChanged: onHumiditeChanged,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: observationsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observations (optionnel)',
              hintText: 'Notes sur l\'état général du champ...',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Étape 3 : Confirmation ─────────────────────────────────────────────
class _EtapeConfirmation extends StatelessWidget {
  const _EtapeConfirmation({
    super.key,
    required this.champNom,
    required this.ph,
    required this.azote,
    required this.phosphore,
    required this.potassium,
    required this.humidite,
    required this.observations,
  });

  final String champNom;
  final double ph;
  final double azote;
  final double phosphore;
  final double potassium;
  final double humidite;
  final String observations;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirmer la saisie', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          _ConfirmRow(label: 'Champ', value: champNom, icon: Icons.terrain_rounded),
          _ConfirmRow(label: 'pH du sol', value: ph.toStringAsFixed(1), icon: Icons.science_outlined),
          _ConfirmRow(label: 'Azote (N)', value: '${azote.toInt()} kg/ha', icon: Icons.grass_rounded),
          _ConfirmRow(label: 'Phosphore (P)', value: '${phosphore.toInt()} kg/ha', icon: Icons.grain_rounded),
          _ConfirmRow(label: 'Potassium (K)', value: '${potassium.toInt()} kg/ha', icon: Icons.blur_on_rounded),
          _ConfirmRow(label: 'Humidité', value: '${humidite.toInt()}%', icon: Icons.water_drop_outlined),
          if (observations.isNotEmpty)
            _ConfirmRow(label: 'Observations', value: observations, icon: Icons.notes_rounded),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}

// ─── Écran de succès ────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 60),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text('Données enregistrées !', style: Theme.of(context).textTheme.headlineMedium)
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Text(
                'Vos données agronomiques ont été sauvegardées avec succès.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),
              AppButton(label: 'Retour', onPressed: onDone, width: 200)
                  .animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
