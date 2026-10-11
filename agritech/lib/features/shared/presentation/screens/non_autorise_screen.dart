import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Écran affiché quand un compte atteint une section qui ne lui est pas
/// ouverte.
///
/// C'est le seul écran de l'application où l'on arrive sans l'avoir demandé :
/// la redirection vient de la garde de rôle du routeur. La personne n'a donc
/// rien fait de mal, et le texte évite de le lui reprocher. Deux sorties lui
/// sont offertes, parce que les deux cas existent : soit le compte est le bon
/// et il suffit de revenir en arrière, soit il ne l'est pas et il faut changer
/// de compte.
class NonAutoriseScreen extends ConsumerWidget {
  const NonAutoriseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(currentUserProvider);
    final accueil = utilisateur?.routeHome ?? '/login';

    return Scaffold(
      appBar: BarreTitre(titre: 'Accès refusé', routeRepli: accueil),
      body: CadreEtat(
        sujet: SujetIllustration.recherche,
        titre: 'Cette section ne vous est pas ouverte',
        message: 'Votre compte n\'a pas accès à cette partie de '
            'l\'application. Revenez à votre accueil, ou connectez-vous avec '
            'un autre compte.',
        action: Column(
          children: [
            AppBouton.principal(
              libelle: 'Revenir à l\'accueil',
              icone: Icons.home_rounded,
              pleineLargeur: false,
              onPressed: () => context.go(accueil),
            ),
            const SizedBox(height: AppEspaces.xs),
            AppBouton.texte(
              libelle: 'Changer de compte',
              icone: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
