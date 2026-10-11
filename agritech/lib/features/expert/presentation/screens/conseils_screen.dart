import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../../domain/entities/conseil_entity.dart';
import '../../domain/entities/recommandation_expert_entity.dart';
import '../providers/expert_provider.dart';
import '../../../../shared/widgets/widgets.dart';

/// Gestion des conseils et recommandations
class ConseilsScreen extends ConsumerStatefulWidget {
  const ConseilsScreen({super.key});

  @override
  ConsumerState<ConseilsScreen> createState() => _ConseilsScreenState();
}

class _ConseilsScreenState extends ConsumerState<ConseilsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conseilsAsync = ref.watch(conseilsProvider);

    return Scaffold(
      backgroundColor: context.couleurs.fond,
      appBar: AppBar(
        backgroundColor: context.couleurs.primaireFonce,
        foregroundColor: Colors.white,
        title: Text('Mes conseils',
            style: AppTypography.police(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              AppTypography.police(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'À envoyer'),
            Tab(text: 'Envoyés'),
            Tab(text: 'Recos cultures'),
          ],
        ),
      ),
      body: conseilsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EtatErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(conseilsProvider),
        ),
        data: (conseils) {
          final brouillons = conseils
              .where((c) => c.statut == StatutConseil.brouillon)
              .toList();
          final envoyes = conseils
              .where((c) => c.statut != StatutConseil.brouillon)
              .toList();

          return TabBarView(
            controller: _tabs,
            children: [
              // Brouillons
              _conseilsList(brouillons, 'Aucun conseil en brouillon'),
              // Envoyés
              _conseilsList(envoyes, 'Aucun conseil envoyé'),
              // Recommandations cultures (statique)
              _recosCultures(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(ExpertRoutes.nouveauConseilNom),
        backgroundColor: context.couleurs.primaire,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nouveau conseil',
            style: AppTypography.police(
                fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _conseilsList(List<ConseilEntity> liste, String emptyMsg) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48, color: context.couleurs.texteSecondaire),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: AppTypography.police(
                    color: context.couleurs.texteSecondaire)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: liste.length,
      itemBuilder: (_, i) => _ConseilCard(conseil: liste[i]),
    );
  }

  Widget _recosCultures() {
    final async = ref.watch(recommandationsExpertProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EtatErreur(
        erreur: e,
        onReessayer: () => ref.invalidate(recommandationsExpertProvider),
      ),
      data: (state) {
        final validees = state.recommandations
            .where((r) => r.estValidee || r.estCorrigee)
            .toList();
        if (validees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_outlined,
                    size: 48, color: context.couleurs.texteSecondaire),
                const SizedBox(height: 12),
                Text('Aucune recommandation validée',
                    style: AppTypography.police(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.couleurs.textePrincipal)),
                const SizedBox(height: 6),
                Text(
                    'Les recommandations validées ou corrigées apparaîtront ici.',
                    style: AppTypography.police(
                        fontSize: 12, color: context.couleurs.texteSecondaire),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: validees.length,
          itemBuilder: (_, i) => _RecoValideeCard(reco: validees[i]),
        );
      },
    );
  }
}

class _ConseilCard extends StatelessWidget {
  const _ConseilCard({required this.conseil});
  final ConseilEntity conseil;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: conseil.typeConseil.couleur.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(conseil.typeConseil.icone,
              color: conseil.typeConseil.couleur, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(conseil.titre,
                  style: AppTypography.police(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (conseil.estUrgent)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.couleurs.erreur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('URGENT',
                    style: AppTypography.police(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: context.couleurs.erreur)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conseil.agriculteurNom,
                style: AppTypography.police(
                    fontSize: 11, color: context.couleurs.texteSecondaire)),
            Text(conseil.corps,
                style: AppTypography.police(
                    fontSize: 11, color: context.couleurs.texteSecondaire),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: conseil.estLu
                ? context.couleurs.primaire
                : context.couleurs.texteSecondaire,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _RecoValideeCard extends StatelessWidget {
  const _RecoValideeCard({required this.reco});
  final RecommandationExpertEntity reco;

  @override
  Widget build(BuildContext context) {
    final couleur =
        reco.estCorrigee ? context.couleurs.info : context.couleurs.primaire;
    final premiere = reco.premiereCulture;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco_outlined, color: couleur, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    premiere?.nom ?? 'Culture non définie',
                    style: AppTypography.police(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: couleur),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reco.statutLibelle,
                    style: AppTypography.police(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: couleur),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${reco.champNom} · ${reco.agriculteurNom}',
              style: AppTypography.police(
                  fontSize: 11, color: context.couleurs.texteSecondaire),
            ),
            if (reco.commentaireExpert != null) ...[
              const SizedBox(height: 4),
              Text(
                reco.commentaireExpert!,
                style: AppTypography.police(
                    fontSize: 11,
                    color: context.couleurs.texteSecondaire,
                    fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              reco.tempsEcoule,
              style: AppTypography.police(
                  fontSize: 10, color: context.couleurs.texteSecondaire),
            ),
          ],
        ),
      ),
    );
  }
}
