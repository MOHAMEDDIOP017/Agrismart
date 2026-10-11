import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/champ_entity.dart';
import '../providers/champ_provider.dart';
import '../widgets/champ_card.dart';

/// Détail d'une parcelle.
///
/// L'écran n'avait pas de bouton principal : on y consultait des
/// informations, et il fallait repartir à l'accueil pour demander une
/// recommandation sur la parcelle qu'on avait justement sous les yeux.
/// « Obtenir une recommandation » est maintenant la première chose sous le
/// nom du champ, et elle emporte la parcelle avec elle.
///
/// L'en-tête illustré de 250 points a été remplacé par la vignette dessinée de
/// la liste. Il affichait la même photo générique distante pour toutes les
/// parcelles, occupait le tiers de l'écran et ne disait rien. La vignette
/// conserve la transition depuis la liste, en emportant le même repère visuel
/// d'un écran à l'autre.
class ChampDetailScreen extends ConsumerWidget {
  const ChampDetailScreen({super.key, required this.champId});

  final String champId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champAsync = ref.watch(champByIdProvider(champId));

    return Scaffold(
      appBar: BarreTitre(
        titre: champAsync.valueOrNull?.nom ?? 'Parcelle',
        routeRepli: AppRoutes.champs,
      ),
      body: champAsync.when(
        loading: () => const SqueletteListe.champs(nombre: 2),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(champByIdProvider(champId)),
        ),
        data: (champ) {
          if (champ == null) {
            return EtatVide(
              titre: 'Parcelle introuvable',
              message: 'Elle a peut-être été supprimée depuis un autre '
                  'appareil.',
              sujet: SujetIllustration.recherche,
              libelleAction: 'Revenir à mes champs',
              onAction: () => context.go(AppRoutes.champs),
            );
          }
          return _Contenu(champ: champ);
        },
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.champ});

  final ChampEntity champ;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: AppEspaces.liste,
      children: [
        _EnTeteParcelle(champ: champ),
        const SizedBox(height: AppEspaces.md),

        // Action principale : elle emporte la parcelle, pour éviter d'avoir à
        // la rechoisir sur l'écran suivant.
        AppBouton.principal(
          libelle: 'Obtenir une recommandation',
          icone: Icons.auto_awesome_rounded,
          onPressed: () => context.push(
            '${AppRoutes.recommandations}?champId=${champ.id}',
          ),
        ),

        const SizedBox(height: AppEspaces.lg),
        _Informations(champ: champ),

        if (champ.latitude != null && champ.longitude != null) ...[
          const SizedBox(height: AppEspaces.lg),
          _Localisation(champ: champ),
        ],

        const SizedBox(height: AppEspaces.lg),
        _Historique(champ: champ),

        const SizedBox(height: AppEspaces.lg),
        _ActionsSecondaires(champ: champ),
      ],
    );
  }
}

class _EnTeteParcelle extends StatelessWidget {
  const _EnTeteParcelle({required this.champ});

