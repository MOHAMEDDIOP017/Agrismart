import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/expert_router.dart';
import '../../domain/entities/conseil_entity.dart';
import '../providers/expert_provider.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text('Mes conseils',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'À envoyer'),
            Tab(text: 'Envoyés'),
            Tab(text: 'Recos cultures'),
          ],
        ),
      ),
      body: conseilsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (conseils) {
          final brouillons =
              conseils.where((c) => c.statut == StatutConseil.brouillon).toList();
          final envoyes =
              conseils.where((c) => c.statut != StatutConseil.brouillon).toList();

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
        onPressed: () => context.goNamed(ExpertRoutes.nouveauConseilNom),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nouveau conseil',
            style: GoogleFonts.poppins(
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
            const Icon(Icons.chat_bubble_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
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

  Widget _recosCultures() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Recommandations personnalisées',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._recosMock.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.eco_outlined, color: AppColors.primary),
                title: Text(r['titre']!,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(r['detail']!,
                    style: GoogleFonts.inter(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      );

  static const _recosMock = [
    {
      'titre': 'Rotation mil-niébé recommandée',
      'detail':
          'Pour les sols sableux de la région de Thiès, alterner mil et niébé améliore la structure du sol.',
    },
    {
      'titre': 'Variété de sorgho résistant à la sécheresse',
      'detail': 'IRAT 204 recommandée pour les zones à faibles précipitations.',
    },
    {
      'titre': 'Période de semis optimale arachide',
      'detail':
          'Semer entre le 15 juin et le 15 juillet pour maximiser le rendement.',
    },
  ];
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
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (conseil.estUrgent)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('URGENT',
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conseil.agriculteurNom,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            Text(conseil.corps,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: conseil.estLu ? AppColors.primary : AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
