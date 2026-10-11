import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/statut_validation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../navigation/expert_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/recommandation_expert_entity.dart';
import '../providers/expert_provider.dart';

/// File de validation de l'expert agronome.
///
/// C'est la tâche première du rôle, et elle occupe maintenant le premier
/// onglet. Trois changements portent sur l'écran lui-même.
///
/// **Les trois décisions sont sur la carte.** Il fallait auparavant ouvrir le
/// détail pour agir, c'est-à-dire deux écrans et un retour pour chaque
/// recommandation, alors qu'un agronome en traite plusieurs d'affilée.
/// Valider se fait d'un geste depuis la liste. Corriger et rejeter ouvrent le
/// détail, parce que le serveur exige un commentaire : une décision qui change
/// le conseil reçu par un agriculteur doit être motivée.
///
/// **Les filtres passent des onglets aux puces.** Quatre onglets défilants, un
/// `TabController`, et des compteurs recalculés à chaque reconstruction, pour
/// un simple choix parmi cinq.
///
/// **Le classement se lit entier.** Les trois cultures et leurs taux restent
/// visibles sur la carte : c'est sur l'écart entre elles que l'agronome décide
/// s'il valide ou s'il corrige.
class RecommandationsExpertScreen extends ConsumerWidget {
  const RecommandationsExpertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommandationsExpertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('À valider'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(recommandationsExpertProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const SqueletteListe.cultures(nombre: 4),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () =>
              ref.read(recommandationsExpertProvider.notifier).refresh(),
        ),
        data: (etat) => Column(
          children: [
            _Filtres(
              actif: etat.filtre,
              compteurs: _compteurs(etat),
              onChoisir: (filtre) => ref
                  .read(recommandationsExpertProvider.notifier)
                  .setFiltre(filtre),
            ),
            Expanded(child: _Liste(etat: etat)),
          ],
        ),
      ),
    );
  }

  Map<String, int> _compteurs(RecommandationsExpertState etat) {
    final compte = <String, int>{'TOUTES': etat.recommandations.length};
    for (final reco in etat.recommandations) {
      compte[reco.statutValidation] = (compte[reco.statutValidation] ?? 0) + 1;
    }
    return compte;
  }
}

// ── Filtres ──────────────────────────────────────────────────────────────────

class _Filtres extends StatelessWidget {
  const _Filtres({
    required this.actif,
    required this.compteurs,
    required this.onChoisir,
  });

  final String actif;
  final Map<String, int> compteurs;
  final void Function(String) onChoisir;