  final ChampEntity champ;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Container(
      padding: AppEspaces.carte,
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: couleurs.separateur),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VignetteChamp(
            champ: champ,
            cote: 88,
            // Même étiquette que dans la liste : la vignette se déplace d'un
            // écran à l'autre au lieu de réapparaître.
            heroTag: 'champ_image_${champ.id}',
          ),
          const SizedBox(width: AppEspaces.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le nom n'est pas répété ici : la barre de titre le porte
                // déjà, à quelques points au-dessus.
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 18, color: couleurs.texteSecondaire),
                    const SizedBox(width: AppEspaces.xxs),
                    Expanded(
                      child: Text(
                        champ.adresse,
                        style: textes.bodyMedium
                            ?.copyWith(color: couleurs.texteSecondaire),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppEspaces.xs),
                BadgeStatut.statutChamp(champ.statut),
                // La culture en place est écrite en toutes lettres plutôt que
                // posée en second badge. Une pastille verte à icône d'herbe
                // juste à côté de « En cours », vert à icône d'herbe lui
                // aussi, se lisait comme un doublon : deux informations
                // différentes dans la même forme et la même couleur.
                if (champ.culture != null && champ.culture!.isNotEmpty) ...[
                  const SizedBox(height: AppEspaces.xs),
                  Row(
                    // L'icône s'aligne sur la première ligne du texte : au
                    // centre, elle flottait à hauteur de la deuxième ligne dès
                    // que le libellé passait à la ligne.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.eco_rounded,
                            size: 18, color: couleurs.primaire),
                      ),
                      const SizedBox(width: AppEspaces.xxs),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: textes.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Culture en place : ',
                                style:
                                    TextStyle(color: couleurs.texteSecondaire),
                              ),
                              TextSpan(text: champ.culture!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Informations extends StatelessWidget {
  const _Informations({required this.champ});

  final ChampEntity champ;

  @override
  Widget build(BuildContext context) {
    return _Section(
      titre: 'Informations',
      enfant: Column(
        children: [
          _LigneInfo(
            icone: Icons.straighten_rounded,
            libelle: 'Superficie',
            valeur: champ.superficieFormatee,
          ),
          _LigneInfo(
            icone: Icons.layers_outlined,
            libelle: 'Type de sol',
            valeur: champ.typeSol,
          ),
          _LigneInfo(
            icone: Icons.place_outlined,
            libelle: 'Adresse',
            valeur: champ.adresse,
            dernier: true,
          ),
        ],
      ),
    );
  }
}

class _Localisation extends StatelessWidget {
  const _Localisation({required this.champ});

  final ChampEntity champ;

  @override
  Widget build(BuildContext context) {
    return _Section(
      titre: 'Position GPS',
      enfant: _LigneInfo(
        icone: Icons.my_location_rounded,
        libelle: 'Coordonnées',
        valeur: champ.localisation,
        dernier: true,
      ),
    );
  }
}

class _Historique extends StatelessWidget {
  const _Historique({required this.champ});

  final ChampEntity champ;

  @override
  Widget build(BuildContext context) {
    return _Section(
      titre: 'Historique',
      enfant: Column(
        children: [
          _LigneInfo(
            icone: Icons.add_circle_outline_rounded,
            libelle: 'Créée le',
            valeur: DateFormatter.formatDate(champ.dateCreation),
            dernier: champ.dateModification == null,
          ),
          if (champ.dateModification != null)
            _LigneInfo(
              icone: Icons.edit_outlined,
              libelle: 'Modifiée le',
              valeur: DateFormatter.formatDate(champ.dateModification!),
              dernier: true,
            ),
        ],
      ),
    );
  }
}

/// Modifier et supprimer, en boutons écrits.
///
/// Ces deux actions étaient des gestes de balayage sur la carte de la liste,
/// invisibles et sans libellé, dont l'un supprimait la parcelle.
class _ActionsSecondaires extends ConsumerWidget {
  const _ActionsSecondaires({required this.champ});

  final ChampEntity champ;

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogue) => AlertDialog(
        title: const Text('Supprimer cette parcelle ?'),
        content: Text(
          '« ${champ.nom} » et son historique de recommandations seront '
          'effacés. Cette action est définitive.',
        ),
        actions: [
          AppBouton.texte(
            libelle: 'Annuler',
            onPressed: () => Navigator.pop(dialogue, false),
          ),
          AppBouton.texte(
            libelle: 'Supprimer',
            ton: TonBouton.destructif,
            onPressed: () => Navigator.pop(dialogue, true),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    await ref.read(champProvider.notifier).deleteChamp(champ.id);
    if (!context.mounted) return;
    context.go(AppRoutes.champs);
    RetourAction.succes(context, 'Parcelle « ${champ.nom} » supprimée');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppBouton.secondaire(
          libelle: 'Modifier la parcelle',
          icone: Icons.edit_outlined,
          onPressed: () =>
              context.push('${AppRoutes.champs}/form?id=${champ.id}'),
        ),
        const SizedBox(height: AppEspaces.xs),
        AppBouton.texte(
          libelle: 'Supprimer la parcelle',
          icone: Icons.delete_outline_rounded,
          ton: TonBouton.destructif,
          onPressed: () => _supprimer(context, ref),
        ),
      ],
    );
  }
}

// ── Briques ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.enfant});

  final String titre;
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppEspaces.xs),
        Container(
          decoration: BoxDecoration(
            color: couleurs.surface,
            borderRadius: AppRayons.brCarte,
            border: Border.all(color: couleurs.separateur),
          ),
          child: enfant,
        ),
      ],
    );
  }
}

class _LigneInfo extends StatelessWidget {
  const _LigneInfo({
    required this.icone,
    required this.libelle,
    required this.valeur,
    this.dernier = false,
  });

  final IconData icone;
  final String libelle;
  final String valeur;
  final bool dernier;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: dernier
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: couleurs.separateur),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: couleurs.primaire),
          const SizedBox(width: AppEspaces.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle,
                  style: textes.bodySmall
                      ?.copyWith(color: couleurs.texteSecondaire),
                ),
                Text(valeur, style: textes.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
