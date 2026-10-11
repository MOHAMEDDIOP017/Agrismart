import 'package:flutter/material.dart';

/// Palette brute d'AgriSmart : la source de vérité des teintes.
///
/// Chaque constante porte en commentaire son rapport de contraste WCAG 2.1
/// mesuré contre les deux fonds de l'application. Les valeurs proviennent du
/// test `test/theme_contraste_test.dart`, qui recalcule les rapports à chaque
/// exécution et échoue si l'un d'eux descend sous le seuil requis.
///
/// Trois règles tiennent l'ensemble, et expliquent pourquoi la palette compte
/// aussi peu de teintes :
///
/// 1. Une seule teinte par famille sémantique. Elle est choisie assez sombre
///    pour servir à la fois de fond d'aplat portant du texte blanc et de
///    couleur de texte sur le fond de page. Deux rôles, une valeur, donc
///    aucune dérive possible entre les deux usages.
/// 2. L'ocre fait exception. C'est la couleur d'identité chaude du projet et
///    l'assombrir jusqu'au niveau AA lui ferait perdre son caractère. Elle se
///    décline donc en trois jetons dont les usages sont disjoints.
/// 3. Sur un fond teinté, le texte est toujours `textePrincipal`. La teinte de
///    famille n'y apparaît qu'en icône ou en liseré. Cette règle écarte le
///    motif « pastille pâle plus petit texte coloré », qui tombe entre 4,0 et
///    4,4 et devient illisible en extérieur.
class AppPalette {
  AppPalette._();

  // ── Mode clair ────────────────────────────────────────────────────────────

  /// Fond de page, crème chaud. Texte principal dessus : 16,23:1.
  static const Color creme = Color(0xFFFAF8F2);

  /// Surface des cartes et des champs. Texte principal dessus : 17,23:1.
  static const Color blanc = Color(0xFFFFFFFF);

  /// Texte courant. 16,23:1 sur crème, 17,23:1 sur blanc (AAA).
  static const Color encre = Color(0xFF1C1B17);

  /// Texte d'appoint. 7,26:1 sur crème, 7,71:1 sur blanc (AAA).
  ///
  /// Le `#6B7280` de la palette précédente n'atteignait que 4,55:1 sur crème.
  /// Il passait le seuil AA sur le papier, mais il portait 204 libellés de 10
  /// à 12 px, taille à laquelle ce rapport ne tient plus en plein soleil.
  static const Color encreDouce = Color(0xFF55534B);

  /// Contour des composants interactifs. 3,61:1 sur crème, 3,84:1 sur blanc,
  /// au-dessus du seuil de 3:1 que WCAG 1.4.11 impose aux bordures de champs.
  static const Color contour = Color(0xFF8A8268);

  /// Trait de séparation décoratif, hors périmètre de 1.4.11.
  static const Color trait = Color(0xFFE8E3D5);

  /// Vert culture. Blanc dessus 5,31:1 ; en texte sur crème 5,00:1.
  static const Color vert = Color(0xFF2D7A3A);

  /// Vert enfoncé, pour l'état appuyé et la fin des dégradés. 8,17:1 sur crème.
  static const Color vertFonce = Color(0xFF1F5628);

  /// Fond vert teinté. Texte principal dessus : 13,88:1.
  static const Color vertVoile = Color(0xFFDDEADF);

  /// Ocre sahélien, en aplat uniquement. Encre dessus 4,71:1 ; le blanc
  /// n'atteindrait que 3,66:1 et ne doit donc jamais y être posé.
  static const Color ocre = Color(0xFFB9772A);

  /// Ocre porteur de texte blanc : 5,95:1.
  static const Color ocreFonce = Color(0xFF8A591F);

  /// Ocre employé comme couleur de texte. 4,58:1 sur crème, 4,86:1 sur blanc.
  static const Color ocreEncre = Color(0xFF9D6523);

  /// Fond ocre teinté. Texte principal dessus : 14,40:1.
  static const Color ocreVoile = Color(0xFFF4E9DD);

  /// Succès. Blanc dessus 5,13:1 ; en texte sur crème 4,83:1.
  static const Color succes = Color(0xFF2E7D32);
  static const Color succesVoile = Color(0xFFDEEADE);

