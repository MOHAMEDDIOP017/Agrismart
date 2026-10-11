import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../alertes/presentation/providers/alertes_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../../../recommandations/presentation/providers/derniere_recommandation_provider.dart';

/// Accueil de l'agriculteur.
///
/// L'écran répond à une seule question : que faire maintenant. Il s'ordonne
/// donc en quatre blocs, du plus utile au moins urgent, et ne propose qu'une
/// action pleine.
///
/// Ce qui a été retiré, et pourquoi.
///
/// **Le carrousel.** Quatre images d'illustration en 900 pixels, chargées
/// depuis un service distant, défilant en boucle par un `Timer.periodic` de
/// quatre secondes avec une animation de 700 ms. Sur un téléphone d'entrée de
/// gamme, cela maintient le processeur graphique occupé en permanence sur
/// l'écran d'ouverture. Hors couverture, les quatre images restaient vides.
/// Et aucune des quatre n'était cliquable : la moitié supérieure de l'accueil
/// ne menait nulle part.
///
/// **La grille de fonctionnalités.** Trois cartes illustrées, elles aussi par
/// des images distantes, qui dupliquaient trois entrées de la barre de
/// navigation. Avec les deux cartes d'accès rapide en dessous, l'écran offrait
/// huit chemins de même poids visuel : aucun ne se détachait, donc aucun ne
/// guidait.
///
/// **La pastille de notification pulsante.** Une animation en boucle infinie,
/// purement décorative, sur un écran qui reste ouvert.
///
/// Ce qui reste tient en quatre blocs : qui vous êtes, l'action principale, où
/// en sont vos parcelles, et ce que l'application a trouvé pour vous.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(authProvider).valueOrNull?.user;
    final champsAsync = ref.watch(champProvider);
    final derniereAsync = ref.watch(derniereRecommandationProvider);
    final alertesNonLues =
        ref.watch(alertesProvider).valueOrNull?.where((a) => !a.isLue).length ??
            0;

    return Scaffold(
      appBar: _EnTete(
        prenom: utilisateur?.prenom ?? '',
        lieu: utilisateur?.zoneGeographique ?? '',
        alertesNonLues: alertesNonLues,
        echelleTexte: MediaQuery.textScalerOf(context).scale(1),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(champProvider);
          ref.invalidate(derniereRecommandationProvider);
          await ref.read(champProvider.future);
        },
        child: ListView(
          padding: AppEspaces.liste,
          children: [
            // Ce que l'application a trouvé vient avant ce qu'elle propose de
            // faire : on lit d'abord le résultat, puis on décide d'en relancer
            // un. L'inverse demandait de passer devant un appel à l'action
            // pour atteindre la réponse déjà disponible.
            _DerniereRecommandation(derniereAsync: derniereAsync),
            const SizedBox(height: AppEspaces.md),
            const _ActionPrincipale(),
            const SizedBox(height: AppEspaces.lg),
            _ResumeChamps(champsAsync: champsAsync),
            const SizedBox(height: AppEspaces.lg),
            const _AccesAssistant(),
          ],
        ),
      ),
    );
  }
}

// ── En-tête ──────────────────────────────────────────────────────────────────

class _EnTete extends StatelessWidget implements PreferredSizeWidget {
  const _EnTete({
    required this.prenom,
    required this.lieu,
    required this.alertesNonLues,
    required this.echelleTexte,
  });

  final String prenom;
  final String lieu;
  final int alertesNonLues;

  /// Facteur d'agrandissement du texte, lu par l'écran et transmis ici.
  ///
  /// `preferredSize` doit renvoyer une hauteur sans avoir accès au contexte,
  /// donc sans pouvoir consulter `MediaQuery`. Avec une hauteur figée, l'en-tête
  /// rognait son contenu dès que l'utilisateur agrandissait le texte de son
  /// téléphone.
  final double echelleTexte;

  @override
  Size get preferredSize => Size.fromHeight(64 * echelleTexte + 8);

  /// Salutation selon l'heure. Le soir, « Bonjour » sonne faux.
  String get _salutation {
    final heure = DateTime.now().hour;
    return (heure >= 18 || heure < 5) ? 'Bonsoir' : 'Bonjour';
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;
    final titre = prenom.isEmpty ? _salutation : '$_salutation, $prenom';

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titre,
            style: textes.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (lieu.isNotEmpty)
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 16, color: couleurs.texteSecondaire),
                const SizedBox(width: AppEspaces.xxs),
                Flexible(
                  child: Text(
                    lieu,
                    style: textes.bodySmall
                        ?.copyWith(color: couleurs.texteSecondaire),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        _AccesAlertes(nonLues: alertesNonLues),
        const SizedBox(width: AppEspaces.xs),
      ],
    );
  }
}

