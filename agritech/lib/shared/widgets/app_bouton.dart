import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// Forme du bouton, qui dit son importance dans l'écran.
enum VarianteBouton {
  /// Fond plein. Une seule par écran : l'action que l'on vient faire.
  plein,

  /// Contour seul. Les actions possibles mais secondaires.
  contour,

  /// Libellé seul. Les actions de retrait, « Annuler », « Plus tard ».
  texte,
}

/// Famille de couleur du bouton.
///
/// Remplace le paramètre `color` de l'ancien `AppButton`, qui acceptait
/// n'importe quelle couleur et laissait chaque écran choisir la sienne. Trois
/// intentions suffisent, et chacune est vérifiée au contraste.
enum TonBouton {
  /// Action normale, en vert culture.
  principal,

  /// Action d'appoint, en ocre. Sert à distinguer une seconde action pleine
  /// d'une première sans les mettre en concurrence.
  accent,

  /// Action qui détruit ou annule quelque chose, en rouge.
  destructif,
}

/// Bouton de l'application, dans ses trois formes.
///
/// Trois propriétés méritent d'être expliquées, parce qu'elles répondent
/// chacune à un défaut relevé par l'audit.
///
/// **Le double envoi est empêché par construction.** [onPressed] peut renvoyer
/// un `Future`. Le bouton le détecte, se désactive pendant l'attente et
/// affiche un indicateur, puis se réactive. L'appelant n'a pas de drapeau à
/// gérer, donc pas de drapeau à oublier. Sur une connexion lente, un
/// agriculteur qui n'a aucun retour appuie deux fois : sans ce verrou, deux
/// champs sont créés.
///
/// **Le libellé reste affiché pendant le chargement.** L'ancien bouton
/// remplaçait tout son contenu par une roue. On perdait alors l'information de
/// ce qui était en cours, ce qui compte d'autant plus quand le français n'est
/// pas la première langue : relire « Enregistrer » aide à se rappeler ce que
/// l'on attend.
///
/// **L'appui se voit tout de suite.** Le bouton s'enfonce légèrement au
/// contact, sans attendre la propagation d'une onde.
class AppBouton extends StatefulWidget {
  const AppBouton.principal({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.enChargement = false,
    this.pleineLargeur = true,
    this.ton = TonBouton.principal,
    this.etiquette,
  }) : variante = VarianteBouton.plein;

  const AppBouton.secondaire({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.enChargement = false,
    this.pleineLargeur = true,
    this.ton = TonBouton.principal,
    this.etiquette,
  }) : variante = VarianteBouton.contour;

  const AppBouton.texte({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone,
    this.enChargement = false,
    this.pleineLargeur = false,
    this.ton = TonBouton.principal,
    this.etiquette,
  }) : variante = VarianteBouton.texte;

  final VarianteBouton variante;
  final TonBouton ton;

  /// Texte du bouton. Court : il doit tenir sur une ligne à 360 dp de large et
  /// à 130 % de taille de texte, et laisser de la place à la traduction.
  final String libelle;

  /// Action déclenchée. Un `Future` active le verrou anti double envoi.
  /// `null` désactive le bouton.
  final FutureOr<void> Function()? onPressed;

  final IconData? icone;

  /// Force l'état de chargement depuis l'extérieur, pour les écrans qui
  /// suivent déjà l'attente dans leur provider.
  final bool enChargement;

  final bool pleineLargeur;

  /// Description pour les lecteurs d'écran, quand le libellé seul est ambigu.
  final String? etiquette;

  @override
  State<AppBouton> createState() => _AppBoutonState();
}

class _AppBoutonState extends State<AppBouton> {
  /// Fourni au bouton Material pour lire son état réel plutôt que de deviner
  /// l'appui avec un détecteur posé par-dessus.
  final WidgetStatesController _etats = WidgetStatesController();

  bool _appuye = false;
  bool _occupe = false;

  @override
  void initState() {
    super.initState();
    _etats.addListener(_surChangementEtat);
  }

  @override
  void dispose() {
    _etats.removeListener(_surChangementEtat);
    _etats.dispose();
    super.dispose();
  }