  /// Avertissement. Blanc dessus 4,92:1 ; en texte sur crème 4,63:1.
  ///
  /// Le `#B26A00` demandé au cahier des charges plafonne à 4,24:1 avec du
  /// blanc et à 3,99:1 en texte sur crème : il échoue AA dans ses deux rôles,
  /// et l'encre posée dessus ne fait pas mieux (4,07:1). Un assombrissement de
  /// 8 % suffit à franchir le seuil sans changer la teinte perçue.
  static const Color avertissement = Color(0xFFA36100);
  static const Color avertissementVoile = Color(0xFFF3E7D6);

  /// Erreur. Blanc dessus 6,54:1 ; en texte sur crème 6,15:1.
  static const Color erreur = Color(0xFFB3261E);
  static const Color erreurVoile = Color(0xFFF3DCDB);

  /// Information et statut « corrigée ». Blanc dessus 5,75:1 ; en texte sur
  /// crème 5,41:1. Le `#1976D2` précédent tombait à 4,33:1 sur crème.
  static const Color info = Color(0xFF1565C0);
  static const Color infoVoile = Color(0xFFDAE6F5);

  /// Niveau d'alerte élevé, entre l'avertissement et l'erreur. Blanc dessus
  /// 6,24:1. Remplace le corail `#D85A30`, qui restait à 3,87:1.
  static const Color alerteElevee = Color(0xFFA83E18);

  // ── Mode sombre ───────────────────────────────────────────────────────────
  //
  // Les teintes claires portent de l'encre sombre et non du blanc : sur fond
  // noir, un aplat saturé avec texte blanc éblouit dans l'obscurité, ce qui
  // est précisément la situation d'usage visée le soir.

  static const Color nuit = Color(0xFF14160F);
  static const Color nuitSurface = Color(0xFF1E2118);
  static const Color nuitSurfaceHaute = Color(0xFF272B20);

  /// 16,10:1 sur le fond, 14,41:1 sur la surface (AAA).
  static const Color encreClaire = Color(0xFFF2F1E9);

  /// 9,97:1 sur le fond, 8,92:1 sur la surface (AAA).
  static const Color encreClaireDouce = Color(0xFFC2C0B2);

  /// 3,47:1 sur la surface, au-dessus du seuil de 3:1.
  static const Color contourNuit = Color(0xFF6E775E);
  static const Color traitNuit = Color(0xFF2F3328);

  /// 8,23:1 sur la surface sombre.
  static const Color vertClair = Color(0xFF7CC98A);
  static const Color vertClairFonce = Color(0xFF5FB06E);
  static const Color vertVoileNuit = Color(0xFF1D2E20);

  /// 7,76:1 sur la surface sombre.
  static const Color ocreClair = Color(0xFFE3A764);
  static const Color ocreClairFonce = Color(0xFFC98C4A);
  static const Color ocreVoileNuit = Color(0xFF2E2619);

  /// 7,95:1 sur la surface sombre.
  static const Color succesClair = Color(0xFF7BC67E);
  static const Color succesVoileNuit = Color(0xFF1C2C1D);

  /// 7,37:1 sur la surface sombre.
  static const Color avertissementClair = Color(0xFFE0A33C);
  static const Color avertissementVoileNuit = Color(0xFF2E2714);

  /// 9,56:1 sur la surface sombre.
  static const Color erreurClaire = Color(0xFFF2B8B5);
  static const Color erreurVoileNuit = Color(0xFF33201F);

  /// 9,48:1 sur la surface sombre.
  static const Color infoClaire = Color(0xFFA8C8F0);
  static const Color infoVoileNuit = Color(0xFF1C2430);

  /// 7,42:1 sur la surface sombre.
  static const Color alerteEleveeClaire = Color(0xFFEF9A72);
}

