import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../providers/champ_provider.dart';
import '../widgets/champ_card.dart';

/// Écran liste des champs avec AnimatedList + pull-to-refresh + FAB SpeedDial
class ChampsListScreen extends ConsumerStatefulWidget {
  const ChampsListScreen({super.key});

  @override
  ConsumerState<ChampsListScreen> createState() => _ChampsListScreenState();
}

class _ChampsListScreenState extends ConsumerState<ChampsListScreen>
    with SingleTickerProviderStateMixin {
  bool _fabExpanded = false;
  late final AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabExpanded = !_fabExpanded);
    _fabExpanded ? _fabCtrl.forward() : _fabCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final champsAsync = ref.watch(champProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Champs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          champsAsync.when(
            loading: () => const ShimmerList(count: 5),
            error: (e, _) => EmptyStateWidget(
              title: 'Erreur de chargement',
              message: e.toString(),
              icon: Icons.error_outline,
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(champProvider),
            ),
            data: (champs) {
              if (champs.isEmpty) {
                return EmptyStateWidget(
                  title: 'Aucun champ enregistré',
                  message: 'Ajoutez votre premier champ pour commencer à suivre vos cultures.',
                  icon: Icons.terrain_outlined,
                  actionLabel: 'Ajouter un champ',
                  onAction: () => context.push('/home/champs/form'),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(champProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: champs.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemBuilder: (context, index) => ChampCard(
                    champ: champs[index],
                    onTap: () => context.push('/home/champs/${champs[index].id}'),
                    onEdit: () => context.push(
                      '/home/champs/form?id=${champs[index].id}',
                    ),
                    onDelete: () => ref
                        .read(champProvider.notifier)
                        .deleteChamp(champs[index].id),
                  )
                      .animate()
                      .fadeIn(delay: (index * 80).ms, duration: 350.ms)
                      .slideX(begin: 0.2, end: 0),
                ),
              );
            },
          ),

          // SpeedDial FAB
          if (_fabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFab,
                child: Container(color: Colors.black26),
              ),
            ),
          Positioned(
            bottom: 24,
            right: 16,
            child: _SpeedDial(
              isExpanded: _fabExpanded,
              controller: _fabCtrl,
              onToggle: _toggleFab,
              onAddManual: () {
                _toggleFab();
                context.push('/home/champs/form');
              },
              onGPS: () {
                _toggleFab();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Localisation GPS en cours...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedDial extends StatelessWidget {
  const _SpeedDial({
    required this.isExpanded,
    required this.controller,
    required this.onToggle,
    required this.onAddManual,
    required this.onGPS,
  });

  final bool isExpanded;
  final AnimationController controller;
  final VoidCallback onToggle;
  final VoidCallback onAddManual;
  final VoidCallback onGPS;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Option GPS
        if (isExpanded) ...[
          _SpeedDialOption(
            label: 'Localiser GPS',
            icon: Icons.my_location_rounded,
            color: AppColors.teal,
            onTap: onGPS,
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          _SpeedDialOption(
            label: 'Ajouter manuellement',
            icon: Icons.add_rounded,
            color: AppColors.primary,
            onTap: onAddManual,
          ).animate().fadeIn(duration: 200.ms, delay: 60.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
        ],

        // FAB principal
        FloatingActionButton(
          onPressed: onToggle,
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: 0.125).animate(controller),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _SpeedDialOption extends StatelessWidget {
  const _SpeedDialOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                )
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
