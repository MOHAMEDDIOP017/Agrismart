import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/champ_provider.dart';
import '../widgets/champ_card.dart';

/// Liste des parcelles de l'agriculteur.
///
/// Deux éléments ont disparu.
///
/// **La loupe de la barre de titre** n'était reliée à rien : son `onPressed`
/// était vide. Un bouton qui ne fait rien use la confiance plus sûrement qu'un
/// bouton absent. La recherche n'a de sens qu'au-delà d'une dizaine de
/// parcelles, ce qui n'est pas le cas d'une exploitation familiale.
///
/// **Le bouton flottant à deux branches.** Il se dépliait sur deux options,
/// dont « Localiser GPS » qui affichait un message « Localisation GPS en
/// cours… » et s'arrêtait là, sans rien localiser. Il reste une seule action,
/// écrite en toutes lettres.
class ChampsListScreen extends ConsumerWidget {
  const ChampsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champsAsync = ref.watch(champProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes champs')),
      floatingActionButton: AppBoutonFlottant(
        libelle: 'Ajouter un champ',
        icone: Icons.add_rounded,
        onPressed: () => context.push('${AppRoutes.champs}/form'),
      ),
      body: champsAsync.when(
        loading: () => const SqueletteListe.champs(),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(champProvider),
        ),
        data: (champs) {
          if (champs.isEmpty) {
            return EtatVide(
              titre: 'Aucune parcelle enregistrée',
              message: 'Ajoutez votre première parcelle pour recevoir des '
                  'recommandations de culture.',
              libelleAction: 'Ajouter un champ',
              iconeAction: Icons.add_rounded,
              onAction: () => context.push('${AppRoutes.champs}/form'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(champProvider.notifier).refresh(),
            child: ListView.separated(
              padding: AppEspaces.liste,
              itemCount: champs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppEspaces.entreCartes),
              itemBuilder: (context, index) => ApparitionCascade(
                index: index,
                child: ChampCard(
                  champ: champs[index],
                  onTap: () =>
                      context.push('${AppRoutes.champs}/${champs[index].id}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