  static const _filtres = [
    ('EN_ATTENTE', 'En attente'),
    ('VALIDEE', 'Validées'),
    ('CORRIGEE', 'Corrigées'),
    ('REJETEE', 'Rejetées'),
    ('TOUTES', 'Toutes'),
  ];

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Container(
      decoration: BoxDecoration(
        color: couleurs.surface,
        border: Border(bottom: BorderSide(color: couleurs.separateur)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppEspaces.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppEspaces.md),
        child: Row(
          children: [
            for (final (cle, libelle) in _filtres) ...[
              if (cle != _filtres.first.$1)
                const SizedBox(width: AppEspaces.xs),
              _PuceFiltre(
                libelle: libelle,
                nombre: compteurs[cle] ?? 0,
                choisi: cle == actif,
                onTap: () => onChoisir(cle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PuceFiltre extends StatelessWidget {
  const _PuceFiltre({
    required this.libelle,
    required this.nombre,
    required this.choisi,
    required this.onTap,
  });

  final String libelle;
  final int nombre;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Semantics(
      selected: choisi,
      button: true,
      label: '$libelle, $nombre',
      child: ZoneTactile(
        onTap: onTap,
        rayon: AppRayons.brPastille,
        tailleMinimale: null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.sm,
            vertical: AppEspaces.xs,
          ),
          decoration: BoxDecoration(
            color: choisi ? couleurs.primaire : couleurs.surface,
            borderRadius: AppRayons.brPastille,
            border: Border.all(
              color: choisi ? couleurs.primaire : couleurs.bordure,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                libelle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: choisi
                          ? couleurs.surPrimaire
                          : couleurs.textePrincipal,
                    ),
              ),
              const SizedBox(width: AppEspaces.xxs),
              Text(
                '$nombre',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: choisi
                          ? couleurs.surPrimaire
                          : couleurs.texteSecondaire,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Liste ────────────────────────────────────────────────────────────────────

class _Liste extends ConsumerWidget {
  const _Liste({required this.etat});

  final RecommandationsExpertState etat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = etat.filtrees;

    if (liste.isEmpty) {
      return EtatVide(
        titre: etat.filtre == 'EN_ATTENTE'
            ? 'Rien à valider'
            : 'Aucune recommandation',
        message: etat.filtre == 'EN_ATTENTE'
            ? 'Toutes les recommandations de vos parcelles ont été traitées.'
            : 'Changez de filtre pour voir les autres recommandations.',
        sujet: SujetIllustration.recherche,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(recommandationsExpertProvider.notifier).refresh(),
      child: ListView.separated(
        padding: AppEspaces.liste,
        itemCount: liste.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppEspaces.entreCartes),
        itemBuilder: (context, index) => ApparitionCascade(
          index: index,
          child: _CarteReco(reco: liste[index]),
        ),
      ),
    );
  }
}

class _CarteReco extends ConsumerWidget {
  const _CarteReco({required this.reco});

  final RecommandationExpertEntity reco;

  void _ouvrirDetail(BuildContext context) {
    context.goNamed(
      ExpertRoutes.recommandationDetailNom,
      pathParameters: {'id': reco.id},
    );
  }

  Future<void> _valider(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(recommandationsExpertProvider.notifier)
        .valider(recoId: reco.id);

    if (!context.mounted) return;
    if (ok) {
      RetourAction.succes(
        context,
        'Recommandation validée pour ${reco.champNom}',
      );
    } else {
      // Le dépôt renvoie un booléen sans porter la cause de l'échec : le
      // message reste donc le plus général de ceux que traduit MessageErreur.
      RetourAction.echec(context, null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;
    final statut = StatutValidation.fromString(reco.statutValidation);

    return ZoneTactile(
      onTap: () => _ouvrirDetail(context),
      rayon: AppRayons.brCarte,
      tailleMinimale: null,
      etiquette: 'Recommandation pour ${reco.champNom}',
      child: Container(
        padding: AppEspaces.carte,
        decoration: BoxDecoration(
          color: couleurs.surface,
          borderRadius: AppRayons.brCarte,
          border: Border.all(
            // Une recommandation en attente se distingue au premier coup
            // d'œil : c'est elle qui demande une décision.
            color: reco.estEnAttente
                ? couleurs.avertissement
                : couleurs.separateur,
            width: reco.estEnAttente ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reco.champNom, style: textes.titleSmall),
                      Text(
                        '${reco.agriculteurNom} · ${reco.champRegion}',
                        style: textes.bodySmall
                            ?.copyWith(color: couleurs.texteSecondaire),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppEspaces.xs),
                BadgeStatut.validation(statut),
              ],
            ),
            const SizedBox(height: AppEspaces.sm),
            // Le classement complet : c'est sur l'écart entre les trois
            // cultures que se prend la décision.
            for (final culture in reco.top3Cultures)
              _LigneCulture(culture: culture),
            const SizedBox(height: AppEspaces.xs),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 16, color: couleurs.texteSecondaire),
                const SizedBox(width: AppEspaces.xxs),
                Text(
                  DateFormatter.formatDate(reco.dateGeneree),
                  style: textes.bodySmall
                      ?.copyWith(color: couleurs.texteSecondaire),
                ),
              ],
            ),
            if (reco.estEnAttente) ...[
              const SizedBox(height: AppEspaces.sm),
              _Decisions(
                onValider: () => _valider(context, ref),
                onCorriger: () => _ouvrirDetail(context),
                onRejeter: () => _ouvrirDetail(context),
              ),
            ] else if (reco.commentaireExpert != null &&
                reco.commentaireExpert!.isNotEmpty) ...[
              const SizedBox(height: AppEspaces.xs),
              _Commentaire(texte: reco.commentaireExpert!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Les trois décisions, côte à côte sous la carte.
class _Decisions extends StatelessWidget {
  const _Decisions({
    required this.onValider,
    required this.onCorriger,
    required this.onRejeter,
  });

  final Future<void> Function() onValider;
  final VoidCallback onCorriger;
  final VoidCallback onRejeter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Valider est plein et seul sur sa ligne : c'est le cas courant, et la
        // décision la moins coûteuse à prendre puisqu'elle confirme ce que le
        // moteur propose déjà.
        AppBouton.principal(
          libelle: 'Valider',
          icone: Icons.verified_rounded,
          onPressed: onValider,
        ),
        const SizedBox(height: AppEspaces.xs),
        Row(
          children: [
            Expanded(
              child: AppBouton.secondaire(
                libelle: 'Corriger',
                icone: Icons.edit_note_rounded,
                onPressed: onCorriger,
              ),
            ),
            const SizedBox(width: AppEspaces.xs),
            Expanded(
              child: AppBouton.secondaire(
                libelle: 'Rejeter',
                icone: Icons.block_rounded,
                ton: TonBouton.destructif,
                onPressed: onRejeter,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LigneCulture extends StatelessWidget {
  const _LigneCulture({required this.culture});

  final CultureScoreEntity culture;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;
    final premiere = culture.rang == 1;

    // Le texte et la barre ne prennent pas la même teinte pour les rangs
    // suivants. Le chiffre a besoin d'un contraste de lecture, la barre non :
    // remplie de la même encre sombre, elle pesait autant que celle du
    // premier rang et brouillait le classement.
    final teinte = premiere ? couleurs.primaire : couleurs.texteSecondaire;
    final teinteBarre = premiere ? couleurs.primaire : couleurs.bordure;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaces.xs),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${culture.rang}.',
              style: textes.labelMedium?.copyWith(color: teinte),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              culture.nom,
              style: premiere ? textes.titleSmall : textes.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppEspaces.xs),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: AppRayons.brPastille,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: culture.score),
                duration: AppMouvement.duree(context, AppDurees.moyenne),
                curve: AppCourbes.sortie,
                builder: (context, valeur, _) => LinearProgressIndicator(
                  value: valeur,
                  minHeight: 8,
                  backgroundColor: couleurs.separateur,
                  valueColor: AlwaysStoppedAnimation<Color>(teinteBarre),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppEspaces.xs),
          SizedBox(
            width: 44,
            child: Text(
              culture.scoreLabel,
              textAlign: TextAlign.end,
              style: textes.labelMedium?.copyWith(color: teinte),
            ),
          ),
        ],
      ),
    );
  }
}

class _Commentaire extends StatelessWidget {
  const _Commentaire({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Container(
      padding: const EdgeInsets.all(AppEspaces.xs),
      decoration: BoxDecoration(
        color: couleurs.fond,
        borderRadius: AppRayons.brChamp,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              size: 18, color: couleurs.texteSecondaire),
          const SizedBox(width: AppEspaces.xxs),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