  void _surChangementEtat() {
    final appuye = _etats.value.contains(WidgetState.pressed);
    if (appuye != _appuye && mounted) setState(() => _appuye = appuye);
  }

  bool get _charge => widget.enChargement || _occupe;

  bool get _actif => widget.onPressed != null && !_charge;

  Future<void> _appuyer() async {
    if (!_actif) return;
    final resultat = widget.onPressed!();
    if (resultat is! Future<void>) return;

    setState(() => _occupe = true);
    try {
      await resultat;
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Color _couleurPrincipale(CouleursAgriSmart c) => switch (widget.ton) {
        TonBouton.principal => c.primaire,
        TonBouton.accent => c.secondaireFonce,
        TonBouton.destructif => c.erreur,
      };

  Color _couleurDessus(CouleursAgriSmart c) => switch (widget.ton) {
        TonBouton.principal => c.surPrimaire,
        TonBouton.accent => Colors.white,
        TonBouton.destructif => c.surErreur,
      };

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final teinte = _couleurPrincipale(couleurs);
    final dessus = _couleurDessus(couleurs);

    final contenu = _Contenu(
      libelle: widget.libelle,
      icone: widget.icone,
      enChargement: _charge,
      couleurIndicateur:
          widget.variante == VarianteBouton.plein ? dessus : teinte,
    );

    final largeurMinimale = widget.pleineLargeur ? double.infinity : 0.0;
    final hauteurMinimale =
        widget.variante == VarianteBouton.texte ? 48.0 : 56.0;
    final taille = Size(largeurMinimale, hauteurMinimale);

    final bouton = switch (widget.variante) {
      VarianteBouton.plein => ElevatedButton(
          onPressed: _actif ? _appuyer : null,
          statesController: _etats,
          style: ElevatedButton.styleFrom(
            backgroundColor: teinte,
            foregroundColor: dessus,
            minimumSize: taille,
          ),
          child: contenu,
        ),
      VarianteBouton.contour => OutlinedButton(
          onPressed: _actif ? _appuyer : null,
          statesController: _etats,
          style: OutlinedButton.styleFrom(
            foregroundColor: teinte,
            side: BorderSide(color: teinte, width: 1.5),
            minimumSize: taille,
          ),
          child: contenu,
        ),
      VarianteBouton.texte => TextButton(
          onPressed: _actif ? _appuyer : null,
          statesController: _etats,
          style: TextButton.styleFrom(
            foregroundColor: teinte,
            minimumSize: taille,
          ),
          child: contenu,
        ),
    };

    return Semantics(
      label: widget.etiquette,
      // Annonce l'attente aux lecteurs d'écran : sans cela, un bouton
      // désactivé pendant un appel réseau est indistinguable d'un bouton
      // désactivé faute de saisie valide.
      liveRegion: _charge,
      child: AnimatedScale(
        scale: _appuye ? 0.97 : 1,
        duration: AppMouvement.duree(context, AppDurees.appui),
        curve: AppCourbes.sortie,
        child: bouton,
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.libelle,
    required this.icone,
    required this.enChargement,
    required this.couleurIndicateur,
  });

  final String libelle;
  final IconData? icone;
  final bool enChargement;
  final Color couleurIndicateur;

  @override
  Widget build(BuildContext context) {
    // Quand une icône est prévue, l'indicateur prend sa place : la largeur du
    // bouton ne change pas au passage en chargement, et rien ne bouge sous le
    // doigt.
    final Widget? avant = enChargement
        ? _Indicateur(couleur: couleurIndicateur)
        : (icone != null ? Icon(icone, size: 20) : null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (avant != null) ...[
          avant,
          const SizedBox(width: AppEspaces.xs),
        ],
        // `Flexible` plutôt qu'un texte nu : à 200 % de taille de texte, un
        // libellé long déborderait du bouton au lieu de passer à la ligne.
        Flexible(
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Indicateur extends StatelessWidget {
  const _Indicateur({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(couleur),
      ),
    );
  }
}
