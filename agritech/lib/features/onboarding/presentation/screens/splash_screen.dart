import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../../../navigation/expert_router.dart';
import '../../../../navigation/admin_router.dart';
import '../../../../core/theme/app_motion.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _bgImage =
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=900&q=80';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    // Le logo ne pulse plus. L'animation tournait en boucle pendant les
    // trois secondes de l'écran d'ouverture, sans rien annoncer : ni
    // chargement, ni progression.

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
    final hasToken = prefs.containsKey(AppConstants.keyUserData);

    if (!mounted) return;
    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (!hasToken) {
      context.go(AppRoutes.login);
    } else {
      // Déterminer la route initiale selon le rôle enregistré
      final userData = prefs.getString('user_data');
      String destination = AppRoutes.dashboard;
      if (userData != null) {
        try {
          final map = jsonDecode(userData) as Map<String, dynamic>;
          final role = (map['role'] as String? ?? '').toUpperCase();
          if (role == 'ADMIN') {
            destination = AdminRoutes.adminDashboard;
          } else if (role == 'EXPERT') {
            destination = ExpertRoutes.expertRecommandations;
          }
        } catch (_) {}
      }
      context.go(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image de fond ──────────────────────────────────
          CachedNetworkImage(
            imageUrl: _bgImage,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF0D2B1A)),
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFF0D2B1A)),
          ),

          // ── Gradient sombre ────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),

          // ── Contenu centré ─────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône et son halo
              Builder(
                builder: (_) {
                  return Transform.scale(
                    scale: 1,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: context.couleurs.primaire.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              context.couleurs.primaire.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.couleurs.primaire
                                .withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Nom de l'application
              Text(
                AppConstants.appName,
                style: AppTypography.police(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Agriculture intelligente',
                style: AppTypography.police(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 70),

              // Points de chargement animés
              _LoadingDots(),
            ],
          ),

          // ── Badge version bas d'écran ──────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0 — Sénégal',
              textAlign: TextAlign.center,
              style: AppTypography.police(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: AppDurees.moyenne,
      );
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 8,
            height: 8 + _controllers[i].value * 10,
            decoration: BoxDecoration(
              color: context.couleurs.primaire
                  .withValues(alpha: 0.5 + _controllers[i].value * 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
