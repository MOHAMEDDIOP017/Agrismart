import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../champs/domain/entities/champ_entity.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';

/// Assistant conversationnel.
///
/// C'est l'écran le plus accessible de l'application pour qui lit mal le
/// français : on y pose sa question comme on la dirait, en français ou en
/// wolof. Il est maintenant un onglet, et non plus une sous-page à deux
/// niveaux sous l'accueil.
///
/// Le sélecteur de parcelle en haut change ce que l'agent peut répondre. Sans
/// parcelle, il raisonne à l'échelle de la commune ; avec une parcelle, il
/// connaît son sol et sa position. Cette bascule existait dans le provider,
/// alimentée seulement par le paramètre d'URL quand on ouvrait l'assistant
/// depuis une parcelle : rien, dans l'écran, ne permettait de la voir ni de la
/// changer.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.champId});

  /// Parcelle depuis laquelle l'assistant a été ouvert.
  final String? champId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.champId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chatProvider.notifier).definirChampCourant(widget.champId);
        }
      });
    }
  }

  @override
  void dispose() {
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _versLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_defilement.hasClients) return;
      _defilement.animateTo(
        _defilement.position.maxScrollExtent,
        duration: AppMouvement.duree(context, AppDurees.moyenne),
        curve: AppCourbes.sortie,
      );
    });
  }

  Future<void> _envoyer(String texte) async {
    if (texte.trim().isEmpty) return;
    _saisie.clear();
    await ref.read(chatProvider.notifier).envoyer(texte);
    _versLeBas();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(chatProvider);
    final champsAsync = ref.watch(champProvider);
    ref.listen(chatProvider, (_, __) => _versLeBas());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        actions: [
          if (etat.messages.isNotEmpty)
            IconButton(
              tooltip: 'Nouvelle conversation',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(chatProvider.notifier).reinitialiser(),
            ),
        ],
      ),
      body: Column(
        children: [
          _SelecteurParcelle(
            champs: champsAsync.valueOrNull ?? const [],
            choisi: etat.champIdCourant,
            onChoisir: (id) =>
                ref.read(chatProvider.notifier).definirChampCourant(id),
          ),
          Expanded(
            child: etat.messages.isEmpty
                ? _Accueil(onSuggestion: _envoyer)
                : ListView.builder(
                    controller: _defilement,
                    padding: AppEspaces.liste,
                    itemCount:
                        etat.messages.length + (etat.envoiEnCours ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == etat.messages.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: etat.messages[index]);
                    },
                  ),
          ),
          _BarreDeSaisie(
            controleur: _saisie,
            enCours: etat.envoiEnCours,
            onEnvoyer: () => _envoyer(_saisie.text),
          ),
        ],
      ),
    );
  }
}

// ── Sélecteur de parcelle ────────────────────────────────────────────────────

/// Bande de puces en haut de l'écran : sur quoi porte la conversation.
///
/// Des puces plutôt qu'une liste déroulante : le choix est visible sans
/// ouvrir quoi que ce soit, et l'exploitation familiale visée compte quelques
/// parcelles, pas cinquante.
class _SelecteurParcelle extends StatelessWidget {
  const _SelecteurParcelle({
    required this.champs,
    required this.choisi,
    required this.onChoisir,
  });

  final List<ChampEntity> champs;
  final String? choisi;
  final void Function(String?) onChoisir;