/// Jetons de couleur résolus pour un mode d'affichage donné.
///
/// Les écrans n'accèdent jamais à [AppPalette] directement : ils passent par
/// `context.couleurs`, qui renvoie le jeu correspondant au mode clair ou
/// sombre en cours. C'est ce qui rend le thème sombre possible sans dupliquer
/// un seul écran.
///
/// Quatre rôles existent par famille sémantique, et ils ne sont pas
/// interchangeables :
///
/// - `x` : l'aplat, fond d'un bouton plein ou remplissage d'une barre ;
/// - `surX` : le texte ou l'icône posés sur cet aplat ;
/// - `xVoile` : le fond teinté d'un bandeau ou d'une ligne sélectionnée ;
/// - `x` à nouveau, cette fois comme couleur de texte sur [fond] ou [surface].
///
/// Sur un fond `xVoile`, le texte reste [textePrincipal], jamais la teinte de
/// famille.
@immutable
class CouleursAgriSmart extends ThemeExtension<CouleursAgriSmart> {
  const CouleursAgriSmart({
    required this.fond,
    required this.surface,
    required this.textePrincipal,
    required this.texteSecondaire,
    required this.bordure,
    required this.separateur,
    required this.ombre,
    required this.primaire,
    required this.surPrimaire,
    required this.primaireFonce,
    required this.primaireVoile,
    required this.secondaire,
    required this.surSecondaire,
    required this.secondaireFonce,
    required this.secondaireTexte,
    required this.secondaireVoile,
    required this.succes,
    required this.surSucces,
    required this.succesVoile,
    required this.avertissement,
    required this.surAvertissement,
    required this.avertissementVoile,
    required this.erreur,
    required this.surErreur,
    required this.erreurVoile,
    required this.info,
    required this.surInfo,
    required this.infoVoile,
    required this.alerteElevee,
    required this.surAlerteElevee,
  });

  final Color fond;
  final Color surface;
  final Color textePrincipal;
  final Color texteSecondaire;
  final Color bordure;
  final Color separateur;
  final Color ombre;

  final Color primaire;
  final Color surPrimaire;
  final Color primaireFonce;
  final Color primaireVoile;

  final Color secondaire;
  final Color surSecondaire;
  final Color secondaireFonce;
  final Color secondaireTexte;
  final Color secondaireVoile;

  final Color succes;
  final Color surSucces;
  final Color succesVoile;

  final Color avertissement;
  final Color surAvertissement;
  final Color avertissementVoile;

  final Color erreur;
  final Color surErreur;
  final Color erreurVoile;

  final Color info;
  final Color surInfo;
  final Color infoVoile;

  final Color alerteElevee;
  final Color surAlerteElevee;

