import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/alerte_model.dart';
import '../providers/alertes_provider.dart';
import '../widgets/alerte_card.dart';
import '../../../../shared/widgets/widgets.dart';

/// Écran liste des alertes avec filtres par niveau
class AlertesScreen extends ConsumerStatefulWidget {
  const AlertesScreen({super.key});

  @override
  ConsumerState<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends ConsumerState<AlertesScreen> {
  String _filtreActif = 'Tous';

  static const _filtres = [
    'Tous',
    AppConstants.alerteCritique,
    AppConstants.alerteEleve,
    AppConstants.alerteModere,
    AppConstants.alerteFaible,
  ];

  static const _filtreLabels = {
    'Tous': 'Tous',
    AppConstants.alerteCritique: 'Critique',
    AppConstants.alerteEleve: 'Élevé',
    AppConstants.alerteModere: 'Modéré',
    AppConstants.alerteFaible: 'Faible',
  };

  List<AlerteModel> _filtrer(List<AlerteModel> toutes) {
    if (_filtreActif == 'Tous') return toutes;
    return toutes.where((a) => a.niveau == _filtreActif).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alertesAsync = ref.watch(alertesProvider);
    final toutes = alertesAsync.valueOrNull ?? [];
    final alertes = _filtrer(toutes);
    final nonLues = toutes.where((a) => !a.isLue).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Mes alertes'),
            if (nonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.couleurs.erreur,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$nonLues',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (alertesAsync.isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(alertesProvider.notifier).rafraichir(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtres par niveau
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filtres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filtre = _filtres[i];
                final isSelected = _filtreActif == filtre;
                return FilterChip(
                  label: Text(_filtreLabels[filtre] ?? filtre),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _filtreActif = filtre),
                  selectedColor:
                      context.couleurs.primaire.withValues(alpha: 0.15),
                  checkmarkColor: context.couleurs.primaire,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? context.couleurs.primaire
                        : context.couleurs.texteSecondaire,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Liste des alertes
          Expanded(
            child: alertes.isEmpty
                ? const EtatVide(
                    titre: 'Aucune alerte',
                    message: 'Aucune alerte pour ce niveau de filtre.',
                    sujet: SujetIllustration.recherche,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: alertes.length,
                    itemBuilder: (context, index) => ApparitionCascade(
                      index: index,
                      child: AlerteCard(
                        alerte: alertes[index],
                        index: index,
                        onTap: () =>
                            context.push('/home/alertes/${alertes[index].id}'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
