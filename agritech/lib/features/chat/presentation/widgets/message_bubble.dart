import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/message_chat_entity.dart';

/// Bulle d'un message de la conversation avec l'agent AgriSmart.
///
/// Les deux interlocuteurs se distinguent par quatre choses à la fois : le
/// côté de l'écran, la couleur, la forme du coin inférieur, et la présence
/// d'un avatar du côté de l'agent. Quatre signaux plutôt qu'un, pour la même
/// raison que partout ailleurs dans l'application : une différence de teinte
/// seule ne tient pas en plein soleil.
///
/// La bulle de l'agent garde un contour plutôt qu'une ombre portée. Dans une
/// conversation qui défile, chaque ombre se recalcule à chaque image.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final MessageChatEntity message;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;
    final estUtilisateur = message.estUtilisateur;

    final (fond, texte, bordure) = switch ((estUtilisateur, message.enErreur)) {
      (_, true) => (
          couleurs.erreurVoile,
          couleurs.textePrincipal,
          couleurs.erreur
        ),
      (true, false) => (couleurs.primaire, couleurs.surPrimaire, null),
      (false, false) => (
          couleurs.surface,
          couleurs.textePrincipal,
          couleurs.separateur
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaces.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            estUtilisateur ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!estUtilisateur) ...[
            const AvatarAgent(),
            const SizedBox(width: AppEspaces.xs),
          ],
          Flexible(
            child: Semantics(
              label: estUtilisateur ? 'Vous' : 'Assistant',
              child: ConstrainedBox(
                // Une bulle ne dépasse pas 78 % de la largeur : au-delà, elle
                // touche les deux bords et son alignement cesse de dire qui
                // parle, alors que c'est le premier des quatre signaux.
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppEspaces.sm,
                    vertical: AppEspaces.xs,
                  ),
                  decoration: BoxDecoration(
                    color: fond,
                    border: bordure == null
                        ? null
                        : Border.all(color: bordure, width: 1.5),
                    // Le coin du côté de l'émetteur est coupé court : la bulle
                    // pointe vers celui qui parle.
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRayons.carte),
                      topRight: const Radius.circular(AppRayons.carte),
                      bottomLeft: Radius.circular(estUtilisateur
                          ? AppRayons.carte
                          : AppRayons.champ / 2),
                      bottomRight: Radius.circular(estUtilisateur
                          ? AppRayons.champ / 2
                          : AppRayons.carte),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.enErreur) ...[
                        Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 18, color: couleurs.erreur),
                            const SizedBox(width: AppEspaces.xxs),
                            Text(
                              'Réponse non reçue',
                              style: textes.labelMedium
                                  ?.copyWith(color: couleurs.erreur),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppEspaces.xxs),
                      ],
                      Text(
                        message.contenu,
                        style: textes.bodyMedium?.copyWith(color: texte),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de l'agent, à gauche de ses messages.
class AvatarAgent extends StatelessWidget {
  const AvatarAgent({super.key});

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: couleurs.primaire,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.eco_rounded, color: couleurs.surPrimaire, size: 18),
    );
  }
}

/// Indicateur de saisie : trois points qui se soulèvent l'un après l'autre.
///
/// Il porte une information, « la réponse arrive », et non une décoration.
/// C'est pourquoi il reste affiché quand l'utilisateur a demandé moins
/// d'animations : seuls les points cessent alors de bouger, et la mention
/// parlée continue de dire ce qui se passe.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: AppDurees.saisie,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMouvement.reduit(context)) {
      _controleur.stop();
    } else if (!_controleur.isAnimating) {
      _controleur.repeat();
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Semantics(
      liveRegion: true,
      label: 'L\'assistant prépare sa réponse',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppEspaces.xs),
        child: Row(
          children: [
            const AvatarAgent(),
            const SizedBox(width: AppEspaces.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspaces.sm,
                vertical: AppEspaces.sm,
              ),
              decoration: BoxDecoration(
                color: couleurs.surface,
                border: Border.all(color: couleurs.separateur, width: 1.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRayons.carte),
                  topRight: Radius.circular(AppRayons.carte),
                  bottomRight: Radius.circular(AppRayons.carte),
                  bottomLeft: Radius.circular(AppRayons.champ / 2),
                ),
              ),
              child: AnimatedBuilder(
                animation: _controleur,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: AppEspaces.xxs),
                      _Point(
                        couleur: couleurs.texteSecondaire,
                        // Chaque point est décalé d'un tiers de cycle :
                        // l'onde parcourt les trois de gauche à droite.
                        avancement: (_controleur.value + i / 3) % 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.couleur, required this.avancement});

  final Color couleur;
  final double avancement;

  @override
  Widget build(BuildContext context) {
    // Le point monte sur la première moitié du cycle et redescend sur la
    // seconde, ce qui évite le saut d'une remise à zéro.
    final hauteur = avancement < 0.5 ? avancement * 2 : (1 - avancement) * 2;

    return Transform.translate(
      offset: Offset(0, -3 * hauteur),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.5 + 0.5 * hauteur),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
