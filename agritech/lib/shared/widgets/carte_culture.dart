import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'squelette.dart';
import 'zone_tactile.dart';

/// Carte d'une culture recommandée.
///
/// Ne connaît aucun modèle de données : elle reçoit des valeurs simples. La
/// couche recommandations garde donc son propre adaptateur, qui traduit sa
/// réponse d'API en arguments. C'est ce qui permet à ce composant de vivre
/// dans `shared/` sans en faire dépendre une couche partagée d'une
/// fonctionnalité précise.
///
/// Quatre points de conception.
///
/// **Le nom wolof est sous le nom français, pas à côté.** Il est écrit en
/// taille de lecture et non en légende, parce que pour une partie des
/// utilisateurs c'est lui, et non le nom français, qui identifie la plante.
/// L'ancienne carte l'affichait en italique à 14 px grisé ; l'italique a été
/// retiré, il ralentit la lecture sans rien ajouter ici.
///
/// **Le taux d'aptitude est écrit en chiffres à côté de sa barre.** La barre
/// seule se compare d'un coup d'œil mais ne se lit pas précisément, et sa
/// couleur ne doit pas porter l'information à elle seule.
///
/// **La barre se remplit avec un décalage selon le rang.** Les trois cartes se
/// remplissent l'une après l'autre, à 100 ms d'écart, ce qui montre l'ordre du
/// classement au lieu de le laisser deviner. Le remplissage dure 300 ms et
/// s'arrête là : l'ancienne carte animait sur 1 200 ms.
///
/// **La première carte est traitée différemment.** Une seule
/// recommandation est à retenir ; les deux autres sont des solutions de repli.
class CarteCulture extends StatelessWidget {
  const CarteCulture({
    super.key,
    required this.nomFrancais,
    required this.tauxAptitude,
    this.nomWolof,
    this.rang,
    this.imageUrl,
    this.icone = Icons.grass_rounded,
    this.badge,
    this.informations = const [],
    this.onTap,
    this.heroTag,
    this.index = 0,
    this.miseEnValeur = false,
  });

  /// Nom affiché en premier.
  final String nomFrancais;

  /// Nom en wolof, affiché sous le nom français quand il est connu. La table
  /// de correspondance ne couvre que les cultures que le modèle sait prédire :
  /// pour les autres, mieux vaut ne rien afficher qu'une traduction approchée.
  final String? nomWolof;

  /// Taux d'aptitude de la parcelle à cette culture, de 0 à 100.
  final int tauxAptitude;

  /// Rang dans le classement, tel que le moteur l'a décidé.
  final int? rang;

  final String? imageUrl;

  /// Icône de repli quand l'image n'est pas disponible, ce qui est le cas
  /// courant hors connexion.
  final IconData icone;

  /// Badge d'état de relecture, construit par l'appelant.
  final Widget? badge;

  /// Lignes d'information complémentaires, période de semis par exemple.
  final List<Widget> informations;

  final FutureOr<void> Function()? onTap;

  /// Étiquette de la transition entre la liste et le détail. La même valeur
  /// doit être posée des deux côtés.
  final Object? heroTag;

  /// Position dans la liste, qui décide du décalage de l'animation.
  final int index;

  /// Met la carte en avant : c'est la recommandation principale.
  final bool miseEnValeur;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    final carte = Container(
      padding: AppEspaces.carte,
      decoration: BoxDecoration(
        color: miseEnValeur ? couleurs.primaireVoile : couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(
          color: miseEnValeur ? couleurs.primaire : couleurs.separateur,
          width: miseEnValeur ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VignetteCulture(
                imageUrl: imageUrl,
                icone: icone,
                heroTag: heroTag,
                cote: miseEnValeur ? 72 : 56,
              ),
              const SizedBox(width: AppEspaces.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomFrancais,
                      style:
                          miseEnValeur ? textes.titleLarge : textes.titleMedium,
                    ),
                    if (nomWolof != null && nomWolof!.trim().isNotEmpty)
                      Text(
                        nomWolof!,
                        style: textes.bodyMedium
                            ?.copyWith(color: couleurs.texteSecondaire),
                      ),
                  ],
                ),
              ),
              if (rang != null) ...[
                const SizedBox(width: AppEspaces.xs),
                _Rang(rang: rang!, premier: rang == 1),
              ],
            ],
          ),
          const SizedBox(height: AppEspaces.sm),
          BarreAptitude(taux: tauxAptitude, index: index),
          if (informations.isNotEmpty) ...[
            const SizedBox(height: AppEspaces.sm),
            ...informations,
          ],
          if (badge != null) ...[
            const SizedBox(height: AppEspaces.sm),
            Align(alignment: Alignment.centerLeft, child: badge!),
          ],
        ],
      ),
    );

    if (onTap == null) return carte;

    return ZoneTactile(
      onTap: () => onTap!(),
      rayon: AppRayons.brCarte,
      // La carte dépasse largement 48 dp : aucune contrainte à ajouter, et en
      // imposer une casserait sa hauteur naturelle.
      tailleMinimale: null,
      etiquette: 'Culture $nomFrancais, '
          'aptitude $tauxAptitude pour cent'
          '${rang != null ? ', rang $rang' : ''}',
      child: carte,
    );
  }
}

