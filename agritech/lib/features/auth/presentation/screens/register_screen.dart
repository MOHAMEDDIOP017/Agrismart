import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
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

  String? _zoneSelectionnee;
  bool _isLoading = false;
  bool _mdpVisible = false;
  bool _confirmVisible = false;

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
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _adresseCtrl.dispose();
    _villageCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_zoneSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner votre zone géographique',
            style: AppTypography.police(color: Colors.white),
          ),
          backgroundColor: context.couleurs.erreur,
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
              style: AppTypography.police(color: Colors.white),
            ),
            backgroundColor: context.couleurs.erreur,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        color: context.couleurs.primaire,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AgriSmart',
                      style: AppTypography.police(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Formulaire (bas) ───────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                            color: context.couleurs.bordure,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Text(
                        'Inscription Agriculteur',
                        style: AppTypography.police(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.couleurs.textePrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rejoignez des milliers d\'agriculteurs connectés',
                        style: AppTypography.police(
                          fontSize: 13,
                          color: context.couleurs.texteSecondaire,
                        ),
                      ),
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
                      ),
                      const SizedBox(height: 12),

                      // Zone géographique
                      _ZoneDropdown(
                        value: _zoneSelectionnee,
                        onChanged: (v) => setState(() => _zoneSelectionnee = v),
                      ),
                      const SizedBox(height: 12),

                      // Téléphone
                      _ChampTexte(
                        label: 'Téléphone',
                        hint: '+221 77 000 00 00',
                        controller: _telCtrl,
                        icone: Icons.phone_outlined,
                        type: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 12),

                      // Adresse
                      _ChampTexte(
                        label: 'Adresse',
                        hint: 'Ex : Route de Thiès, Km 3',
                        controller: _adresseCtrl,
                        icone: Icons.home_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Village / Ville
                      _ChampTexte(
                        label: 'Village / Ville',
                        hint: 'Ex : Mbour',
                        controller: _villageCtrl,
                        icone: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      _ChampTexte(
                        label: 'Email',
                        hint: 'exemple@agrismart.sn',
                        controller: _emailCtrl,
                        icone: Icons.alternate_email_rounded,
                        type: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
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
                            color: context.couleurs.texteSecondaire,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _mdpVisible = !_mdpVisible),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Confirmer mot de passe
                      _ChampTexte(
                        label: 'Confirmer le mot de passe',
                        hint: '••••••••',
                        controller: _confirmCtrl,
                        icone: Icons.lock_outline_rounded,
                        obscure: !_confirmVisible,
                        action: TextInputAction.done,
                        validator:
                            Validators.confirmPassword(_passwordCtrl.text),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: context.couleurs.texteSecondaire,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _confirmVisible = !_confirmVisible),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Bouton S'inscrire
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.couleurs.primaire,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  "S'inscrire en tant qu'agriculteur",
                                  style: AppTypography.police(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Note expert / admin
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              context.couleurs.primaire.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: context.couleurs.primaire
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: context.couleurs.primaire),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous êtes agronome ou administrateur ? Contactez l\'administrateur de la plateforme pour obtenir un compte adapté à votre rôle.',
                                style: AppTypography.police(
                                  fontSize: 11,
                                  color: context.couleurs.texteSecondaire,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Déjà inscrit
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Déjà inscrit ? ',
                              style: AppTypography.police(
                                  color: context.couleurs.texteSecondaire,
                                  fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Se connecter',
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
          style: AppTypography.police(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.couleurs.textePrincipal,
          ),
        ),
        const SizedBox(height: 6),
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
            prefixIcon: Icon(icone, color: context.couleurs.primaire, size: 19),
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
              borderSide: BorderSide(color: context.couleurs.bordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: context.couleurs.primaire, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.couleurs.erreur),
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
          style: AppTypography.police(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.couleurs.textePrincipal,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            'Sélectionner votre région',
            style: AppTypography.police(
                color: context.couleurs.texteSecondaire, fontSize: 14),
          ),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Zone requise' : null,
          style: AppTypography.police(
              fontSize: 14, color: context.couleurs.textePrincipal),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: context.couleurs.primaire),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined,
                color: context.couleurs.primaire, size: 19),
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
              borderSide: BorderSide(color: context.couleurs.bordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: context.couleurs.primaire, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.couleurs.erreur),
            ),
          ),
          items: AppConstants.villesSenegal
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v,
                        style: AppTypography.police(
                            fontSize: 14,
                            color: context.couleurs.textePrincipal)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
