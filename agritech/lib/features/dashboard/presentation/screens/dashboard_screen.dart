import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../meteo/presentation/providers/meteo_provider.dart';
import '../../../alertes/presentation/providers/alertes_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../../navigation/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../champs/presentation/providers/champ_provider.dart';
import '../widgets/meteo_card.dart';

/// Tableau de bord redesigné avec carousel animé et design moderne
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final PageController _carouselCtrl = PageController();
  int _carouselIndex = 0;
  Timer? _carouselTimer;

  // Images agricoles africaines du carousel
  static const _carouselSlides = [
    _SlideData(
      imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=900&q=80',
      titre: 'Gérez vos parcelles',
      sousTitre: 'Suivez chaque champ en temps réel',
      couleur: Color(0xFF0D6E4E),
    ),
    _SlideData(
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=900&q=80',
      titre: 'Détectez les maladies',
      sousTitre: 'IA de pointe pour protéger vos cultures',
      couleur: Color(0xFF1A4A6B),
    ),
    _SlideData(
      imageUrl: 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=900&q=80',
      titre: 'Optimisez vos rendements',
      sousTitre: 'Recommandations climatiques personnalisées',
      couleur: Color(0xFF5B3A00),
    ),
    _SlideData(
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80',
      titre: 'Alertes intelligentes',
      sousTitre: 'Ne ratez jamais une action critique',
      couleur: Color(0xFF1D2E1A),
    ),
    _SlideData(
      imageUrl: 'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=900&q=80',
      titre: 'AgriSmart Sénégal',
      sousTitre: 'L\'agriculture de demain, aujourd\'hui',
      couleur: Color(0xFF3D1C00),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_carouselIndex + 1) % _carouselSlides.length;
      _carouselCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final champsState = ref.watch(champProvider);
    final user = authState.valueOrNull?.user;
    final meteoAsync = ref.watch(meteoProvider);
    final alertesNonLues = ref.watch(alertesProvider).valueOrNull?.where((a) => !a.isLue).length ?? 0;
    final notifsNonLues = ref.watch(nonLuesCountProvider);
    final champsCount = champsState.valueOrNull?.length ?? 0;
    final culturesActives =
        champsState.valueOrNull?.where((c) => c.statut == 'EN_COURS').length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F2),
      body: CustomScrollView(
        slivers: [
          // ── AppBar transparente ──────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 0,
            toolbarHeight: 56,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'AgriSmart',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  if (notifsNonLues > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$notifsNonLues',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                          .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 700.ms)
                          .then()
                          .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 700.ms),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Contenu ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                // CAROUSEL HERO
                _HeroCarousel(
                  ctrl: _carouselCtrl,
                  slides: _carouselSlides,
                  indexActuel: _carouselIndex,
                  onPageChanged: (i) => setState(() => _carouselIndex = i),
                  user: user?.nomComplet ?? 'Agriculteur',
                  ville: user?.zoneGeographique ?? 'Sénégal',
                ),

                // ── Stats flottantes ──────────────────────────
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _StatsFlottantes(
                    champsCount: champsCount,
                    culturesActives: culturesActives,
                    alertes: alertesNonLues,
                  ),
                ),

                // ── Météo ─────────────────────────────────────
                meteoAsync.when(
                  data: (meteo) => meteo == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: MeteoCard(meteo: meteo)
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: SizedBox(height: 90),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // ── Fonctionnalités ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        'Fonctionnalités',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FeatureGrid(
                  features: [
                    _Feature(
                      titre: 'Mes Champs',
                      sousTitre: '$champsCount parcelles',
                      icone: Icons.terrain_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=400&q=70',
                      onTap: () => context.go(AppRoutes.champs),
                    ),
                    _Feature(
                      titre: 'Recommandations',
                      sousTitre: 'IA climatique',
                      icone: Icons.psychology_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF9F27), Color(0xFFBA7517)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&q=70',
                      onTap: () => context.go(AppRoutes.recommandations),
                    ),
                    _Feature(
                      titre: 'Détection',
                      sousTitre: 'Maladie IA',
                      icone: Icons.document_scanner_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF00695C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&q=70',
                      onTap: () => context.go(AppRoutes.detection),
                    ),
                    _Feature(
                      titre: 'Alertes',
                      sousTitre: '$alertesNonLues non lues',
                      icone: Icons.notifications_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD85A30), Color(0xFFB04020)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: 'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=400&q=70',
                      onTap: () => context.go(AppRoutes.alertes),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Accès rapide ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Text(
                    'Accès rapide',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _QuickCard(
                  imageUrl: 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=700&q=70',
                  titre: 'Données agronomiques',
                  sousTitre: 'pH, NPK, humidité de vos champs',
                  icone: Icons.science_outlined,
                  onTap: () => context.push('/home/dashboard/donnees-agro'),
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                _QuickCard(
                  imageUrl: 'https://images.unsplash.com/photo-1536782376847-5c9d14d97cc0?w=700&q=70',
                  titre: 'Suivi des champs',
                  sousTitre: 'Vue liste et grille de vos parcelles',
                  icone: Icons.track_changes_rounded,
                  onTap: () => context.push('/home/dashboard/suivi'),
                ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Carousel ─────────────────────────────────────────────────

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.ctrl,
    required this.slides,
    required this.indexActuel,
    required this.onPageChanged,
    required this.user,
    required this.ville,
  });

  final PageController ctrl;
  final List<_SlideData> slides;
  final int indexActuel;
  final void Function(int) onPageChanged;
  final String user;
  final String ville;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          // Carousel
          PageView.builder(
            controller: ctrl,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => _SlideItem(slide: slides[i]),
          ),

          // Salutation utilisateur (haut)
          Positioned(
            top: 64,
            left: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, 👋',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                Text(
                  user,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(color: Colors.black45, blurRadius: 8),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      ville,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Texte du slide (bas)
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey(indexActuel),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slides[indexActuel].titre,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(color: Colors.black54, blurRadius: 10),
                      ],
                    ),
                  ),
                  Text(
                    slides[indexActuel].sousTitre,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicateurs de page
          Positioned(
            bottom: 18,
            left: 20,
            child: Row(
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == indexActuel ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == indexActuel
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
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

class _SlideItem extends StatelessWidget {
  const _SlideItem({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image de fond
        CachedNetworkImage(
          imageUrl: slide.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: slide.couleur),
          errorWidget: (_, __, ___) => Container(
            color: slide.couleur,
            child: const Icon(Icons.eco, size: 80, color: Colors.white24),
          ),
        ),

        // Gradient sombre pour lisibilité
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.65),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats flottantes ─────────────────────────────────────────────

class _StatsFlottantes extends StatelessWidget {
  const _StatsFlottantes({
    required this.champsCount,
    required this.culturesActives,
    required this.alertes,
  });

  final int champsCount;
  final int culturesActives;
  final int alertes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              valeur: '$champsCount',
              label: 'Champs',
              icone: Icons.terrain_rounded,
              couleur: AppColors.primary,
            ),
            _Diviseur(),
            _StatItem(
              valeur: '$culturesActives',
              label: 'En cours',
              icone: Icons.grass_rounded,
              couleur: AppColors.amber,
            ),
            _Diviseur(),
            _StatItem(
              valeur: '$alertes',
              label: 'Alertes',
              icone: Icons.notifications_active_rounded,
              couleur: alertes > 0 ? AppColors.coral : AppColors.textSecondary,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 150.ms, duration: 500.ms)
          .slideY(begin: 0.3, end: 0),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.valeur,
    required this.label,
    required this.icone,
    required this.couleur,
  });

  final String valeur;
  final String label;
  final IconData icone;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: couleur, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          valeur,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Diviseur extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: AppColors.border);
  }
}

