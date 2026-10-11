import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../navigation/app_router.dart';
import '../providers/auth_provider.dart';

/// Écran de connexion redesigné — carousel de fond + card verre
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _mdpVisible = false;

  // ─── Verrouillage de sécurité ─────────────────────────────────────────────
  int _secondesRestantes = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ─── Gestion du compte à rebours de déverrouillage ───────────────────────

  void _demarrerCompteARebours() {
    _countdownTimer?.cancel();
    setState(() => _secondesRestantes = AuthState.dureeVerrouillage.inSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondesRestantes <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondesRestantes = 0);
        return;
      }
      setState(() => _secondesRestantes--);
    });
  }

  void _arreterCompteARebours() {
    _countdownTimer?.cancel();
    if (mounted) setState(() => _secondesRestantes = 0);
  }

  void _afficherAlerteSecurite() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.gpp_bad_rounded,
            color: context.couleurs.erreur, size: 44),
        title: Text(
          'Alerte de sécurité',
          style:
              AppTypography.police(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trop de tentatives de connexion échouées.\n'
              'Votre accès est temporairement bloqué pendant '
              '${AuthState.dureeVerrouillage.inSeconds} secondes.',
              style: AppTypography.police(
                color: context.couleurs.texteSecondaire,
                fontSize: 14,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'Si vous avez oublié votre mot de passe, '
              'utilisez l\'option « Mot de passe oublié ».',
              style: AppTypography.police(
                color: context.couleurs.texteSecondaire,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Compris',
              style: AppTypography.police(
                color: context.couleurs.primaire,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Soumission du formulaire ─────────────────────────────────────────────

  Future<void> _login() async {
    // Vérification préventive du verrouillage
    if (ref.read(authProvider).valueOrNull?.isLocked == true) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final route = ref.read(authProvider).valueOrNull?.routeInitiale ??
          AppRoutes.dashboard;
      context.go(route);
    } else {
      // Pas de SnackBar si le compte vient d'être verrouillé
      // (le dialog de sécurité affiché via ref.listen gère ce cas)
      final newState = ref.read(authProvider).valueOrNull;
      if (newState?.isLocked != true && mounted) {
        final erreur = newState?.error ??
            'Connexion impossible. Vérifiez vos identifiants.';
        final message = erreur.replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(message, style: AppTypography.police(color: Colors.white)),
            backgroundColor: context.couleurs.erreur,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    // Observe l'état auth pour réagir au verrouillage / déverrouillage
    final authState = ref.watch(authProvider).valueOrNull;
    final isLocked = authState?.isLocked ?? false;

    ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
      final wasLocked = prev?.valueOrNull?.isLocked ?? false;
      final nowLocked = next.valueOrNull?.isLocked ?? false;
      if (nowLocked && !wasLocked) {
        _demarrerCompteARebours();
        // Différé pour éviter d'appeler showDialog pendant un rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _afficherAlerteSecurite();
        });
      } else if (!nowLocked && wasLocked) {
        _arreterCompteARebours();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fond uni plutôt qu'un carrousel d'images.
          //
          // Trois photos de 900 à 1 280 pixels, tirées de trois services
          // distants différents, défilaient en boucle par un minuteur de cinq
          // secondes avec une animation de 900 ms. Sur l'écran de connexion,
          // c'est-à-dire avant tout accès au compte, cela demandait le réseau
          // pour afficher un décor, maintenait le processeur graphique actif
          // en permanence, et laissait un aplat vert hors couverture, c'est-
          // à-dire le cas le plus fréquent du terrain visé.
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFF0D2B1A)),
          ),

          // ── Gradient sombre ──────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.30, 0.55, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),

          // ── En-tête avec logo ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.couleurs.primaire,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AgriSmart',
                      style: AppTypography.police(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Agriculture\nintelligente',
                  style: AppTypography.police(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    shadows: [
                      const Shadow(color: Colors.black45, blurRadius: 10)
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connectez-vous pour gérer vos champs',
                  style: AppTypography.police(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── Card formulaire (bas de l'écran) ─────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxHeight: screenH * 0.78),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poignée
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: context.couleurs.bordure,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        Text(
                          'Connexion',
                          style: AppTypography.police(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.couleurs.textePrincipal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entrez vos identifiants pour continuer',
                          style: AppTypography.police(
                            fontSize: 13,
                            color: context.couleurs.texteSecondaire,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Champ email
                        _ChampTexte(
                          label: 'Email ou téléphone',
                          hint: 'exemple@uadb.sn',
                          controller: _emailCtrl,
                          icone: Icons.alternate_email_rounded,
                          type: TextInputType.emailAddress,
                          action: TextInputAction.next,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),

                        // Champ mot de passe
                        _ChampTexte(
                          label: 'Mot de passe',
                          hint: '••••••••',
                          controller: _passwordCtrl,
                          icone: Icons.lock_outline_rounded,
                          obscure: !_mdpVisible,
                          action: TextInputAction.done,
                          validator: Validators.password,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mdpVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: context.couleurs.texteSecondaire,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _mdpVisible = !_mdpVisible),
                          ),
                        ),

                        // ─── Compteur de tentatives restantes ──────────────
                        if (!isLocked &&
                            (authState?.tentativesEchouees ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '⚠ ${authState!.tentativesRestantes} tentative${authState.tentativesRestantes > 1 ? 's' : ''} '
                              'restante${authState.tentativesRestantes > 1 ? 's' : ''} avant blocage.',
                              style: AppTypography.police(
                                color: context.couleurs.secondaire,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Fonctionnalité à venir')),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppTypography.police(
                                fontSize: 13,
                                color: context.couleurs.primaire,
                                fontWeight: isLocked
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // ─── Bannière de verrouillage ───────────────────────
                        if (isLocked) ...[
                          const SizedBox(height: 8),
                          _BanniereVerrouillage(
                              secondesRestantes: _secondesRestantes),
                        ],

                        const SizedBox(height: 12),

                        // Bouton Se connecter
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_isLoading || isLocked) ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLocked
                                  ? context.couleurs.texteSecondaire
                                  : context.couleurs.primaire,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isLocked ? 'Accès bloqué' : 'Se connecter',
                                    style: AppTypography.police(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Créer un compte
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pas encore de compte ? ',
                                style: AppTypography.police(
                                  color: context.couleurs.texteSecondaire,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.register),
                                child: Text(
                                  "S'inscrire",
                                  style: AppTypography.police(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.couleurs.primaire,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bannière rouge affichée quand le compte est temporairement verrouillé
class _BanniereVerrouillage extends StatelessWidget {
  const _BanniereVerrouillage({required this.secondesRestantes});
  final int secondesRestantes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.couleurs.erreur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: context.couleurs.erreur.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_rounded,
                color: context.couleurs.erreur, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accès temporairement bloqué',
                  style: AppTypography.police(
                    fontWeight: FontWeight.w700,
                    color: context.couleurs.erreur,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondesRestantes > 0
                      ? 'Réessayez dans $secondesRestantes seconde${secondesRestantes > 1 ? 's' : ''}.'
                      : 'Vous pouvez maintenant réessayer.',
                  style: AppTypography.police(
                      color: context.couleurs.erreur, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de texte personnalisé avec style AgriSmart
class _ChampTexte extends StatelessWidget {
  const _ChampTexte({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icone,
    this.obscure = false,
    this.type = TextInputType.text,
    this.action = TextInputAction.next,
    this.validator,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icone;
  final bool obscure;
  final TextInputType type;
  final TextInputAction action;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.police(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.couleurs.textePrincipal,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          textInputAction: action,
          validator: validator,
          style: AppTypography.police(
              fontSize: 14, color: context.couleurs.textePrincipal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.police(
                color: context.couleurs.texteSecondaire, fontSize: 14),
            prefixIcon: Icon(icone, color: context.couleurs.primaire, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F7F6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.couleurs.bordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: context.couleurs.primaire, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.couleurs.erreur),
            ),
          ),
        ),
      ],
    );
  }
}
