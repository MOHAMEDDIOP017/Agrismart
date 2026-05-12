import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(notificationsProvider.notifier).rafraichir(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Impossible de charger les notifications', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(notificationsProvider.notifier).rafraichir(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 72, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Aucune notification', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final n = notifs[i];
              return _NotifTile(notif: n, index: i);
            },
          );
        },
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  const _NotifTile({required this.notif, required this.index});

  final NotificationModel notif;
  final int index;

  IconData _iconForType(String type) => switch (type) {
        'DIAGNOSTIC_PRET' => Icons.biotech_rounded,
        'RECOMMANDATION_PRETE' => Icons.agriculture_rounded,
        'INTERVENTION_PLANIFIEE' => Icons.event_rounded,
        'CONSEIL_EXPERT' => Icons.tips_and_updates_rounded,
        'ALERTE_MALADIE' => Icons.warning_amber_rounded,
        _ => Icons.notifications_rounded,
      };

  Color _colorForType(String type) => switch (type) {
        'ALERTE_MALADIE' => AppColors.danger,
        'DIAGNOSTIC_PRET' => AppColors.primary,
        'INTERVENTION_PLANIFIEE' => Colors.orange,
        _ => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = _iconForType(notif.type);
    final color = _colorForType(notif.type);
    final dateStr = DateFormat('dd/MM · HH:mm').format(notif.dateEnvoi.toLocal());

    return InkWell(
      onTap: notif.estLue
          ? null
          : () => ref.read(notificationsProvider.notifier).marquerLue(notif.id),
      child: Container(
        color: notif.estLue ? null : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: notif.estLue ? FontWeight.normal : FontWeight.bold,
                              ),
                        ),
                      ),
                      if (!notif.estLue)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.corps,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05, end: 0);
  }
}
