import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../navigation/app_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final PageController _bgCtrl = PageController();

  String? _zoneSelectionnee;
  bool _isLoading = false;
  bool _mdpVisible = false;
  bool _confirmVisible = false;
  int _bgIndex = 0;
  Timer? _bgTimer;

  static const _bgImages = [
    'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80',
    'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=900&q=80',
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
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _adresseCtrl.dispose();
    _villageCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _bgCtrl.dispose();
    _bgTimer?.cancel();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_zoneSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner votre zone géographique',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).register(
          nom: _nomCtrl.text.trim(),
          prenom: _prenomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _telCtrl.text.trim(),
          zoneGeographique: _zoneSelectionnee!,
          password: _passwordCtrl.text,
          adresse: _adresseCtrl.text.trim().isEmpty
              ? null
              : _adresseCtrl.text.trim(),
          villageVille: _villageCtrl.text.trim().isEmpty
              ? null
              : _villageCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final route = ref.read(authProvider).valueOrNull?.routeInitiale ??
          AppRoutes.dashboard;
      context.go(route);
    } else {
      final erreur = ref.read(authProvider).valueOrNull?.error ??
          "Erreur lors de l'inscription.";
      final message = erreur.replaceFirst(RegExp(r'^Exception:\s*'), '');
      final emailDejaUtilise = message.contains('existe déjà');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            action: emailDejaUtilise
                ? SnackBarAction(
                    label: 'Se connecter',
                    textColor: Colors.white70,
                    onPressed: () => context.go(AppRoutes.login),
                  )
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background carousel ────────────────────────────
          Positioned.fill(
            child: PageView.builder(
              controller: _bgCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bgImages.length,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: _bgImages[i],
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: const Color(0xFF0D2B1A)),
                errorWidget: (_, __, ___) =>
                    Container(color: const Color(0xFF0D2B1A)),
              ),
            ),
          ),

          // ── Gradient sombre ────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.25, 0.50, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // ── En-tête ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 28,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'KoobalaTech',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
          ),

          // ── Formulaire (bas) ───────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poignée
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Text(
                        'Inscription Agriculteur',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Rejoignez des milliers d\'agriculteurs connectés',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 20),

                      // Prénom & Nom
                      Row(
                        children: [
                          Expanded(
                            child: _ChampTexte(
                              label: 'Prénom',
                              hint: 'Mamadou',
                              controller: _prenomCtrl,
                              icone: Icons.person_outline_rounded,
                              validator: Validators.nom,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ChampTexte(
                              label: 'Nom',
                              hint: 'Diallo',
                              controller: _nomCtrl,
                              icone: Icons.badge_outlined,
                              validator: Validators.nom,
                            ),
                          ),
                        ],
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Zone géographique
                      _ZoneDropdown(
                        value: _zoneSelectionnee,
                        onChanged: (v) =>
                            setState(() => _zoneSelectionnee = v),
                      ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Téléphone
                      _ChampTexte(
                        label: 'Téléphone',
                        hint: '+221 77 000 00 00',
                        controller: _telCtrl,
                        icone: Icons.phone_outlined,
                        type: TextInputType.phone,
                        validator: Validators.phone,
                      ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Adresse
                      _ChampTexte(
                        label: 'Adresse',
                        hint: 'Ex : Route de Thiès, Km 3',
                        controller: _adresseCtrl,
                        icone: Icons.home_outlined,
                      ).animate(delay: 420.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Village / Ville
                      _ChampTexte(
                        label: 'Village / Ville',
                        hint: 'Ex : Mbour',
                        controller: _villageCtrl,
                        icone: Icons.location_city_outlined,
                      ).animate(delay: 435.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Email
                      _ChampTexte(
                        label: 'Email',
                        hint: 'exemple@koobalatec.sn',
                        controller: _emailCtrl,
                        icone: Icons.alternate_email_rounded,
                        type: TextInputType.emailAddress,
                        validator: Validators.email,
                      ).animate(delay: 440.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Mot de passe
                      _ChampTexte(
                        label: 'Mot de passe',
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        icone: Icons.lock_outline_rounded,
                        obscure: !_mdpVisible,
                        validator: Validators.password,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _mdpVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _mdpVisible = !_mdpVisible),
                        ),
                      ).animate(delay: 480.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),

                      // Confirmer mot de passe
                      _ChampTexte(
                        label: 'Confirmer le mot de passe',
                        hint: '••••••••',
                        controller: _confirmCtrl,
                        icone: Icons.lock_outline_rounded,
                        obscure: !_confirmVisible,
                        action: TextInputAction.done,
                        validator: Validators.confirmPassword(
                            _passwordCtrl.text),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _confirmVisible = !_confirmVisible),
                        ),
                      ).animate(delay: 520.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 22),

                      // Bouton S'inscrire
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : Text(
                                  "S'inscrire en tant qu'agriculteur",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ).animate(delay: 560.ms).fadeIn().slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // Note expert / admin
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous êtes agronome ou administrateur ? Contactez l\'administrateur de la plateforme pour obtenir un compte adapté à votre rôle.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 580.ms).fadeIn(),

                      const SizedBox(height: 12),

                      // Déjà inscrit
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Déjà inscrit ? ',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Se connecter',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 600.ms).fadeIn(),
                    ],
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          textInputAction: action,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: Icon(icone, color: AppColors.primary, size: 19),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F7F6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneDropdown extends StatelessWidget {
  const _ZoneDropdown({required this.value, required this.onChanged});

  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone géographique',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            'Sélectionner votre région',
            style:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          ),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Zone requise' : null,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 19),
            filled: true,
            fillColor: const Color(0xFFF5F7F6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
          items: AppConstants.villesSenegal
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