  /// Dégradé du vert culture, du clair vers le foncé.
  ///
  /// Dérivé plutôt que déclaré : il suit ainsi le mode d'affichage comme les
  /// deux teintes dont il est fait.
  LinearGradient get degradePrimaire => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaire, primaireFonce],
      );

  // ── Statuts métier ────────────────────────────────────────────────────────
  //
  // Dérivés des familles sémantiques au lieu d'être déclarés à part. Les cinq
  // enums de l'application redéclaraient auparavant leurs propres hex,
  // identiques à ceux de la palette : la même couleur existait en double, sans
  // rien pour garantir qu'elles resteraient synchronisées.

  /// Recommandation produite par le moteur, pas encore relue par un agronome.
  Color get validationEnAttente => avertissement;

  /// Recommandation confirmée telle quelle par un agronome.
  Color get validationValidee => succes;

  /// Recommandation dont l'agronome a modifié la culture retenue.
  Color get validationCorrigee => info;

  /// Recommandation écartée par l'agronome.
  Color get validationRejetee => erreur;

  /// Culture planifiée, pas encore semée.
  ///
  /// L'application montrait ce statut en deux couleurs selon le widget : gris
  /// dans le badge de champ, bleu dans l'enum `StatutCulture`. Le bleu est
  /// retenu, parce qu'un gris se lit comme un élément désactivé alors qu'une
  /// culture prévue est une décision prise.
  Color get statutPrevu => info;

  Color get statutEnCours => primaire;
  Color get statutRecolte => secondaireTexte;

  /// Culture sous traitement phytosanitaire : demande une action.
  Color get statutEnTraitement => alerteElevee;

  /// Culture abandonnée en cours de campagne.
  ///
  /// Même divergence que pour [statutPrevu] : rouge dans le badge de champ,
  /// gris dans l'enum. Le gris est retenu, parce qu'un abandon est une fin de
  /// parcours neutre et non une erreur à corriger. Réserver le rouge aux
  /// situations qui appellent une réaction lui garde sa force.
  Color get statutAbandonne => texteSecondaire;

  Color get alerteCritique => erreur;
  Color get alerteModeree => avertissement;
  Color get alerteFaible => info;

  // ── Jeux clair et sombre ──────────────────────────────────────────────────

  static const CouleursAgriSmart clair = CouleursAgriSmart(
    fond: AppPalette.creme,
    surface: AppPalette.blanc,
    textePrincipal: AppPalette.encre,
    texteSecondaire: AppPalette.encreDouce,
    bordure: AppPalette.contour,
    separateur: AppPalette.trait,
    ombre: AppPalette.encre,
    primaire: AppPalette.vert,
    surPrimaire: AppPalette.blanc,
    primaireFonce: AppPalette.vertFonce,
    primaireVoile: AppPalette.vertVoile,
    secondaire: AppPalette.ocre,
    surSecondaire: AppPalette.encre,
    secondaireFonce: AppPalette.ocreFonce,
    secondaireTexte: AppPalette.ocreEncre,
    secondaireVoile: AppPalette.ocreVoile,
    succes: AppPalette.succes,
    surSucces: AppPalette.blanc,
    succesVoile: AppPalette.succesVoile,
    avertissement: AppPalette.avertissement,
    surAvertissement: AppPalette.blanc,
    avertissementVoile: AppPalette.avertissementVoile,
    erreur: AppPalette.erreur,
    surErreur: AppPalette.blanc,
    erreurVoile: AppPalette.erreurVoile,
    info: AppPalette.info,
    surInfo: AppPalette.blanc,
    infoVoile: AppPalette.infoVoile,
    alerteElevee: AppPalette.alerteElevee,
    surAlerteElevee: AppPalette.blanc,
  );

  static const CouleursAgriSmart sombre = CouleursAgriSmart(
    fond: AppPalette.nuit,
    surface: AppPalette.nuitSurface,
    textePrincipal: AppPalette.encreClaire,
    texteSecondaire: AppPalette.encreClaireDouce,
    bordure: AppPalette.contourNuit,
    separateur: AppPalette.traitNuit,
    ombre: Color(0xFF000000),
    primaire: AppPalette.vertClair,
    surPrimaire: AppPalette.nuit,
    primaireFonce: AppPalette.vertClairFonce,
    primaireVoile: AppPalette.vertVoileNuit,
    secondaire: AppPalette.ocreClair,
    surSecondaire: AppPalette.nuit,
    secondaireFonce: AppPalette.ocreClairFonce,
    secondaireTexte: AppPalette.ocreClair,
    secondaireVoile: AppPalette.ocreVoileNuit,
    succes: AppPalette.succesClair,
    surSucces: AppPalette.nuit,
    succesVoile: AppPalette.succesVoileNuit,
    avertissement: AppPalette.avertissementClair,
    surAvertissement: AppPalette.nuit,
    avertissementVoile: AppPalette.avertissementVoileNuit,
    erreur: AppPalette.erreurClaire,
    surErreur: AppPalette.nuit,
    erreurVoile: AppPalette.erreurVoileNuit,
    info: AppPalette.infoClaire,
    surInfo: AppPalette.nuit,
    infoVoile: AppPalette.infoVoileNuit,
    alerteElevee: AppPalette.alerteEleveeClaire,
    surAlerteElevee: AppPalette.nuit,
  );

  @override
  CouleursAgriSmart copyWith({
    Color? fond,
    Color? surface,
    Color? textePrincipal,
    Color? texteSecondaire,
    Color? bordure,
    Color? separateur,
    Color? ombre,
    Color? primaire,
    Color? surPrimaire,
    Color? primaireFonce,
    Color? primaireVoile,
    Color? secondaire,
    Color? surSecondaire,
    Color? secondaireFonce,
    Color? secondaireTexte,
    Color? secondaireVoile,
    Color? succes,
    Color? surSucces,
    Color? succesVoile,
    Color? avertissement,
    Color? surAvertissement,
    Color? avertissementVoile,
    Color? erreur,
    Color? surErreur,
    Color? erreurVoile,
    Color? info,
    Color? surInfo,
    Color? infoVoile,
    Color? alerteElevee,
    Color? surAlerteElevee,
  }) {
    return CouleursAgriSmart(
      fond: fond ?? this.fond,
      surface: surface ?? this.surface,
      textePrincipal: textePrincipal ?? this.textePrincipal,
      texteSecondaire: texteSecondaire ?? this.texteSecondaire,
      bordure: bordure ?? this.bordure,
      separateur: separateur ?? this.separateur,
      ombre: ombre ?? this.ombre,
      primaire: primaire ?? this.primaire,
      surPrimaire: surPrimaire ?? this.surPrimaire,
      primaireFonce: primaireFonce ?? this.primaireFonce,
      primaireVoile: primaireVoile ?? this.primaireVoile,
      secondaire: secondaire ?? this.secondaire,
      surSecondaire: surSecondaire ?? this.surSecondaire,
      secondaireFonce: secondaireFonce ?? this.secondaireFonce,
      secondaireTexte: secondaireTexte ?? this.secondaireTexte,
      secondaireVoile: secondaireVoile ?? this.secondaireVoile,
      succes: succes ?? this.succes,
      surSucces: surSucces ?? this.surSucces,
      succesVoile: succesVoile ?? this.succesVoile,
      avertissement: avertissement ?? this.avertissement,
      surAvertissement: surAvertissement ?? this.surAvertissement,
      avertissementVoile: avertissementVoile ?? this.avertissementVoile,
      erreur: erreur ?? this.erreur,
      surErreur: surErreur ?? this.surErreur,
      erreurVoile: erreurVoile ?? this.erreurVoile,
      info: info ?? this.info,
      surInfo: surInfo ?? this.surInfo,
      infoVoile: infoVoile ?? this.infoVoile,
      alerteElevee: alerteElevee ?? this.alerteElevee,
      surAlerteElevee: surAlerteElevee ?? this.surAlerteElevee,
    );
  }

  @override
  CouleursAgriSmart lerp(CouleursAgriSmart? autre, double t) {
    if (autre == null) return this;
    return CouleursAgriSmart(
      fond: Color.lerp(fond, autre.fond, t)!,
      surface: Color.lerp(surface, autre.surface, t)!,
      textePrincipal: Color.lerp(textePrincipal, autre.textePrincipal, t)!,
      texteSecondaire: Color.lerp(texteSecondaire, autre.texteSecondaire, t)!,
      bordure: Color.lerp(bordure, autre.bordure, t)!,
      separateur: Color.lerp(separateur, autre.separateur, t)!,
      ombre: Color.lerp(ombre, autre.ombre, t)!,
      primaire: Color.lerp(primaire, autre.primaire, t)!,
      surPrimaire: Color.lerp(surPrimaire, autre.surPrimaire, t)!,
      primaireFonce: Color.lerp(primaireFonce, autre.primaireFonce, t)!,
      primaireVoile: Color.lerp(primaireVoile, autre.primaireVoile, t)!,
      secondaire: Color.lerp(secondaire, autre.secondaire, t)!,
      surSecondaire: Color.lerp(surSecondaire, autre.surSecondaire, t)!,
      secondaireFonce: Color.lerp(secondaireFonce, autre.secondaireFonce, t)!,
      secondaireTexte: Color.lerp(secondaireTexte, autre.secondaireTexte, t)!,
      secondaireVoile: Color.lerp(secondaireVoile, autre.secondaireVoile, t)!,
      succes: Color.lerp(succes, autre.succes, t)!,
      surSucces: Color.lerp(surSucces, autre.surSucces, t)!,
      succesVoile: Color.lerp(succesVoile, autre.succesVoile, t)!,
      avertissement: Color.lerp(avertissement, autre.avertissement, t)!,
      surAvertissement:
          Color.lerp(surAvertissement, autre.surAvertissement, t)!,
      avertissementVoile:
          Color.lerp(avertissementVoile, autre.avertissementVoile, t)!,
      erreur: Color.lerp(erreur, autre.erreur, t)!,
      surErreur: Color.lerp(surErreur, autre.surErreur, t)!,
      erreurVoile: Color.lerp(erreurVoile, autre.erreurVoile, t)!,
      info: Color.lerp(info, autre.info, t)!,
      surInfo: Color.lerp(surInfo, autre.surInfo, t)!,
      infoVoile: Color.lerp(infoVoile, autre.infoVoile, t)!,
      alerteElevee: Color.lerp(alerteElevee, autre.alerteElevee, t)!,
      surAlerteElevee: Color.lerp(surAlerteElevee, autre.surAlerteElevee, t)!,
    );
  }
}

/// Accès aux jetons de couleur depuis un `BuildContext`.
///
/// `context.couleurs.primaire` remplace `AppColors.primary` : la valeur suit
/// le mode d'affichage, là où une constante statique ne peut pas.
extension CouleursContexte on BuildContext {
  CouleursAgriSmart get couleurs =>
      Theme.of(this).extension<CouleursAgriSmart>() ?? CouleursAgriSmart.clair;
}
