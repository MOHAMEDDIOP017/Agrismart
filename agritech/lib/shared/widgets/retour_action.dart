import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../erreurs/message_erreur.dart';

/// Confirmations et échecs d'action, dans une forme unique.
///
/// Une action qui réussit sans rien dire laisse dans le doute : sur une
/// connexion lente, rien ne distingue « c'est enregistré » de « l'appui n'a
/// pas été pris en compte ». Chaque écran répondait à sa façon, quand il
/// répondait, et le message d'échec affichait la trace d'exception.
///
/// Le bandeau porte une icône en plus de sa couleur, pour la même raison que
/// les badges : la teinte seule ne dit rien en plein soleil ni à qui distingue
/// mal le vert du rouge.
class RetourAction {
  RetourAction._();

  /// Confirme une action réussie.
  ///
  /// [texte] nomme ce qui vient de se passer, au passé et en une phrase :
  /// « Parcelle enregistrée », « Recommandation validée ». Un « Succès ! » ne
  /// dit pas de quoi il s'agit quand deux actions s'enchaînent.
  static void succes(BuildContext context, String texte) {
    _afficher(
      context,
      texte: texte,
      icone: Icons.check_circle_rounded,
      fond: context.couleurs.succes,
      surFond: context.couleurs.surSucces,
    );
  }

  /// Signale un échec, en traduisant l'exception.
  static void echec(BuildContext context, Object? erreur) {
    _afficher(
      context,
      texte: MessageErreur.pour(erreur),
      icone: Icons.error_outline_rounded,
      fond: context.couleurs.erreur,
      surFond: context.couleurs.surErreur,
      // Un échec se lit plus longtemps qu'une confirmation : il demande de
      // décider quoi faire ensuite.
      duree: const Duration(seconds: 6),
    );
  }

  static void _afficher(
    BuildContext context, {
    required String texte,
    required IconData icone,
    required Color fond,
    required Color surFond,
    Duration duree = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // Un seul bandeau à la fois : deux actions enchaînées empileraient leurs
    // confirmations, et la seconde attendrait la fin de la première.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: fond,
        duration: duree,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRayons.brChamp),
        content: Row(
          children: [
            Icon(icone, color: surFond, size: 22),
            const SizedBox(width: AppEspaces.xs),
            Expanded(
              child: Text(
                texte,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: surFond),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marque de confirmation affichée en plein écran après une action.
///
/// Sert aux fins de parcours, après l'enregistrement d'une parcelle par
/// exemple, là où un bandeau passerait inaperçu parce que l'écran change au
/// même moment.
///
/// L'apparition rebondit légèrement, ce qui est le seul endroit de
/// l'application où une courbe élastique est employée : le rebond dit que
/// quelque chose vient d'aboutir. Il reste dans le budget de 400 ms et
/// disparaît quand l'utilisateur a demandé moins d'animations.
class MarqueSucces extends StatelessWidget {
  const MarqueSucces({super.key, required this.texte, this.taille = 88});

  final String texte;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final reduit = AppMouvement.reduit(context);

    final pastille = Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: couleurs.succesVoile,
        shape: BoxShape.circle,
        border: Border.all(color: couleurs.succes, width: 2),
      ),
      child: Icon(
        Icons.check_rounded,
        size: taille * 0.5,
        color: couleurs.succes,
      ),
    );

    return Semantics(
      liveRegion: true,
      label: texte,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reduit)
            pastille
          else
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppDurees.plafond,
              curve: Curves.elasticOut,
              builder: (context, valeur, enfant) =>
                  Transform.scale(scale: valeur, child: enfant),
              child: pastille,
            ),
          const SizedBox(height: AppEspaces.md),
          Text(
            texte,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
