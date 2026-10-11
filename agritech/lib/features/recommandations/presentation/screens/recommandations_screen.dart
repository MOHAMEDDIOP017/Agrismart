import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../champs/domain/entities/champ_entity.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../../champs/presentation/widgets/champ_card.dart';
import '../providers/recommandation_provider.dart';
import '../widgets/culture_card.dart';
import '../widgets/mention_sources_donnees.dart';
import 'recommandation_detail_screen.dart';

/// Résultat de recommandation.
///
/// L'écran traverse quatre états, et chacun montre quelque chose : le choix de
/// la parcelle, l'analyse en cours, le classement, ou l'échec. Aucun ne laisse
/// de page blanche.
class RecommandationsScreen extends ConsumerStatefulWidget {
  const RecommandationsScreen({super.key, this.champId});

  /// Parcelle déjà choisie, transmise par l'écran de détail d'un champ.
  final String? champId;

  @override
  ConsumerState<RecommandationsScreen> createState() =>
      _RecommandationsScreenState();
}

class _RecommandationsScreenState extends ConsumerState<RecommandationsScreen> {
  @override
  void initState() {
    super.initState();
    final id = widget.champId;
    if (id == null || id.isEmpty) return;
    // Après la première image : la sélection modifie un provider, ce qui ne
    // peut pas se faire pendant la construction de l'arbre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(recommandationProvider.notifier).selectChamp(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(recommandationProvider);
    final champsAsync = ref.watch(champProvider);

    return Scaffold(
      appBar: BarreTitre(
        titre: 'Recommandations',
        sousTitre: _nomChampChoisi(champsAsync.valueOrNull, etat),
        routeRepli: AppRoutes.dashboard,
      ),
      body: _corps(etat, champsAsync),
    );
  }

  String? _nomChampChoisi(
    List<ChampEntity>? champs,
    RecommandationState etat,
  ) {
    final id = etat.champIdSelectionne;
    if (champs == null || id == null) return null;
    for (final champ in champs) {
      if (champ.id == id) return champ.nom;
    }
    return null;
  }

  Widget _corps(
    RecommandationState etat,
    AsyncValue<List<ChampEntity>> champsAsync,
  ) {
    if (etat.isAnalysing) {
      return _AnalyseEnCours(message: etat.progressMessage);
    }

    if (etat.error != null && etat.recommandations.isEmpty) {
      return EtatErreur(
        erreur: etat.error,
        onReessayer: () {
          final id = etat.champIdSelectionne;
          if (id != null) {
            ref.read(recommandationProvider.notifier).analyserAvecIA(id);
          }
        },
      );
    }

    if (etat.recommandations.isNotEmpty) {
      return _Resultats(
        etat: etat,
        onRelancer: () {
          final id = etat.champIdSelectionne;
          ref.invalidate(recommandationProvider);
          if (id != null) {
            ref.read(recommandationProvider.notifier).selectChamp(id);
          }
        },
      );
    }

    return champsAsync.when(
      loading: () => const SqueletteListe.champs(nombre: 3),
      error: (e, _) => EtatErreur(
        erreur: e,
        onReessayer: () => ref.invalidate(champProvider),
      ),
      data: (champs) => _ChoixParcelle(
        champs: champs,
        choisi: etat.champIdSelectionne,
        onChoisir: (id) =>
            ref.read(recommandationProvider.notifier).selectChamp(id),
        onLancer: (id) =>
            ref.read(recommandationProvider.notifier).analyserAvecIA(id),
      ),
    );
  }
}

// ── Choix de la parcelle ─────────────────────────────────────────────────────

/// Choix de la parcelle à analyser.
///
/// Les parcelles étaient listées en `RadioListTile`, dont la cible utile se
/// réduit au petit cercle et dont l'état coché ne se distingue que par une
/// teinte de fond à 5 % d'opacité. Chaque parcelle est maintenant une carte
/// entière, touchable sur toute sa surface, et la sélection se lit à son
/// contour et à sa coche.
///
/// Le bouton reste désactivé tant qu'aucune parcelle n'est choisie. Il
/// affichait auparavant un message « Veuillez sélectionner un champ » après
/// coup : faire appuyer quelqu'un pour lui apprendre qu'il ne fallait pas
/// encore appuyer.
class _ChoixParcelle extends StatelessWidget {
  const _ChoixParcelle({
    required this.champs,
    required this.choisi,
    required this.onChoisir,
    required this.onLancer,
  });

  final List<ChampEntity> champs;
  final String? choisi;
  final void Function(String) onChoisir;
  final void Function(String) onLancer;

  @override
  Widget build(BuildContext context) {
    if (champs.isEmpty) {
      return EtatVide(
        titre: 'Aucune parcelle à analyser',
        message: 'Ajoutez une parcelle : AgriSmart a besoin de sa position et '
            'de son type de sol pour proposer des cultures.',
        libelleAction: 'Ajouter un champ',
        iconeAction: Icons.add_rounded,
        onAction: () => context.push('${AppRoutes.champs}/form'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: AppEspaces.liste,
            itemCount: champs.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppEspaces.entreCartes),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppEspaces.xs),
                  child: Text(
                    'Sur quelle parcelle ?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                );
              }
              final champ = champs[index - 1];
              return _CarteChoix(
                champ: champ,
                choisi: champ.id == choisi,
                onTap: () => onChoisir(champ.id),
              );
            },
          ),
        ),
        _BarreAction(
          child: AppBouton.principal(
            libelle: 'Lancer l\'analyse',
            icone: Icons.auto_awesome_rounded,
            onPressed: choisi == null ? null : () => onLancer(choisi!),
          ),
        ),
      ],
    );
  }
}

