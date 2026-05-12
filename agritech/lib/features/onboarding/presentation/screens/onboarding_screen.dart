import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';

/// Onboarding redesigné — images plein écran animées, typographie immersive
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _ctrl = PageController();
  int _currentPage = 0;
  late AnimationController _textCtrl;

  static const _pages = [
    _OnboardingData(
      imageUrl:
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=900&q=80',
      tag: 'GESTION DES CHAMPS',
      titre: 'Gérez vos\nparcelles\nintelligemment',
      sousTitre:
          'Suivez l\'état de vos champs, planifiez vos cultures et maximisez vos rendements.',
      accentColor: Color(0xFF1D9E75),
    ),
    _OnboardingData(
      imageUrl:
          'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80',
      tag: 'RECOMMANDATIONS IA',
      titre: 'Des conseils\nadaptés à votre\nclimat',
      sousTitre:
          'Notre IA analyse la météo locale et vous guide pour choisir les meilleures cultures.',
      accentColor: Color(0xFFEF9F27),
    ),
    _OnboardingData(
      imageUrl:
          'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=900&q=80',
      tag: 'DÉTECTION DE MALADIE',
      titre: 'Protégez vos\nplantes avec\nl\'IA',
      sousTitre:
          'Prenez une photo, notre modèle détecte la maladie et propose le traitement adapté.',
      accentColor: Color(0xFF00897B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _demarrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final accent = _pages[_currentPage].accentColor;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── PageView images plein écran ────────────────────
          PageView.builder(
            controller: _ctrl,
            itemCount: _pages.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _textCtrl.forward(from: 0);
            },
            itemBuilder: (_, i) => _PageImage(data: _pages[i]),
          ),

          // ── Gradient bas pour lisibilité ───────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          // ── Logo + Passer ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 16,
            child: Row(
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AgriSmart',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!isLast)
                  GestureDetector(
                    onTap: _demarrer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Passer',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Contenu bas ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  28, 0, 28, MediaQuery.of(context).padding.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tag de catégorie
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      key: ValueKey('tag_$_currentPage'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _pages[_currentPage].tag,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Grand titre
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.2), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOut)),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      _pages[_currentPage].titre,
                      key: ValueKey('title_$_currentPage'),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        shadows: [
                          const Shadow(
                              color: Colors.black54, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: Text(
                      _pages[_currentPage].sousTitre,
                      key: ValueKey('sub_$_currentPage'),
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Indicateurs + bouton
                  Row(
                    children: [
                      // Dots
                      Row(
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(right: 7),
                            width: i == _currentPage ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? accent
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Bouton Suivant / Commencer
                      GestureDetector(
                        onTap: isLast ? _demarrer : _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          padding: EdgeInsets.symmetric(
                            horizontal: isLast ? 28 : 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLast ? 'Commencer' : 'Suivant',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageImage extends StatelessWidget {
  const _PageImage({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: data.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(
        color: const Color(0xFF1A2E20),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF1A2E20),
        child: const Icon(Icons.eco, size: 100, color: Colors.white24),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.imageUrl,
    required this.tag,
    required this.titre,
    required this.sousTitre,
    required this.accentColor,
  });

  final String imageUrl;
  final String tag;
  final String titre;
  final String sousTitre;
  final Color accentColor;
}
