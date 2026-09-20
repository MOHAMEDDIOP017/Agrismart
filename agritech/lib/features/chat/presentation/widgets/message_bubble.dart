import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_chat_entity.dart';

/// Bulle d'un message de la conversation avec l'agent AgriSmart
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final MessageChatEntity message;

  @override
  Widget build(BuildContext context) {
    final estUtilisateur = message.estUtilisateur;
    final couleurFond = message.enErreur
        ? AppColors.danger.withValues(alpha: 0.08)
        : estUtilisateur
            ? AppColors.primary
            : AppColors.surface;
    final couleurTexte = message.enErreur
        ? AppColors.danger
        : estUtilisateur
            ? Colors.white
            : AppColors.textPrimary;

    return Row(
      mainAxisAlignment:
          estUtilisateur ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!estUtilisateur) ...[
          const _AvatarAgent(),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(estUtilisateur ? 16 : 4),
                bottomRight: Radius.circular(estUtilisateur ? 4 : 16),
              ),
              border: estUtilisateur || message.enErreur
                  ? null
                  : Border.all(color: AppColors.border),
              boxShadow: estUtilisateur
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              message.contenu,
              style: TextStyle(color: couleurTexte, fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, end: 0);
  }
}

class _AvatarAgent extends StatelessWidget {
  const _AvatarAgent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
    );
  }
}

/// Indicateur "l'agent est en train d'écrire..."
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _AvatarAgent(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(delay: (i * 150).ms, duration: 400.ms)
                  .then()
                  .fadeOut(duration: 400.ms),
            ),
          ),
        ),
      ],
    );
  }
}
