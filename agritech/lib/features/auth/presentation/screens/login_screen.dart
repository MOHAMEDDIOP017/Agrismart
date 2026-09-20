import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final PageController _bgCtrl = PageController();
  bool _isLoading = false;
  bool _mdpVisible = false;
  int _bgIndex = 0;
  Timer? _bgTimer;

  // ─── Verrouillage de sécurité ─────────────────────────────────────────────
  int _secondesRestantes = 0;
  Timer? _countdownTimer;

  static const _bgImages = [
    'https://c8.alamy.com/comp/2HR0R1M/an-africa-woman-harvests-produce-on-her-farm-in-the-senegal-river-valley-northern-senegal-west-africa-2HR0R1M.jpg',
    'https://cdn.pixabay.com/photo/2022/09/15/18/40/farmers-7457046_1280.jpg',
    'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=900&q=80',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _bgTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_bgIndex + 1) % _bgImages.length;
      _bgCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _bgIndex = next);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _bgCtrl.dispose();
    _bgTimer?.cancel();
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
        icon: const Icon(Icons.gpp_bad_rounded, color: AppColors.danger, size: 44),
        title: Text(
          'Alerte de sécurité',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trop de tentatives de connexion échouées.\n'
              'Votre accès est temporairement bloqué pendant '
              '${AuthState.dureeVerrouillage.inSeconds} secondes.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'Si vous avez oublié votre mot de passe, '
              'utilisez l\'option « Mot de passe oublié ».',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
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
              style: GoogleFonts.poppins(
                color: AppColors.primary,
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
      final route =
          ref.read(authProvider).valueOrNull?.routeInitiale ?? AppRoutes.dashboard;
      context.go(route);
    } else {
      // Pas de SnackBar si le compte vient d'être verrouillé
      // (le dialog de sécurité affiché via ref.listen gère ce cas)
      final newState = ref.read(authProvider).valueOrNull;
      if (newState?.isLocked != true && mounted) {
        final erreur = newState?.error ?? 'Connexion impossible. Vérifiez vos identifiants.';
        final message = erreur.replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // ── Background carousel ──────────────────────────────────
          Positioned.fill(
            child: PageView.builder(
              controller: _bgCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bgImages.length,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: _bgImages[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFF0D2B1A)),
                errorWidget: (_, __, ___) => Container(color: const Color(0xFF0D2B1A)),
              ),
            ),
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'KoobalaTech',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                const SizedBox(height: 12),
                Text(
                  'Agriculture\nintelligente',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    shadows: [const Shadow(color: Colors.black45, blurRadius: 10)],
                  ),
                ).animate(delay: 150.ms).fadeIn().slideX(begin: -0.15, end: 0),
                const SizedBox(height: 6),
                Text(
                  'Connectez-vous pour gérer vos champs',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ).animate(delay: 250.ms).fadeIn(),
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
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        Text(
                          'Connexion',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 4),
                        Text(
                          'Entrez vos identifiants pour continuer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 350.ms),
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
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
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
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _mdpVisible = !_mdpVisible),
                          ),
                        ).animate(delay: 480.ms).fadeIn().slideY(begin: 0.2, end: 0),

                        // ─── Compteur de tentatives restantes ──────────────
                        if (!isLocked && (authState?.tentativesEchouees ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '⚠ ${authState!.tentativesRestantes} tentative${authState.tentativesRestantes > 1 ? 's' : ''} '
                              'restante${authState.tentativesRestantes > 1 ? 's' : ''} avant blocage.',
                              style: GoogleFonts.inter(
                                color: AppColors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fonctionnalité à venir')),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight:
                                    isLocked ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ).animate(delay: 520.ms).fadeIn(),

                        // ─── Bannière de verrouillage ───────────────────────
                        if (isLocked) ...[
                          const SizedBox(height: 8),
                          _BanniereVerrouillage(secondesRestantes: _secondesRestantes),
                        ],

                        const SizedBox(height: 12),

                        // Bouton Se connecter
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_isLoading || isLocked) ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isLocked ? AppColors.textSecondary : AppColors.primary,
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
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ).animate(delay: 560.ms).fadeIn().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 16),

                        // Créer un compte
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pas encore de compte ? ',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.register),
                                child: Text(
                                  "S'inscrire",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 680.ms).fadeIn(),
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
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_rounded, color: AppColors.danger, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accès temporairement bloqué',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondesRestantes > 0
                      ? 'Réessayez dans $secondesRestantes seconde${secondesRestantes > 1 ? 's' : ''}.'
                      : 'Vous pouvez maintenant réessayer.',
                  style: GoogleFonts.inter(color: AppColors.danger, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de texte personnalisé avec style KoobalaTech
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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          textInputAction: action,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: Icon(icone, color: AppColors.primary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F7F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