// ── Feature Grid ─────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<_Feature> features;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: features.length,
        itemBuilder: (_, i) => _FeatureCard(feature: features[i])
            .animate(delay: Duration(milliseconds: 80 * i))
            .fadeIn()
            .scale(begin: const Offset(0.92, 0.92)),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.feature.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond
              CachedNetworkImage(
                imageUrl: widget.feature.image,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(gradient: widget.feature.gradient),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(gradient: widget.feature.gradient),
                ),
              ),

              // Overlay gradient
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(widget.feature.icone, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      widget.feature.titre,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.feature.sousTitre,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Card ───────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.imageUrl,
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.onTap,
  });

  final String imageUrl;
  final String titre;
  final String sousTitre;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.primary),
                  errorWidget: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  ),
                ),

                // Overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),

                // Contenu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icone, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              titre,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              sousTitre,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.imageUrl,
    required this.titre,
    required this.sousTitre,
    required this.couleur,
  });

  final String imageUrl;
  final String titre;
  final String sousTitre;
  final Color couleur;
}

class _Feature {
  const _Feature({
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.gradient,
    required this.image,
    required this.onTap,
  });

  final String titre;
  final String sousTitre;
  final IconData icone;
  final LinearGradient gradient;
  final String image;
  final VoidCallback onTap;
}