/// Entrée vers les alertes : une icône et son libellé écrit.
///
/// La cloche seule contrevenait à la règle que le projet s'impose, une icône
/// n'allant jamais sans son mot. Une cloche se comprend dans beaucoup de
/// cultures d'interface, mais « beaucoup » n'est pas « toutes », et c'est
/// justement l'hypothèse que ce projet refuse de faire.
///
/// La disposition verticale reprend celle des onglets de la barre de
/// navigation : même geste, même forme, un apprentissage au lieu de deux.
class _AccesAlertes extends StatelessWidget {
  const _AccesAlertes({required this.nonLues});

  final int nonLues;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Semantics(
      button: true,
      label: nonLues == 0
          ? 'Alertes'
          : 'Alertes, $nonLues non lue${nonLues > 1 ? 's' : ''}',
      child: InkWell(
        onTap: () => context.push(AppRoutes.alertes),
        borderRadius: AppRayons.brCarte,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.xs,
            vertical: AppEspaces.xxs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // La pastille est posée à côté de l'icône et non par-dessus.
              // Superposée, elle recouvrait la cloche dès 130 % de taille de
              // texte : le compteur grandissait, l'icône non, et il ne restait
              // plus qu'un chiffre rouge sans objet auquel le rattacher.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_outlined,
                      size: 24, color: couleurs.textePrincipal),
                  if (nonLues > 0) ...[
                    const SizedBox(width: AppEspaces.xxs),
                    _Pastille(nombre: nonLues),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              // Même repli que dans la barre de navigation : le mot se réduit
              // plutôt que d'être coupé.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Alertes',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: couleurs.textePrincipal,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: couleurs.erreur,
        borderRadius: AppRayons.brPastille,
        border: Border.all(color: couleurs.surface, width: 1.5),
      ),
      child: Text(
        nombre > 99 ? '99+' : '$nombre',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: couleurs.surErreur,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
      ),
    );
  }
}

// ── Action principale ────────────────────────────────────────────────────────

/// Le seul bouton plein de l'écran.
///
/// Il était posé dans un encadré vert avec un titre et une phrase
/// d'explication, qui occupaient à eux trois environ 40 % du premier écran.
/// Le bloc disait ce que faisait le bouton ; le bouton le dit déjà. Réduit à
/// sa seule étiquette, il laisse remonter le contenu réel, et reste le seul
/// élément plein de la page, donc toujours le seul évident.
class _ActionPrincipale extends StatelessWidget {
  const _ActionPrincipale();

  @override
  Widget build(BuildContext context) {
    return AppBouton.principal(
      libelle: 'Obtenir une recommandation',
      icone: Icons.auto_awesome_rounded,
      onPressed: () => context.push(AppRoutes.recommandations),
    );
  }
}

// ── Résumé des parcelles ─────────────────────────────────────────────────────

class _ResumeChamps extends ConsumerWidget {
  const _ResumeChamps({required this.champsAsync});

  final AsyncValue<List<dynamic>> champsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      titre: 'Mes champs',
      actionLibelle: 'Voir tout',
      onAction: () => context.go(AppRoutes.champs),
      enfant: champsAsync.when(
        loading: () => const ZoneSquelette(
          child: Row(
            children: [
              Expanded(child: Squelette(hauteur: 76)),
              SizedBox(width: AppEspaces.sm),
              Expanded(child: Squelette(hauteur: 76)),
            ],
          ),
        ),
        error: (e, _) => BandeauErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(champProvider),
        ),
        data: (champs) {
          if (champs.isEmpty) {
            return _CarteInvite(
              icone: Icons.add_location_alt_outlined,
              titre: 'Aucune parcelle enregistrée',
              message: 'Ajoutez votre première parcelle pour recevoir des '
                  'recommandations.',
              libelleAction: 'Ajouter un champ',
              onAction: () => context.push('${AppRoutes.champs}/form'),
            );
          }

          final enCours = champs.where((c) => c.statut == 'EN_COURS').length;
          // `IntrinsicHeight` donne aux deux cartes la même hauteur, même
          // quand un libellé passe à la ligne, ce qui arrive dès 130 % de
          // taille de texte. Il faut l'envelopper ainsi parce que la liste ne
          // borne pas la hauteur : un `stretch` seul demanderait une hauteur
          // infinie. Le surcoût d'une passe de mesure supplémentaire est
          // négligeable sur deux cartes, et il ne concerne que ce bloc.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Compteur(
                    valeur: '${champs.length}',
                    libelle: champs.length > 1 ? 'parcelles' : 'parcelle',
                    icone: Icons.terrain_rounded,
                  ),
                ),
                const SizedBox(width: AppEspaces.sm),
                Expanded(
                  child: _Compteur(
                    valeur: '$enCours',
                    libelle:
                        enCours > 1 ? 'cultures en cours' : 'culture en cours',
                    icone: Icons.grass_rounded,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({
    required this.valeur,
    required this.libelle,
    required this.icone,
  });

  final String valeur;
  final String libelle;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: couleurs.separateur),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: couleurs.primaire),
          const SizedBox(height: AppEspaces.xs),
          Text(valeur, style: textes.headlineSmall),
          Text(
            libelle,
            style: textes.bodySmall?.copyWith(color: couleurs.texteSecondaire),
          ),
        ],
      ),
    );
  }
}

