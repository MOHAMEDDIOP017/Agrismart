import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/diagnostic_entity.dart';
import '../widgets/expert_selection_sheet.dart';
import '../widgets/gravite_badge.dart';
import '../widgets/prediction_bar.dart';
import '../widgets/symptome_chip.dart';
import '../widgets/traitement_card.dart';
import '../widgets/score_circle.dart';
import 'evaluation_sheet.dart';

/// Écran 5 — Résultat complet du diagnostic IA
class DiagnosticResultScreen extends StatelessWidget {
  const DiagnosticResultScreen({required this.diagnostic, super.key});

  final DiagnosticEntity diagnostic;

  @override
  Widget build(BuildContext context) {
    final maladie = diagnostic.maladieDetectee;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar avec image en background ──────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image analysée ou placeholder
                  diagnostic.imageLocalPath != null
                      ? Image.asset(
                          diagnostic.imageLocalPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ImagePlaceholder(),
                        )
                      : _ImagePlaceholder(),

                  // Gradient bas vers transparent
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: [0.0, 0.6],
                        colors: [Color(0xCC000000), Colors.transparent],
                      ),
                    ),
                  ),

                  // Badge de confiance (bas centre)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: ScoreCircle(
                      scorePourcent: diagnostic.scoreConfiancePourcent,
                      taille: 90,
                    ),
                  ),

                  // Chip "DIAGNOSTIC IA"
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.psychology_outlined,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'DIAGNOSTIC IA',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu principal ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section 2 — Maladie principale
                _SectionMaladie(diagnostic: diagnostic)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // Section 3 — Top 3 prédictions
                if (diagnostic.topPredictions.isNotEmpty) ...[
                  const _SectionTitre('Analyse détaillée',
                      Icons.bar_chart_outlined),
                  const SizedBox(height: 10),
                  ...diagnostic.topPredictions.asMap().entries.map(
                        (e) => PredictionBar(
                          prediction: e.value,
                          delaiAnimation:
                              Duration(milliseconds: 200 * e.key),
                        ).animate(delay: Duration(milliseconds: 200 * e.key)).fadeIn(),
                      ),
                  const SizedBox(height: 16),
                ],

                // Section 4 — Symptômes
                const _SectionTitre('Symptômes identifiés', Icons.biotech_outlined),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: maladie.symptomes
                      .asMap()
                      .entries
                      .map((e) => SymptomeChip(
                            symptome: e.value,
                            index: e.key,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Section 5 — Cultures affectées
                const _SectionTitre('Cultures susceptibles', Icons.eco_outlined),
                const SizedBox(height: 10),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: maladie.culturesAffectees.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _CultureChip(
                      culture: maladie.culturesAffectees[i],
                    )
                        .animate(delay: Duration(milliseconds: 80 * i))
                        .fadeIn()
                        .slideX(begin: 0.2, end: 0),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 6 — Traitements recommandés
                if (maladie.traitements.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_services_outlined,
                                color: AppColors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Traitement recommandé',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...maladie.traitements.map(
                          (t) => TraitementCard(traitement: t),
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // Section 7 — Actions
                _BoutonAction(
                  label: 'Partager avec un expert',
                  icone: Icons.share_outlined,
                  couleur: AppColors.primary,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (_) =>
                        ExpertSelectionSheet(diagnosticId: diagnostic.id),
                  ),
                ),
                const SizedBox(height: 10),
                _BoutonAction(
                  label: 'Évaluer ce diagnostic',
                  icone: Icons.rate_review_outlined,
                  couleur: AppColors.textSecondary,
                  outlined: false,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (_) =>
                        EvaluationDiagnosticSheet(diagnosticId: diagnostic.id),
                  ),
                ),

                const SizedBox(height: 16),

                // Section 8 — Infos du diagnostic
                _SectionInfoDiagnostic(diagnostic: diagnostic),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionMaladie extends StatelessWidget {
  const _SectionMaladie({required this.diagnostic});

  final DiagnosticEntity diagnostic;

  @override
  Widget build(BuildContext context) {
    final maladie = diagnostic.maladieDetectee;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_florist_outlined,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maladie.nom,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        maladie.nomScientifique,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GraviteBadge(gravite: maladie.gravite),
            const SizedBox(height: 12),
            Text(
              maladie.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (maladie.agentPathogene != null) ...[
              const SizedBox(height: 10),
              _InfoLine(
                label: 'Agent',
                valeur: maladie.agentPathogene!,
                icone: Icons.science_outlined,
              ),
            ],
            if (maladie.conditionsFavorables != null) ...[
              const SizedBox(height: 6),
              _InfoLine(
                label: 'Conditions',
                valeur: maladie.conditionsFavorables!,
                icone: Icons.wb_sunny_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(
      {required this.label,
      required this.valeur,
      required this.icone});

  final String label;
  final String valeur;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          '$label : ',
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        Expanded(
          child: Text(
            valeur,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _CultureChip extends StatelessWidget {
  const _CultureChip({required this.culture});

  final String culture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grass, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            culture,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionInfoDiagnostic extends StatelessWidget {
  const _SectionInfoDiagnostic({required this.diagnostic});

  final DiagnosticEntity diagnostic;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du diagnostic',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
              icone: Icons.schedule_outlined,
              label: 'Analysé le',
              valeur: fmt.format(diagnostic.dateAnalyse)),
          _InfoRow(
              icone: Icons.timer_outlined,
              label: 'Temps d\'analyse',
              valeur: diagnostic.tempsAnalyseFormate),
          _InfoRow(
              icone: Icons.smart_toy_outlined,
              label: 'Modèle IA',
              valeur: 'AgriSmart v${diagnostic.modeleVersion}'),
          if (diagnostic.champNom != null)
            _InfoRow(
                icone: Icons.terrain_outlined,
                label: 'Champ',
                valeur: diagnostic.champNom!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icone,
      required this.label,
      required this.valeur});

  final IconData icone;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label : ',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              valeur,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  const _SectionTitre(this.titre, this.icone);

  final String titre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          titre,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _BoutonAction extends StatelessWidget {
  const _BoutonAction({
    required this.label,
    required this.icone,
    required this.couleur,
    required this.onTap,
    this.outlined = true,
  });

  final String label;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icone, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: couleur,
          side: BorderSide(color: couleur),
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icone, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: couleur),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      child: const Center(
        child: Icon(Icons.eco, size: 80, color: Colors.white30),
      ),
    );
  }
}