class _CarteChoix extends StatelessWidget {
  const _CarteChoix({
    required this.champ,
    required this.choisi,
    required this.onTap,
  });

  final ChampEntity champ;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Semantics(
      selected: choisi,
      child: ZoneTactile(
        onTap: onTap,
        rayon: AppRayons.brCarte,
        tailleMinimale: null,
        etiquette: 'Parcelle ${champ.nom}',
        child: Container(
          padding: AppEspaces.carte,
          decoration: BoxDecoration(
            color: choisi ? couleurs.primaireVoile : couleurs.surface,
            borderRadius: AppRayons.brCarte,
            border: Border.all(
              color: choisi ? couleurs.primaire : couleurs.separateur,
              width: choisi ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              VignetteChamp(
                champ: champ,
                cote: 48,
                couleurFond: choisi ? couleurs.surface : null,
              ),
              const SizedBox(width: AppEspaces.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(champ.nom, style: textes.titleSmall),
                    Text(
                      '${champ.superficieFormatee} · sol ${champ.typeSol}',
                      style: textes.bodySmall
                          ?.copyWith(color: couleurs.texteSecondaire),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppEspaces.xs),
              // Coche pleine ou cercle vide : l'état choisi ne repose pas sur
              // la seule couleur de fond.
              Icon(
                choisi
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: choisi ? couleurs.primaire : couleurs.bordure,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Analyse en cours ─────────────────────────────────────────────────────────

/// Attente de la réponse du moteur.
///
/// L'écran affichait un cerveau qui grossissait et rétrécissait en boucle, une
/// barre de progression indéterminée et un message. Le squelette des trois
/// cartes le remplace : il annonce la forme de ce qui arrive, donc le nombre
/// de cultures et la place de leur taux d'aptitude, au lieu de faire patienter
/// devant une icône.
class _AnalyseEnCours extends StatelessWidget {
  const _AnalyseEnCours({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: couleurs.primaireVoile,
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.md,
            vertical: AppEspaces.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(couleurs.primaire),
                ),
              ),
              const SizedBox(width: AppEspaces.sm),
              Expanded(
                child: Text(
                  // Le message vient du provider, qui décrit l'étape en cours.
                  message?.trim().isNotEmpty == true
                      ? message!
                      : 'Analyse de votre parcelle…',
                  // Annoncé aux lecteurs d'écran à chaque changement d'étape.
                  semanticsLabel: message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: SqueletteListe.cultures()),
      ],
    );
  }
}

// ── Résultats ────────────────────────────────────────────────────────────────

class _Resultats extends StatelessWidget {
  const _Resultats({required this.etat, required this.onRelancer});

  final RecommandationState etat;
  final VoidCallback onRelancer;

  @override
  Widget build(BuildContext context) {
    final recos = etat.recommandations;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: AppEspaces.liste,
            itemCount: recos.length + 2,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppEspaces.entreCartes),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppEspaces.xs),
                  child: Text(
                    recos.length > 1
                        ? '${recos.length} cultures conseillées'
                        : 'Culture conseillée',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                );
              }

              if (index == recos.length + 1) {
                // La provenance des données ferme la liste, en petit : elle
                // compte pour qui veut savoir sur quoi repose le classement,
                // sans s'interposer entre l'agriculteur et sa réponse.
                return Padding(
                  padding: const EdgeInsets.only(top: AppEspaces.sm),
                  child: MentionSourcesDonnees(
                    sources: etat.sourcesDonnees,
                    zoneAgroecologique: recos.first.zoneAgroecologique,
                    padding: EdgeInsets.zero,
                  ),
                );
              }

              final reco = recos[index - 1];
              return CultureCard(
                recommandation: reco,
                index: index - 1,
                onTap: () => _ouvrirDetail(context, reco),
              );
            },
          ),
        ),
        _BarreAction(
          child: AppBouton.secondaire(
            libelle: 'Analyser une autre parcelle',
            icone: Icons.refresh_rounded,
            onPressed: onRelancer,
          ),
        ),
      ],
    );
  }

  void _ouvrirDetail(BuildContext context, dynamic recommandation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommandationDetailSheet(recommandation: recommandation),
    );
  }
}

// ── Brique commune ───────────────────────────────────────────────────────────

/// Barre d'action ancrée en bas, hors de la zone qui défile.
///
/// L'action principale reste atteignable sans remonter la liste, ce qui compte
/// quand le classement en fait défiler plusieurs écrans.
class _BarreAction extends StatelessWidget {
  const _BarreAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Container(
      decoration: BoxDecoration(
        color: couleurs.surface,
        border: Border(top: BorderSide(color: couleurs.separateur)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppEspaces.md),
          child: child,
        ),
      ),
    );
  }
}