  @override
  Widget build(BuildContext context) {
    if (champs.isEmpty) return const SizedBox.shrink();

    final couleurs = context.couleurs;

    return Container(
      decoration: BoxDecoration(
        color: couleurs.surface,
        border: Border(bottom: BorderSide(color: couleurs.separateur)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppEspaces.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppEspaces.md),
        child: Row(
          children: [
            _Puce(
              libelle: 'Toutes mes parcelles',
              icone: Icons.public_rounded,
              choisi: choisi == null,
              onTap: () => onChoisir(null),
            ),
            for (final champ in champs) ...[
              const SizedBox(width: AppEspaces.xs),
              _Puce(
                libelle: champ.nom,
                icone: Icons.terrain_rounded,
                choisi: champ.id == choisi,
                onTap: () => onChoisir(champ.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  const _Puce({
    required this.libelle,
    required this.icone,
    required this.choisi,
    required this.onTap,
  });

  final String libelle;
  final IconData icone;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Semantics(
      selected: choisi,
      button: true,
      child: ZoneTactile(
        onTap: onTap,
        rayon: AppRayons.brPastille,
        tailleMinimale: null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaces.sm,
            vertical: AppEspaces.xs,
          ),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: choisi ? couleurs.primaire : couleurs.surface,
            borderRadius: AppRayons.brPastille,
            border: Border.all(
              color: choisi ? couleurs.primaire : couleurs.bordure,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                size: 18,
                color: choisi ? couleurs.surPrimaire : couleurs.texteSecondaire,
              ),
              const SizedBox(width: AppEspaces.xxs),
              Text(
                libelle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: choisi
                          ? couleurs.surPrimaire
                          : couleurs.textePrincipal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Conversation vide ────────────────────────────────────────────────────────

class _Accueil extends StatelessWidget {
  const _Accueil({required this.onSuggestion});

  final void Function(String) onSuggestion;

  /// Trois questions, dont une en wolof, parce que l'agent y répond et que
  /// rien d'autre dans l'application ne le dit.
  static const _suggestions = [
    'Quelles cultures pour Kaolack ?',
    'Comment traiter le mildiou de la tomate ?',
    'Naka lay mengue mbay yi ci Ziguinchor ?',
  ];

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final textes = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: AppEspaces.liste,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppEspaces.lg),
          const Center(child: Illustration(sujet: SujetIllustration.parcelle)),
          const SizedBox(height: AppEspaces.md),
          Text(
            'Posez votre question',
            style: textes.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppEspaces.xxs),
          Text(
            'L\'assistant répond en français ou en wolof.',
            style: textes.bodyMedium?.copyWith(color: couleurs.texteSecondaire),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppEspaces.lg),
          Text('Par exemple', style: textes.titleSmall),
          const SizedBox(height: AppEspaces.xs),
          // Les suggestions sont empilées plutôt que mises côte à côte : des
          // questions entières ne tiennent pas sur une ligne à 360 dp, et les
          // couper les rendrait illisibles.
          for (final question in _suggestions) ...[
            _Suggestion(
              question: question,
              onTap: () => onSuggestion(question),
            ),
            const SizedBox(height: AppEspaces.xs),
          ],
        ],
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.question, required this.onTap});

  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return ZoneTactile(
      onTap: onTap,
      rayon: AppRayons.brCarte,
      tailleMinimale: null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspaces.sm,
          vertical: AppEspaces.sm,
        ),
        decoration: BoxDecoration(
          color: couleurs.primaireVoile,
          borderRadius: AppRayons.brCarte,
          border: Border.all(color: couleurs.primaire),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded,
                size: 20, color: couleurs.primaire),
            const SizedBox(width: AppEspaces.xs),
            Expanded(
              child: Text(
                question,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(Icons.north_east_rounded,
                size: 18, color: couleurs.texteSecondaire),
          ],
        ),
      ),
    );
  }
}

// ── Saisie ───────────────────────────────────────────────────────────────────

class _BarreDeSaisie extends StatelessWidget {
  const _BarreDeSaisie({
    required this.controleur,
    required this.enCours,
    required this.onEnvoyer,
  });

  final TextEditingController controleur;
  final bool enCours;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Container(
      decoration: BoxDecoration(
        color: couleurs.surface,
        border: Border(top: BorderSide(color: couleurs.separateur)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppEspaces.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controleur,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onEnvoyer(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Écrivez en français ou en wolof',
                    // Le champ de la conversation n'a pas de libellé au-dessus,
                    // contrairement aux formulaires : ce qu'on écrit ici est
                    // évident, et une étiquette volerait une ligne à l'écran
                    // sur un clavier déjà ouvert.
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
              ),
              const SizedBox(width: AppEspaces.xs),
              _BoutonEnvoyer(enCours: enCours, onEnvoyer: onEnvoyer),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonEnvoyer extends StatelessWidget {
  const _BoutonEnvoyer({required this.enCours, required this.onEnvoyer});

  final bool enCours;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;

    return Semantics(
      button: true,
      label: enCours ? 'Envoi en cours' : 'Envoyer la question',
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: enCours ? couleurs.separateur : couleurs.primaire,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enCours ? null : onEnvoyer,
            child: Center(
              child: enCours
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          couleurs.texteSecondaire,
                        ),
                      ),
                    )
                  : Icon(Icons.send_rounded,
                      color: couleurs.surPrimaire, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
