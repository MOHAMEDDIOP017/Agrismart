import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/recommandation_expert_entity.dart';
import '../providers/expert_provider.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../shared/widgets/widgets.dart';

/// Détail d'une RecommandationCulture avec actions Valider / Corriger / Rejeter
class RecommandationDetailExpertScreen extends ConsumerStatefulWidget {
  const RecommandationDetailExpertScreen({super.key, required this.recoId});
  final String recoId;

  @override
  ConsumerState<RecommandationDetailExpertScreen> createState() =>
      _RecommandationDetailExpertScreenState();
}

class _RecommandationDetailExpertScreenState
    extends ConsumerState<RecommandationDetailExpertScreen> {
  bool _enChargement = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recommandationsExpertProvider);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: context.couleurs.primaireFonce,
        foregroundColor: Colors.white,
        title: Text(
          'Recommandation IA',
          style: AppTypography.police(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: async.when(
          data: (s) {
            final reco = s.recommandations
                .where((r) => r.id == widget.recoId)
                .firstOrNull;
            if (reco == null || !reco.estEnAttente) return [];
            return [
              TextButton(
                onPressed: _enChargement ? null : () => _valider(context, reco),
                child: Text('Valider',
                    style: AppTypography.police(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed:
                    _enChargement ? null : () => _corriger(context, reco),
                child: Text('Corriger',
                    style: AppTypography.police(
                        color: Colors.amber, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: _enChargement ? null : () => _rejeter(context, reco),
                child: Text('Rejeter',
                    style: AppTypography.police(
                        color: context.couleurs.erreur,
                        fontWeight: FontWeight.w600)),
              ),
            ];
          },
          loading: () => [],
          error: (_, __) => [],
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(recommandationsExpertProvider),
        ),
        data: (s) {
          final reco =
              s.recommandations.where((r) => r.id == widget.recoId).firstOrNull;
          if (reco == null) {
            return Center(
              child: Text(
                'Recommandation introuvable',
                style: AppTypography.police(
                    color: context.couleurs.texteSecondaire),
              ),
            );
          }
          return _Contenu(reco: reco, enChargement: _enChargement);
        },
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _valider(BuildContext ctx, RecommandationExpertEntity reco) {
    return _afficherFeuille(
      context: ctx,
      titre: 'Valider la recommandation',
      description:
          'Vous confirmez que les cultures recommandées par l\'IA sont adaptées à ce champ.',
      couleur: context.couleurs.primaire,
      labelBouton: 'Confirmer la validation',
      commentaireRequis: false,
      onConfirmer: (commentaire, notifier) async {
        setState(() => _enChargement = true);
        final ok =
            await ref.read(recommandationsExpertProvider.notifier).valider(
                  recoId: reco.id,
                  commentaire: commentaire,
                  notifierAgriculteur: notifier,
                );
        if (mounted) setState(() => _enChargement = false);
        if (ok && ctx.mounted) {
          Navigator.pop(ctx);
          Navigator.pop(ctx);
        } else if (ctx.mounted) {
          // `ctx` et non `context` : c'est lui que le `mounted` ci-dessus
          // garde après l'attente, et lire le thème par l'autre reviendrait à
          // se servir d'un contexte dont rien ne dit qu'il est encore monté.
          RetourAction.echec(ctx, null);
        }
      },
    );
  }

  Future<void> _corriger(BuildContext ctx, RecommandationExpertEntity reco) {
    final cultureCtrl = TextEditingController();
    return _afficherFeuille(
      context: ctx,
      titre: 'Corriger la recommandation',
      description:
          'Indiquez la culture que vous recommandez à la place et expliquez votre correction.',
      couleur: context.couleurs.secondaire,
      labelBouton: 'Soumettre la correction',
      commentaireRequis: true,
      champSupplementaire: TextField(
        controller: cultureCtrl,
        decoration: InputDecoration(
          labelText: 'Culture recommandée (optionnel)',
          prefixIcon: Icon(Icons.eco_outlined,
              color: context.couleurs.primaire, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      onConfirmer: (commentaire, notifier) async {
        setState(() => _enChargement = true);
        final ok = await ref
            .read(recommandationsExpertProvider.notifier)
            .corrigerOuRejeter(
              recoId: reco.id,
              decision: 'CORRIGEE',
              commentaire: commentaire ?? '',
              cultureCorrigee: cultureCtrl.text.trim().isEmpty
                  ? null
                  : cultureCtrl.text.trim(),
              notifierAgriculteur: notifier,
            );
        if (mounted) setState(() => _enChargement = false);
        if (ok && ctx.mounted) {
          Navigator.pop(ctx);
          Navigator.pop(ctx);
        }
      },
    );
  }

  Future<void> _rejeter(BuildContext ctx, RecommandationExpertEntity reco) {
    return _afficherFeuille(
      context: ctx,
      titre: 'Rejeter la recommandation',
      description:
          'La recommandation sera marquée comme rejetée. Un motif obligatoire sera transmis à l\'agriculteur.',
      couleur: context.couleurs.erreur,
      labelBouton: 'Confirmer le rejet',
      commentaireRequis: true,
      onConfirmer: (commentaire, notifier) async {
        setState(() => _enChargement = true);
        final ok = await ref
            .read(recommandationsExpertProvider.notifier)
            .corrigerOuRejeter(
              recoId: reco.id,
              decision: 'REJETEE',
              commentaire: commentaire ?? '',
              notifierAgriculteur: notifier,
            );
        if (mounted) setState(() => _enChargement = false);
        if (ok && ctx.mounted) {
          Navigator.pop(ctx);
          Navigator.pop(ctx);
        }
      },
    );
  }

  Future<void> _afficherFeuille({
    required BuildContext context,
    required String titre,
    required String description,
    required Color couleur,
    required String labelBouton,
    required bool commentaireRequis,
    Widget? champSupplementaire,
    required Future<void> Function(String? commentaire, bool notifier)
        onConfirmer,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeuilleAction(
        titre: titre,
        description: description,
        couleur: couleur,
        labelBouton: labelBouton,
        commentaireRequis: commentaireRequis,
        champSupplementaire: champSupplementaire,
        onConfirmer: onConfirmer,
      ),
    );
  }
}

// ── Contenu principal ────────────────────────────────────────────────────────

class _Contenu extends StatelessWidget {
  const _Contenu({required this.reco, required this.enChargement});
  final RecommandationExpertEntity reco;
  final bool enChargement;

  /// Teinte du statut, résolue au rendu.
  ///
  /// C'était une table constante de couleurs figées, ce qui interdisait au
  /// thème sombre de s'y appliquer : une constante de compilation ne peut pas
  /// dépendre du mode d'affichage.
  Color _couleurStatut(BuildContext context) => switch (reco.statutValidation) {
        'EN_ATTENTE' => context.couleurs.avertissement,
        'VALIDEE' => context.couleurs.succes,
        'CORRIGEE' => context.couleurs.info,
        'REJETEE' => context.couleurs.erreur,
        _ => context.couleurs.texteSecondaire,
      };

  @override
  Widget build(BuildContext context) {
    final couleurStatut = _couleurStatut(context);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Statut ─────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: couleurStatut.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: couleurStatut.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          reco.statutLibelle.toUpperCase(),
                          style: AppTypography.police(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: couleurStatut),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        reco.tempsEcoule,
                        style: AppTypography.police(
                            fontSize: 12,
                            color: context.couleurs.texteSecondaire),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Champ / Agriculteur ────────────────────────
                  _Section(
                    titre: 'Champ concerné',
                    enfants: [
                      _LigneInfo(Icons.terrain_outlined, 'Champ',
                          '${reco.champNom} · ${reco.champRegion}'),
                      _LigneInfo(Icons.person_outline, 'Agriculteur',
                          reco.agriculteurNom),
                      if (reco.agriculteurTelephone.isNotEmpty)
                        _LigneInfo(Icons.phone_outlined, 'Téléphone',
                            reco.agriculteurTelephone),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Top 3 cultures ─────────────────────────────
                  _Section(
                    titre: 'Cultures recommandées par l\'IA',
                    enfants: reco.top3Cultures
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: c.rang == 1
                                              ? context.couleurs.primaire
                                              : context.couleurs.info
                                                  .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${c.rang}',
                                          style: TextStyle(
                                            color: c.rang == 1
                                                ? Colors.white
                                                : context.couleurs.info,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c.nom,
                                          style: AppTypography.police(
                                            fontSize: 14,
                                            fontWeight: c.rang == 1
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color:
                                                context.couleurs.textePrincipal,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        c.scoreLabel,
                                        style: AppTypography.police(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: c.rang == 1
                                              ? context.couleurs.primaire
                                              : context.couleurs.info,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: c.score),
                                    duration: AppDurees.moyenne,
                                    builder: (_, v, __) =>
                                        LinearProgressIndicator(
                                      value: v,
                                      backgroundColor: context.couleurs.bordure,
                                      valueColor: AlwaysStoppedAnimation(
                                        c.rang == 1
                                            ? context.couleurs.primaire
                                            : context.couleurs.info,
                                      ),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  if (c.rendementEstime != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rendement estimé : ${c.rendementLabel}',
                                      style: AppTypography.police(
                                          fontSize: 11,
                                          color:
                                              context.couleurs.texteSecondaire),
                                    ),
                                  ],
                                ],
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // ── Données d'entrée (snapshot agronomique) ────
                  _Section(
                    titre: 'Données d\'entrée utilisées',
                    enfants: [
                      _SnapshotGrid(snapshot: reco.snapshot),
                    ],
                  ),

                  // ── Note expert (si déjà traité) ───────────────
                  if (reco.commentaireExpert != null) ...[
                    const SizedBox(height: 16),
                    _Section(
                      titre: 'Note de l\'expert',
                      enfants: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: couleurStatut.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: couleurStatut.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            reco.commentaireExpert!,
                            style: AppTypography.police(
                              fontSize: 13,
                              color: context.couleurs.textePrincipal,
                            ),
                          ),
                        ),
                        if (reco.cultureCorrigee != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _LigneInfo(
                              Icons.eco_outlined,
                              'Culture corrigée',
                              reco.cultureCorrigee!,
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
        if (enChargement)
          const ColoredBox(
            color: Colors.black26,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// ── Grid snapshot agronomique ────────────────────────────────────────────────

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.snapshot});
  final SnapshotAgronomique snapshot;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      if (snapshot.azote != null)
        (
          'Azote (N)',
          '${snapshot.azote!.toStringAsFixed(1)} mg/kg',
          Icons.science_outlined
        ),
      if (snapshot.phosphore != null)
        (
          'Phosphore (P)',
          '${snapshot.phosphore!.toStringAsFixed(1)} mg/kg',
          Icons.science_outlined
        ),
      if (snapshot.potassium != null)
        (
          'Potassium (K)',
          '${snapshot.potassium!.toStringAsFixed(1)} mg/kg',
          Icons.science_outlined
        ),
      if (snapshot.ph != null)
        ('pH', snapshot.ph!.toStringAsFixed(1), Icons.water_drop_outlined),
      if (snapshot.humidite != null)
        (
          'Humidité',
          '${snapshot.humidite!.toStringAsFixed(0)} %',
          Icons.water_outlined
        ),
      if (snapshot.temperature != null)
        (
          'Température',
          '${snapshot.temperature!.toStringAsFixed(1)} °C',
          Icons.thermostat_outlined
        ),
      if (snapshot.pluviometrie != null)
        (
          'Pluviométrie',
          '${snapshot.pluviometrie!.toStringAsFixed(0)} mm',
          Icons.cloud_outlined
        ),
      if (snapshot.typeSol != null)
        ('Type de sol', snapshot.typeSol!, Icons.terrain_outlined),
    ];

    if (items.isEmpty) {
      return Text(
        'Données d\'entrée non disponibles',
        style: AppTypography.police(
            fontSize: 12, color: context.couleurs.texteSecondaire),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.couleurs.primaire.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: context.couleurs.primaire.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(item.$3, size: 16, color: context.couleurs.primaire),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.$1,
                            style: AppTypography.police(
                                fontSize: 9,
                                color: context.couleurs.texteSecondaire),
                          ),
                          Text(
                            item.$2,
                            style: AppTypography.police(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.couleurs.textePrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Widgets utilitaires ──────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.enfants});
  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.couleurs.bordure),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: AppTypography.police(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.couleurs.textePrincipal),
              ),
              const SizedBox(height: 10),
              ...enfants,
            ],
          ),
        ),
      );
}

class _LigneInfo extends StatelessWidget {
  const _LigneInfo(this.icone, this.label, this.valeur);
  final IconData icone;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 16, color: context.couleurs.texteSecondaire),
            const SizedBox(width: 8),
            Text('$label : ',
                style: AppTypography.police(
                    fontSize: 12, color: context.couleurs.texteSecondaire)),
            Expanded(
              child: Text(valeur,
                  style: AppTypography.police(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.couleurs.textePrincipal)),
            ),
          ],
        ),
      );
}

// ── BottomSheet action (valider / corriger / rejeter) ────────────────────────

class _FeuilleAction extends StatefulWidget {
  const _FeuilleAction({
    required this.titre,
    required this.description,
    required this.couleur,
    required this.labelBouton,
    required this.commentaireRequis,
    required this.onConfirmer,
    this.champSupplementaire,
  });

  final String titre;
  final String description;
  final Color couleur;
  final String labelBouton;
  final bool commentaireRequis;
  final Widget? champSupplementaire;
  final Future<void> Function(String? commentaire, bool notifier) onConfirmer;

  @override
  State<_FeuilleAction> createState() => _FeuilleActionState();
}

class _FeuilleActionState extends State<_FeuilleAction> {
  final _commentaireCtrl = TextEditingController();
  bool _notifier = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.couleurs.bordure,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(widget.titre,
                      style: AppTypography.police(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.couleur)),
                  const SizedBox(height: 6),
                  Text(widget.description,
                      style: AppTypography.police(
                          fontSize: 13,
                          color: context.couleurs.texteSecondaire)),
                  const SizedBox(height: 20),

                  // Champ supplémentaire (ex : culture corrigée)
                  if (widget.champSupplementaire != null) ...[
                    widget.champSupplementaire!,
                    const SizedBox(height: 12),
                  ],

                  // Commentaire
                  Text(
                    widget.commentaireRequis
                        ? 'Commentaire expert *'
                        : 'Commentaire expert (optionnel)',
                    style: AppTypography.police(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentaireCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: widget.commentaireRequis
                          ? 'Expliquez votre décision...'
                          : 'Ajoutez vos observations (optionnel)...',
                      hintStyle: AppTypography.police(
                          fontSize: 12,
                          color: context.couleurs.texteSecondaire),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: context.couleurs.bordure)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: context.couleurs.bordure)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notification agriculteur
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notifier l\'agriculteur',
                                style: AppTypography.police(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('Notification push automatique',
                                style: AppTypography.police(
                                    fontSize: 11,
                                    color: context.couleurs.texteSecondaire)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _notifier,
                        activeColor: context.couleurs.primaire,
                        onChanged: (v) => setState(() => _notifier = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton confirmer
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.couleur,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.police(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(widget.labelBouton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmer() async {
    final commentaire = _commentaireCtrl.text.trim();
    if (widget.commentaireRequis && commentaire.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Le commentaire doit contenir au moins 10 caractères.'),
          backgroundColor: context.couleurs.erreur,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await widget.onConfirmer(
      commentaire.isEmpty ? null : commentaire,
      _notifier,
    );
    if (mounted) setState(() => _isLoading = false);
  }
}
