import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/recommandation_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/culture_card.dart';
import '../widgets/mention_sources_donnees.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/theme/app_radius.dart';

/// BottomSheet détail d'une recommandation de culture
class RecommandationDetailSheet extends StatelessWidget {
  const RecommandationDetailSheet({super.key, required this.recommandation});

  final RecommandationModel recommandation;

  /// Teinte du taux d'aptitude, selon trois paliers agronomiques : au-dessus
  /// de 85 la parcelle convient, entre 70 et 85 sous conditions, en dessous
  /// elle ne convient pas. La couleur ne porte jamais seule l'information, le
  /// pourcentage est écrit à côté.
  Color _couleurScore(BuildContext context) {
    final s = recommandation.scoreCompatibilite;
    if (s >= 85) return context.couleurs.primaire;
    if (s >= 70) return context.couleurs.secondaireTexte;
    return context.couleurs.alerteElevee;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.couleurs.surface,
          borderRadius: AppRayons.brFeuille,
        ),
        child: Column(
          children: [
            // Poignée
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.couleurs.bordure,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  // En-tête
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // La vignette porte la même étiquette que celle de la
                      // carte du classement : elle vole de la liste jusqu'ici
                      // au lieu de disparaître d'un côté et de réapparaître de
                      // l'autre, ce qui dit quelle carte on vient d'ouvrir.
                      VignetteCulture(
                        imageUrl: recommandation.imageUrl,
                        icone: Icons.eco_rounded,
                        cote: 72,
                        heroTag: etiquetteHeroCulture(recommandation.culture),
                      ),
                      const SizedBox(width: AppEspaces.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (recommandation.rang != null) ...[
                                  _RangPastille(rang: recommandation.rang!),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    recommandation.culture,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // Nom wolof : l'agriculteur nomme sa culture ainsi,
                            // l'agent conversationnel lui répond aussi ainsi.
                            if (recommandation.nomWolof != null)
                              Text(
                                recommandation.nomWolof!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: context.couleurs.texteSecondaire,
                                    ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              recommandation.periodeIdealePlantation,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: context.couleurs.texteSecondaire,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            BadgeStatut.validation(
                              recommandation.statutValidation,
                              detaille: true,
                            ),
                          ],
                        ),
                      ),
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _couleurScore(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _couleurScore(context)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          recommandation.scoreLabel,
                          style: TextStyle(
                            color: _couleurScore(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Provenance des données ayant produit cette recommandation :
                  // mesure temps réel, ou repli sur les moyennes de la zone
                  // agroécologique. Placée sous l'en-tête pour rester visible
                  // sans avoir à faire défiler, mais en retrait visuel.
                  MentionSourcesDonnees(
                    sources: recommandation.sourcesDonnees,
                    zoneAgroecologique: recommandation.zoneAgroecologique,
                    padding: const EdgeInsets.only(top: 12),
                  ),

                  const SizedBox(height: 24),

                  // Statistiques rapides
                  _StatsGrid(recommandation: recommandation),

                  const SizedBox(height: 24),

                  // Conseils agronomiques
                  _Section(
                    title: 'Conseils agronomiques',
                    icon: Icons.tips_and_updates_rounded,
                    child: Text(
                      recommandation.conseilsAgronomiques,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Engrais conseillés
                  _Section(
                    title: 'Engrais conseillés',
                    icon: Icons.science_outlined,
                    child: Column(
                      children: recommandation.engAraisConseillesList
                          .map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.fiber_manual_record,
                                        size: 8,
                                        color: context.couleurs.primaire),
                                    const SizedBox(width: 8),
                                    Text(e,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Maladies fréquentes
                  _Section(
                    title: 'Maladies fréquentes',
                    icon: Icons.bug_report_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recommandation.maladiesFrequentes
                          .map((m) => Chip(
                                label: Text(m,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: context.couleurs.alerteElevee
                                    .withValues(alpha: 0.08),
                                side: BorderSide(
                                    color: context.couleurs.alerteElevee
                                        .withValues(alpha: 0.3)),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Estimations economiques derivees de la recommandation v2
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.couleurs.bordure),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store_rounded,
                                  color: context.couleurs.secondaire, size: 18),
                              const SizedBox(width: 8),
                              Text('Estimations économiques',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _EstimationRow(
                            label: 'Prix marché estimé',
                            value: recommandation.prixLabel,
                            icon: Icons.sell_outlined,
                          ),
                          const SizedBox(height: 8),
                          _EstimationRow(
                            label: 'Profit potentiel',
                            value: recommandation.profitLabel,
                            icon: Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton fermer
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text('Fermer'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.recommandation});

  final RecommandationModel recommandation;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        Icons.water_drop_outlined,
        'Besoin en eau',
        recommandation.besoinEauLabel,
        context.couleurs.info
      ),
      (
        Icons.trending_up_rounded,
        'Rendement',
        recommandation.rendementLabel,
        context.couleurs.primaire
      ),
    ];
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: s == stats.last ? 0 : 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: s.$4.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.$4.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(s.$1, color: s.$4, size: 22),
                      const SizedBox(height: 6),
                      Text(s.$3,
                          style: TextStyle(
                              color: s.$4,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(s.$2,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: context.couleurs.texteSecondaire),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: context.couleurs.primaire),
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

class _EstimationRow extends StatelessWidget {
  const _EstimationRow(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.couleurs.secondaire),
        const SizedBox(width: 10),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.couleurs.texteSecondaire)),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: context.couleurs.textePrincipal)),
      ],
    );
  }
}

/// Pastille de rang du détail (« 1 », « 2 », « 3 »).
///
/// Reprend `RecommandationCulture.rang` décidé par le moteur : 1 désigne la
/// culture dont la probabilité d'aptitude est la plus élevée pour cette
/// parcelle. Les aptitudes étant indépendantes les unes des autres
/// (classification multi-étiquettes), le rang ordonne sans impliquer que les
/// suivantes soient inadaptées.
class _RangPastille extends StatelessWidget {
  const _RangPastille({required this.rang});

  final int rang;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.couleurs.primaire.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rang',
        style: TextStyle(
          color: context.couleurs.primaire,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