// ── Dernière recommandation ──────────────────────────────────────────────────

class _DerniereRecommandation extends ConsumerWidget {
  const _DerniereRecommandation({required this.derniereAsync});

  final AsyncValue<DerniereRecommandation?> derniereAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      titre: 'Dernière recommandation',
      enfant: derniereAsync.when(
        loading: () => const ZoneSquelette(child: SqueletteCarteCulture()),
        // L'erreur est affichée en bandeau et non en plein écran : le reste de
        // l'accueil reste utilisable, notamment l'action principale.
        error: (e, _) => BandeauErreur(
          erreur: e,
          onReessayer: () => ref.invalidate(derniereRecommandationProvider),
        ),
        data: (reco) {
          if (reco == null) {
            return const _CarteInvite(
              icone: Icons.auto_awesome_outlined,
              titre: 'Pas encore de recommandation',
              message: 'Lancez une analyse sur l\'une de vos parcelles pour '
                  'voir apparaître les cultures conseillées ici.',
            );
          }

          return CarteCulture(
            nomFrancais: reco.cultureNom,
            nomWolof: AppConstants.nomWolof(reco.cultureNom),
            tauxAptitude: reco.aptitudePct,
            miseEnValeur: true,
            informations: [
              LigneInfoCulture(
                icone: Icons.terrain_outlined,
                texte: reco.champNom,
              ),
              if (reco.periodePlantation.isNotEmpty)
                LigneInfoCulture(
                  icone: Icons.calendar_today_outlined,
                  texte: reco.periodePlantation,
                ),
            ],
            onTap: () => context.push(AppRoutes.recommandations),
          );
        },
      ),
    );
  }
}

// ── Accès à l'assistant ──────────────────────────────────────────────────────

class _AccesAssistant extends StatelessWidget {
  const _AccesAssistant();

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: couleurs.separateur),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 24, color: couleurs.primaire),
              const SizedBox(width: AppEspaces.xs),
              Expanded(
                child: Text('Une question ?', style: textes.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppEspaces.xxs),
          Text(
            'L\'assistant répond en français ou en wolof.',
            style: textes.bodyMedium?.copyWith(color: couleurs.texteSecondaire),
          ),
          const SizedBox(height: AppEspaces.sm),
          AppBouton.secondaire(
            libelle: 'Ouvrir l\'assistant',
            icone: Icons.chat_bubble_outline_rounded,
            onPressed: () => context.go(AppRoutes.assistant),
          ),
        ],
      ),
    );
  }
}

// ── Briques communes ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.titre,
    required this.enfant,
    this.actionLibelle,
    this.onAction,
  });

  final String titre;
  final Widget enfant;
  final String? actionLibelle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(titre, style: Theme.of(context).textTheme.titleSmall),
            ),
            if (actionLibelle != null && onAction != null)
              AppBouton.texte(libelle: actionLibelle!, onPressed: onAction),
          ],
        ),
        const SizedBox(height: AppEspaces.xs),
        enfant,
      ],
    );
  }
}

/// Carte d'invitation : ce qui manque, et comment l'obtenir.
///
/// Le même motif que [EtatVide], en version compacte, parce qu'ici le vide ne
/// concerne qu'une section et non l'écran entier.
class _CarteInvite extends StatelessWidget {
  const _CarteInvite({
    required this.icone,
    required this.titre,
    required this.message,
    this.libelleAction,
    this.onAction,
  });

  final IconData icone;
  final String titre;
  final String message;
  final String? libelleAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppEspaces.md),
      decoration: BoxDecoration(
        color: couleurs.surface,
        borderRadius: AppRayons.brCarte,
        border: Border.all(color: couleurs.separateur),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 24, color: couleurs.texteSecondaire),
              const SizedBox(width: AppEspaces.xs),
              Expanded(child: Text(titre, style: textes.titleSmall)),
            ],
          ),
          const SizedBox(height: AppEspaces.xxs),
          Text(
            message,
            style: textes.bodyMedium?.copyWith(color: couleurs.texteSecondaire),
          ),
          if (libelleAction != null && onAction != null) ...[
            const SizedBox(height: AppEspaces.sm),
            AppBouton.secondaire(
              libelle: libelleAction!,
              icone: Icons.add_rounded,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
