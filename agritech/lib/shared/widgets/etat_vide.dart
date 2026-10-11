import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_bouton.dart';
import 'illustration.dart';

/// Écran ou zone sans contenu, avec ce qu'il faut faire pour en avoir.
///
/// Un état vide qui se contente de constater le vide laisse la personne
/// bloquée. Celui-ci nomme la situation, en donne la raison probable, et
/// propose l'action qui la résout. Les trois écrans concernés dans
/// l'application sont une liste de parcelles vide, une liste de
/// recommandations avant toute analyse, et une conversation non commencée :
/// dans les trois cas, il y a une action évidente à proposer.
///
/// La structure est volontairement identique à celle de [EtatErreur], pour que
/// les deux situations se lisent de la même façon.
class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.titre,
    required this.message,
    this.sujet = SujetIllustration.parcelle,
    this.libelleAction,
    this.onAction,
    this.iconeAction,
  });

  /// Ce qu'il n'y a pas, en quelques mots.
  final String titre;

  /// Pourquoi, et ce que cela implique. Deux phrases au plus.
  final String message;

  final SujetIllustration sujet;

  /// Action proposée. Les deux vont ensemble : sans [onAction], le bouton
  /// n'est pas affiché.
  final String? libelleAction;
  final FutureOr<void> Function()? onAction;
  final IconData? iconeAction;

  @override
  Widget build(BuildContext context) {
    return CadreEtat(
      sujet: sujet,
      titre: titre,
      message: message,
      action: (libelleAction != null && onAction != null)
          ? AppBouton.principal(
              libelle: libelleAction!,
              icone: iconeAction,
              onPressed: onAction,
              pleineLargeur: false,
            )
          : null,
    );
  }
}

/// Mise en page commune aux états vides et aux états d'erreur.
///
/// Les deux situations se lisent ainsi de la même façon : illustration, titre,
/// explication, action. [EtatErreur] s'en sert aussi.
///
/// Le contenu est défilable même s'il paraît court : à 200 % de taille de
/// texte et sur un écran de 360 dp, une illustration, un titre, deux phrases
/// et un bouton dépassent la hauteur disponible. Sans cela, l'état vide
/// déborderait, ce qui est le genre de détail qui ne se voit qu'une fois
/// l'application installée.
class CadreEtat extends StatelessWidget {
  const CadreEtat({
    super.key,
    required this.sujet,
    required this.titre,
    required this.message,
    this.action,
  });

  final SujetIllustration sujet;
  final String titre;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, contraintes) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contraintes.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppEspaces.lg,
                  vertical: AppEspaces.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Illustration(sujet: sujet),
                    const SizedBox(height: AppEspaces.lg),
                    Text(
                      titre,
                      style: textes.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppEspaces.xs),
                    Text(
                      message,
                      style: textes.bodyMedium
                          ?.copyWith(color: couleurs.texteSecondaire),
                      textAlign: TextAlign.center,
                    ),
                    if (action != null) ...[
                      const SizedBox(height: AppEspaces.lg),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
