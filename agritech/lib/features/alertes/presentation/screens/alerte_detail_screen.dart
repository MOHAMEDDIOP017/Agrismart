import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../features/alertes/data/models/alerte_model.dart';
import '../providers/alertes_provider.dart';

/// Écran détail d'une alerte avec diagnostic et traitement
class AlerteDetailScreen extends ConsumerStatefulWidget {
  const AlerteDetailScreen({super.key, required this.alerteId});

  final String alerteId;

  @override
  ConsumerState<AlerteDetailScreen> createState() => _AlerteDetailScreenState();
}

class _AlerteDetailScreenState extends ConsumerState<AlerteDetailScreen> {
  bool _isLue = false;
  bool _showEvaluation = false;
  int? _evaluation; // 0=correct, 1=partiel, 2=incorrect
  final _commentCtrl = TextEditingController();
  bool _evalSubmitted = false;

  AlerteModel? get _alerte =>
      ref.watch(alertesProvider).valueOrNull?.where((a) => a.id == widget.alerteId).firstOrNull;

  Color _niveauColor(String niveau) => switch (niveau) {
        AppConstants.alerteCritique => AppColors.alerteCritique,
        AppConstants.alerteEleve => AppColors.alerteEleve,
        AppConstants.alerteModere => AppColors.alerteModere,
        _ => AppColors.alerteFaible,
      };

  @override
  void initState() {
    super.initState();
    _isLue = _alerte?.isLue ?? false;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerte = _alerte;
    if (alerte == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerte introuvable')),
        body: const Center(child: Text('Cette alerte n\'existe plus.')),
      );
    }

    final color = _niveauColor(alerte.niveau);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'alerte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec niveau de gravité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alerte.titre,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        _NiveauChip(niveau: alerte.niveau, color: color),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // Champ concerné
            _InfoRow(
              icon: Icons.terrain_rounded,
              label: 'Champ concerné',
              value: alerte.champNom,
              color: AppColors.primary,
            ).animate().fadeIn(delay: 80.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // Maladie détectée
            _InfoRow(
              icon: Icons.bug_report_outlined,
              label: 'Maladie détectée',
              value: alerte.maladieDetectee,
              color: color,
            ).animate().fadeIn(delay: 120.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Description complète
            _Section(
              title: 'Description',
              icon: Icons.description_outlined,
              child: Text(
                alerte.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.6),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // Traitement conseillé
            _Section(
              title: 'Traitement conseillé',
              icon: Icons.healing_outlined,
              color: AppColors.primary,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  alerte.traitementConseille,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            // Bouton marquer comme lu
            if (!_isLue)
              AppButton(
                label: 'Marquer comme lu',
                onPressed: () => setState(() => _isLue = true),
                isOutlined: true,
                icon: Icons.check_circle_outline_rounded,
              ).animate().fadeIn(delay: 250.ms),

            if (_isLue && !_showEvaluation && !_evalSubmitted) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'Évaluer ce diagnostic',
                onPressed: () => setState(() => _showEvaluation = true),
                icon: Icons.star_outline_rounded,
                color: AppColors.amber,
              ).animate().fadeIn(delay: 300.ms),
            ],

            // Section évaluation du diagnostic
            if (_showEvaluation && !_evalSubmitted) ...[
              const SizedBox(height: 24),
              _EvaluationSection(
                evaluation: _evaluation,
                commentCtrl: _commentCtrl,
                onEvaluate: (v) => setState(() => _evaluation = v),
                onSubmit: () => setState(() => _evalSubmitted = true),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            ],

            // Remerciement après évaluation
            if (_evalSubmitted)
              _ThanksCard()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets utilitaires ─────────────────────────────────────────────────

class _NiveauChip extends StatelessWidget {
  const _NiveauChip({required this.niveau, required this.color});
  final String niveau;
  final Color color;

  String get _label => switch (niveau) {
        AppConstants.alerteCritique => 'CRITIQUE',
        AppConstants.alerteEleve => 'ÉLEVÉ',
        AppConstants.alerteModere => 'MODÉRÉ',
        _ => 'FAIBLE',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Niveau : $_label',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: color ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.color,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─── Section évaluation du diagnostic ────────────────────────────────────
class _EvaluationSection extends StatelessWidget {
  const _EvaluationSection({
    required this.evaluation,
    required this.commentCtrl,
    required this.onEvaluate,
    required this.onSubmit,
  });

  final int? evaluation;
  final TextEditingController commentCtrl;
  final void Function(int) onEvaluate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce diagnostic était-il correct ?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _EvalButton(
                label: 'Correct',
                icon: Icons.check_circle_rounded,
                color: AppColors.primary,
                isSelected: evaluation == 0,
                onTap: () => onEvaluate(0),
              ),
              const SizedBox(width: 8),
              _EvalButton(
                label: 'Partiel',
                icon: Icons.remove_circle_rounded,
                color: AppColors.amber,
                isSelected: evaluation == 1,
                onTap: () => onEvaluate(1),
              ),
              const SizedBox(width: 8),
              _EvalButton(
                label: 'Incorrect',
                icon: Icons.cancel_rounded,
                color: AppColors.danger,
                isSelected: evaluation == 2,
                onTap: () => onEvaluate(2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Commentaire (optionnel)...',
              prefixIcon: Icon(Icons.comment_outlined),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Envoyer l\'évaluation',
            onPressed: evaluation != null ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _EvalButton extends StatelessWidget {
  const _EvalButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThanksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merci pour votre retour !',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre évaluation aide à améliorer les diagnostics.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
