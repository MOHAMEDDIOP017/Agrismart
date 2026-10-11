import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Champ de saisie de l'application.
///
/// Le libellé est posé au-dessus du champ, en texte ordinaire, et n'en bouge
/// jamais. L'ancien champ utilisait `labelText`, qui place le libellé dans le
/// champ puis le fait remonter et rétrécir dès la première frappe. Ce
/// comportement suppose qu'on se souvienne de ce qu'on remplissait : pour une
/// personne peu à l'aise avec le numérique, ou qui lit le français sans le
/// pratiquer couramment, c'est une information perdue au moment précis où elle
/// sert.
///
/// Le texte indicatif devient donc un exemple, et non une répétition du
/// libellé. « Nom du champ » au-dessus, « Ex : Champ Nord Thiès » à
/// l'intérieur : les deux disent des choses différentes, et seul le second
/// disparaît à la saisie.
///
/// Le message d'erreur s'affiche sous le champ, sur trois lignes au besoin, et
/// le champ garde sa place : une erreur qui pousse le reste du formulaire vers
/// le bas fait perdre le fil.
class AppChampTexte extends StatefulWidget {
  const AppChampTexte({
    super.key,
    required this.libelle,
    this.exemple,
    this.aide,
    this.controleur,
    this.validateur,
    this.onModification,
    this.onAppui,
    this.icone,
    this.suffixe,
    this.masque = false,
    this.clavier,
    this.lignes = 1,
    this.formateurs,
    this.actif = true,
    this.lectureSeule = false,
    this.actionClavier,
    this.focusAuto = false,
    this.obligatoire = false,
  });

  /// Libellé affiché au-dessus du champ, toujours visible.
  final String libelle;

  /// Exemple de saisie, affiché dans le champ tant qu'il est vide.
  final String? exemple;

  /// Précision affichée sous le champ quand il n'y a pas d'erreur. Sert à dire
  /// une contrainte avant qu'elle ne soit violée plutôt qu'après.
  final String? aide;

  final TextEditingController? controleur;
  final String? Function(String?)? validateur;
  final void Function(String)? onModification;
  final VoidCallback? onAppui;

  final IconData? icone;

  /// Unité ou suffixe affiché à droite, « ha » par exemple.
  final String? suffixe;

  /// Masque la saisie, avec un bouton pour la révéler.
  final bool masque;

  final TextInputType? clavier;
  final int lignes;
  final List<TextInputFormatter>? formateurs;
  final bool actif;
  final bool lectureSeule;
  final TextInputAction? actionClavier;
  final bool focusAuto;

  /// Marque le champ comme obligatoire, par une mention écrite à côté du
  /// libellé. Un astérisque seul n'est pas compris de tout le monde.
  final bool obligatoire;

  @override
  State<AppChampTexte> createState() => _AppChampTexteState();
}

class _AppChampTexteState extends State<AppChampTexte> {
  late bool _masque;

  @override
  void initState() {
    super.initState();
    _masque = widget.masque;
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Libelle(
          libelle: widget.libelle,
          obligatoire: widget.obligatoire,
          actif: widget.actif,
        ),
        const SizedBox(height: AppEspaces.xs),
        TextFormField(
          controller: widget.controleur,
          validator: widget.validateur,
          onChanged: widget.onModification,
          onTap: widget.onAppui,
          obscureText: widget.masque ? _masque : false,
          keyboardType: widget.clavier,
          maxLines: widget.masque ? 1 : widget.lignes,
          inputFormatters: widget.formateurs,
          enabled: widget.actif,
          readOnly: widget.lectureSeule,
          textInputAction: widget.actionClavier,
          autofocus: widget.focusAuto,
          style: textes.bodyMedium,
          decoration: InputDecoration(
            // Pas de `labelText` : le libellé est déjà au-dessus, le répéter
            // ici le ferait réapparaître par-dessus l'exemple.
            hintText: widget.exemple,
            helperText: widget.aide,
            suffixText: widget.suffixe,
            suffixStyle: textes.bodyMedium?.copyWith(
              color: couleurs.texteSecondaire,
            ),
            prefixIcon: widget.icone == null
                ? null
                : Icon(widget.icone, size: 22, color: couleurs.texteSecondaire),
            suffixIcon: widget.masque
                ? IconButton(
                    // Libellé parlé explicite : l'icône d'œil barré ne dit pas
                    // à elle seule ce qu'elle va faire.
                    tooltip: _masque
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    icon: Icon(
                      _masque
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 22,
                      color: couleurs.texteSecondaire,
                    ),
                    onPressed: () => setState(() => _masque = !_masque),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _Libelle extends StatelessWidget {
  const _Libelle({
    required this.libelle,
    required this.obligatoire,
    required this.actif,
  });

  final String libelle;
  final bool obligatoire;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: actif ? couleurs.textePrincipal : couleurs.texteSecondaire,
        );

    if (!obligatoire) return Text(libelle, style: style);

    return Row(
      children: [
        Flexible(child: Text(libelle, style: style)),
        const SizedBox(width: AppEspaces.xs),
        Text(
          '(obligatoire)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: couleurs.texteSecondaire,
              ),
        ),
      ],
    );
  }
}
