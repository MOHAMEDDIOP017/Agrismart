import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../erreurs/message_erreur.dart';
import 'app_bouton.dart';
import 'etat_vide.dart';
import 'illustration.dart';

/// Écran d'erreur, formulé pour la personne qui le lit.
///
/// Remplace les 21 `Center(child: Text('Erreur : $e'))` relevés par l'audit,
/// qui affichaient la trace d'une exception Dio, URL et code HTTP comprises.
///
/// Trois décisions.
///
/// **La phrase vient de [MessageErreur]**, qui traduit l'exception. Aucun
/// écran ne formule son propre message : les mêmes causes produisent donc les
/// mêmes mots partout, ce qui permet de les apprendre.
///
/// **« Réessayer » n'apparaît que quand réessayer peut changer le résultat.**
/// Proposer le bouton après une erreur de droits ou une ressource supprimée
/// invite à appuyer en boucle sur quelque chose qui échouera toujours.
///
/// **Le détail technique reste accessible mais replié.** Il faut bien pouvoir
/// diagnostiquer une panne, et l'alternative, remettre le message brut à
/// l'écran, a déjà été essayée.
class EtatErreur extends StatelessWidget {
  const EtatErreur({
    super.key,
    required this.erreur,
    this.onReessayer,
    this.detailVisible = false,
  });

  /// L'exception levée. Son type décide de la phrase et de l'illustration.
  final Object? erreur;

  /// Relance le chargement. Typiquement `() => ref.refresh(monProvider)`.
  final FutureOr<void> Function()? onReessayer;

  /// Affiche le détail technique sans attendre une action. Réservé aux écrans
  /// d'administration, où la personne qui regarde sait quoi en faire.
  final bool detailVisible;

  @override
  Widget build(BuildContext context) {
    final reseau = MessageErreur.estReseau(erreur);
    final peutReessayer =
        onReessayer != null && MessageErreur.vautLaPeineDeReessayer(erreur);

    return CadreEtat(
      sujet: reseau ? SujetIllustration.reseau : SujetIllustration.recherche,
      titre: MessageErreur.titrePour(erreur),
      message: MessageErreur.pour(erreur),
      action: Column(
        children: [
          if (peutReessayer)
            AppBouton.principal(
              libelle: 'Réessayer',
              icone: Icons.refresh_rounded,
              onPressed: onReessayer,
              pleineLargeur: false,
            ),
          if (detailVisible && erreur != null) _Detail(erreur: erreur!),
        ],
      ),
    );
  }
}

/// Erreur affichée dans une zone réduite, à l'intérieur d'un écran qui garde
/// son contenu par ailleurs.
///
/// Sert quand une partie seulement de l'écran a échoué : les indicateurs d'un
/// tableau de bord, par exemple, alors que la liste en dessous s'est chargée.
/// Occuper tout l'écran avec l'erreur ferait disparaître ce qui marche.
class BandeauErreur extends StatelessWidget {
  const BandeauErreur({super.key, required this.erreur, this.onReessayer});

  final Object? erreur;
  final FutureOr<void> Function()? onReessayer;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final peutReessayer =
        onReessayer != null && MessageErreur.vautLaPeineDeReessayer(erreur);

    return Container(
      padding: AppEspaces.carte,
      decoration: BoxDecoration(
        color: couleurs.erreurVoile,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: couleurs.erreur, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: couleurs.erreur, size: 24),
          const SizedBox(width: AppEspaces.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MessageErreur.pour(erreur),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (peutReessayer) ...[
                  const SizedBox(height: AppEspaces.xs),
                  AppBouton.texte(
                    libelle: 'Réessayer',
                    icone: Icons.refresh_rounded,
                    onPressed: onReessayer,
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

class _Detail extends StatelessWidget {
  const _Detail({required this.erreur});

  final Object erreur;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    return Padding(
      padding: const EdgeInsets.only(top: AppEspaces.md),
      child: ExpansionTile(
        title: Text(
          'Détail technique',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: couleurs.texteSecondaire,
              ),
        ),
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Text(
            erreur.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: couleurs.texteSecondaire,
                ),
          ),
        ],
      ),
    );
  }
}
