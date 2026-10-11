import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../reseau/connectivite.dart';

/// Bandeau discret annonçant la perte du réseau, et son retour.
///
/// Se place en haut du corps de l'écran, au-dessus du contenu, et prend une
/// seule ligne. Rien n'est masqué, rien n'est bloqué : l'application continue
/// de fonctionner avec les dernières données reçues, et le bandeau explique
/// simplement pourquoi les chiffres ne bougent plus.
///
/// Le retour du réseau est annoncé, puis le bandeau disparaît de lui-même.
/// Sans cette confirmation, la personne qui a vu « pas de connexion » n'a
/// aucun moyen de savoir quand réessayer : elle relance au hasard. Avec elle,
/// le moment est donné.
///
/// Le libellé reste prudent, parce que ce que le système rapporte est l'état
/// des interfaces et non l'accès réel à Internet. Un téléphone accroché à une
/// antenne sans données utilisables se déclare connecté. Le bandeau ne couvre
/// donc que la coupure franche ; la connexion faible est signalée par le
/// message d'erreur de l'écran, lui déclenché par un vrai échec de requête.
class BandeauHorsConnexion extends ConsumerStatefulWidget {
  const BandeauHorsConnexion({super.key});

  @override
  ConsumerState<BandeauHorsConnexion> createState() =>
      _BandeauHorsConnexionState();
}

enum _Affichage { masque, horsLigne, retabli }

class _BandeauHorsConnexionState extends ConsumerState<BandeauHorsConnexion> {
  _Affichage _affichage = _Affichage.masque;
  Timer? _effacement;

  /// Durée pendant laquelle le retour du réseau reste annoncé.
  static const _dureeConfirmation = Duration(seconds: 4);

  @override
  void dispose() {
    _effacement?.cancel();
    super.dispose();
  }

  void _surChangement(bool horsLigne) {
    _effacement?.cancel();

    if (horsLigne) {
      setState(() => _affichage = _Affichage.horsLigne);
      return;
    }

    // Le retour n'est confirmé que si une coupure avait été annoncée : au
    // premier lancement, personne n'a besoin d'apprendre que le réseau marche.
    if (_affichage != _Affichage.horsLigne) {
      setState(() => _affichage = _Affichage.masque);
      return;
    }

    setState(() => _affichage = _Affichage.retabli);
    _effacement = Timer(_dureeConfirmation, () {
      if (mounted) setState(() => _affichage = _Affichage.masque);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(estHorsLigneProvider, (_, horsLigne) {
      _surChangement(horsLigne);
    });

    // État initial : si le réseau est déjà coupé au premier affichage, le
    // `listen` ci-dessus ne se déclenchera pas, puisqu'il n'y a pas de
    // changement à observer.
    final horsLigneMaintenant = ref.watch(estHorsLigneProvider);
    final affichage = horsLigneMaintenant ? _Affichage.horsLigne : _affichage;

    return AnimatedSize(
      duration: AppMouvement.duree(context, AppDurees.courte),
      curve: AppCourbes.sortie,
      alignment: Alignment.topCenter,
      child: switch (affichage) {
        _Affichage.masque => const SizedBox(width: double.infinity),
        _Affichage.horsLigne => const _Ligne(
            icone: Icons.wifi_off_rounded,
            texte: 'Pas de connexion. Vous voyez les dernières données reçues.',
            ton: _TonLigne.avertissement,
          ),
        _Affichage.retabli => const _Ligne(
            icone: Icons.wifi_rounded,
            texte: 'Connexion rétablie.',
            ton: _TonLigne.succes,
          ),
      },
    );
  }
}

enum _TonLigne { avertissement, succes }

class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.texte, required this.ton});

  final IconData icone;
  final String texte;
  final _TonLigne ton;

  @override
  Widget build(BuildContext context) {
    final couleurs = context.couleurs;
    final (fond, teinte) = switch (ton) {
      _TonLigne.avertissement => (
          couleurs.avertissementVoile,
          couleurs.avertissement
        ),
      _TonLigne.succes => (couleurs.succesVoile, couleurs.succes),
    };

    return Semantics(
      // Annoncé aux lecteurs d'écran au moment où le bandeau apparaît, sans
      // attendre que le doigt passe dessus.
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: fond,
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspaces.md,
          vertical: AppEspaces.xs,
        ),
        child: Row(
          children: [
            Icon(icone, size: 18, color: teinte),
            const SizedBox(width: AppEspaces.xs),
            Expanded(
              child: Text(
                texte,
                // Le texte principal et non la teinte : sur un fond teinté,
                // la couleur de famille descend sous le seuil AA.
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: couleurs.textePrincipal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