/// Barre de remplissage du taux d'aptitude, avec sa valeur écrite.
class BarreAptitude extends StatefulWidget {
  const BarreAptitude({
    super.key,
    required this.taux,
    this.index = 0,
    this.hauteur = 10,
  });

  final int taux;
  final int index;
  final double hauteur;

  @override
  State<BarreAptitude> createState() => _BarreAptitudeState();
}

class _BarreAptitudeState extends State<BarreAptitude> {
  /// Cible de l'animation. Part de zéro, puis prend sa valeur après le
  /// décalage propre au rang, ce qui déclenche le remplissage.
  double _cible = 0;
  Timer? _depart;
  bool _programme = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_programme) return;
    _programme = true;

    final delai = AppMouvement.decalage(context, widget.index);
    if (delai == Duration.zero) {
      // Réduction des animations active, ou premier rang : la barre affiche
      // directement sa valeur.
      _cible = widget.taux / 100;
      return;
    }
    _depart = Timer(delai, () {
      if (mounted) setState(() => _cible = widget.taux / 100);
    });
  }

  @override
  void didUpdateWidget(BarreAptitude ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.taux != widget.taux) {
      setState(() => _cible = widget.taux / 100);
    }
  }

  @override
  void dispose() {
    _depart?.cancel();
    super.dispose();
  }

  /// Couleur selon le niveau d'aptitude.
  ///
  /// Trois paliers, qui reprennent la lecture agronomique : au-dessus de 75 la
  /// parcelle convient, entre 50 et 75 elle convient sous conditions, en
  /// dessous elle ne convient pas. La couleur ne porte jamais seule cette
  /// information : le pourcentage est écrit à côté.
  Color _couleur(CouleursAgriSmart c) {
    if (widget.taux >= 75) return c.primaire;
    if (widget.taux >= 50) return c.secondaireTexte;
    return c.alerteElevee;
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final teinte = _couleur(couleurs);

    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _cible),
            duration: AppMouvement.duree(context, AppDurees.moyenne),
            curve: AppCourbes.sortie,
            builder: (context, valeur, _) => ClipRRect(
              borderRadius: AppRayons.brPastille,
              child: LinearProgressIndicator(
                value: valeur,
                minHeight: widget.hauteur,
                backgroundColor: couleurs.separateur,
                valueColor: AlwaysStoppedAnimation<Color>(teinte),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppEspaces.xs),
        // Valeur finale écrite tout de suite, et non comptée pendant
        // l'animation : un nombre qui défile se lit moins bien qu'un nombre
        // posé, et c'est l'information centrale de l'écran.
        Text(
          '${widget.taux} %',
          style:
              Theme.of(context).textTheme.titleSmall?.copyWith(color: teinte),
        ),
      ],
    );
  }
}

/// Vignette d'une culture : son image si elle est disponible, sinon une
/// icône sur fond teinté.
///
/// Exposée pour que la carte du classement et la feuille de détail posent la
/// même, avec la même étiquette de transition : la vignette se déplace alors
/// d'un écran à l'autre au lieu de disparaître puis de réapparaître ailleurs.
class VignetteCulture extends StatelessWidget {
  const VignetteCulture({
    super.key,
    required this.imageUrl,
    required this.icone,
    required this.cote,
    this.heroTag,
  });

  final String? imageUrl;
  final IconData icone;
  final double cote;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    Widget contenu = ClipRRect(
      borderRadius: AppRayons.brChamp,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? _repli(couleurs)
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              width: cote,
              height: cote,
              fit: BoxFit.cover,
              placeholder: (_, __) => ZoneSquelette(
                child: Squelette(largeur: cote, hauteur: cote),
              ),
              // Le repli est dessiné et non téléchargé : sur une parcelle
              // consultée hors connexion, la carte reste complète.
              errorWidget: (_, __, ___) => _repli(couleurs),
            ),
    );

    if (heroTag != null) {
      contenu = Hero(tag: heroTag!, child: contenu);
    }
    return contenu;
  }

  Widget _repli(CouleursAgriSmart couleurs) {
    return Container(
      width: cote,
      height: cote,
      color: couleurs.primaireVoile,
      child: Icon(icone, color: couleurs.primaire, size: cote * 0.5),
    );
  }
}

class _Rang extends StatelessWidget {
  const _Rang({required this.rang, required this.premier});

  final int rang;
  final bool premier;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final fond = premier ? couleurs.primaire : couleurs.separateur;
    final texte = premier ? couleurs.surPrimaire : couleurs.textePrincipal;

    return Container(
      padding: AppEspaces.pastille,
      decoration: BoxDecoration(
        color: fond,
        borderRadius: AppRayons.brPastille,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premier) ...[
            Icon(Icons.workspace_premium_rounded, size: 16, color: texte),
            const SizedBox(width: AppEspaces.xxs),
          ],
          Text(
            rang == 1 ? '1re' : '${rang}e',
            style:
                Theme.of(context).textTheme.labelMedium?.copyWith(color: texte),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'information d'une carte de culture : une icône et son texte.
///
/// L'icône ne vient jamais seule, conformément à la règle retenue pour toute
/// l'application.
class LigneInfoCulture extends StatelessWidget {
  const LigneInfoCulture({
    super.key,
    required this.icone,
    required this.texte,
  });

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaces.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: couleurs.texteSecondaire),
          const SizedBox(width: AppEspaces.xs),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
