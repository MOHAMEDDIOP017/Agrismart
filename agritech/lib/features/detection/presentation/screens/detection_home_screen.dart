import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../providers/historique_provider.dart';
import '../widgets/diagnostic_mini_card.dart';

/// Écran 1 — Point d'entrée du module Détection redesigné
class DetectionHomeScreen extends ConsumerStatefulWidget {
  const DetectionHomeScreen({super.key});

  @override
  ConsumerState<DetectionHomeScreen> createState() =>
      _DetectionHomeScreenState();
}

class _DetectionHomeScreenState extends ConsumerState<DetectionHomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _bgCtrl = PageController();
  int _bgIndex = 0;
  Timer? _bgTimer;
  late AnimationController _fabCtrl;
  late Animation<double> _fabPulse;

  static const _bgImages = [
    'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=900&q=80',
    'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=900&q=80',
    'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80',
  ];

  static const _conseils = [
    '🌿 Centrez bien la feuille malade dans le cadre',
    '☀️ Prenez la photo en plein jour pour plus de précision',
    '📸 Évitez le flou — restez immobile au moment de la capture',
    '🔍 Choisissez une feuille représentative de la maladie',
  ];

  int _conseilIndex = 0;
  Timer? _conseilTimer;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fabPulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut),
    );

    _bgTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bgIndex + 1) % _bgImages.length;
      _bgCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic);
      setState(() => _bgIndex = next);
    });

    _conseilTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(
          () => _conseilIndex = (_conseilIndex + 1) % _conseils.length);
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _bgTimer?.cancel();
    _conseilTimer?.cancel();
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirGalerie() async {
    final xFile =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null || !mounted) return;
    context.push(AppRoutes.imagePreview, extra: File(xFile.path));
  }

  void _afficherInfoIA() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _InfoIASheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final derniers = ref.watch(derniersDiagnosticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E0B),
      floatingActionButton: AnimatedBuilder(
        animation: _fabPulse,
        builder: (_, child) =>
            Transform.scale(scale: _fabPulse.value, child: child),
        child: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.camera),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
          label: Text(
            'Photographier',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Hero visuel animé ────────────────────────────
          SliverToBoxAdapter(
            child: _HeroBanner(
              bgCtrl: _bgCtrl,
              bgImages: _bgImages,
              bgIndex: _bgIndex,
              onBgPageChanged: (i) => setState(() => _bgIndex = i),
              onInfo: _afficherInfoIA,
            ),
          ),

          // ── Corps ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Conseil rotatif
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.15), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: Container(
                    key: ValueKey(_conseilIndex),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _conseils[_conseilIndex],
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton principal — Caméra
                _BoutonAction(
                  label: 'Prendre une photo',
                  sousTitre: 'Ouvre la caméra guidée',
                  icone: Icons.camera_alt_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => context.push(AppRoutes.camera),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15, end: 0),

                const SizedBox(height: 12),

                // Bouton secondaire — Galerie
                _BoutonAction(
                  label: 'Choisir depuis la galerie',
                  sousTitre: 'Sélectionner une photo existante',
                  icone: Icons.photo_library_outlined,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A3A2E),
                      AppColors.primary.withValues(alpha: 0.6)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: _choisirGalerie,
                  outlined: true,
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.15, end: 0),

                const SizedBox(height: 32),

                // Section historique
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diagnostics récents',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (derniers.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.diagnosticHistorique),
                        child: Text(
                          'Voir tout',
                          style: GoogleFonts.inter(
                              color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                  ],
                ).animate(delay: 250.ms).fadeIn(),

                const SizedBox(height: 12),

                if (derniers.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: derniers.length,
                      itemBuilder: (_, i) => DiagnosticMiniCard(
                        diagnostic: derniers[i],
                        onTap: () => context.push(
                          AppRoutes.diagnosticResult,
                          extra: derniers[i],
                        ),
                      )
                          .animate(
                              delay: Duration(milliseconds: 300 + i * 80))
                          .fadeIn()
                          .slideX(begin: 0.15, end: 0),
                    ),
                  )
                else
                  _EmptyHistorique()
                      .animate(delay: 300.ms)
                      .fadeIn(),

                const SizedBox(height: 24),

                // Comment ça fonctionne
                _CommentCaMarche()
                    .animate(delay: 400.ms)
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ─────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.bgCtrl,
    required this.bgImages,
    required this.bgIndex,
    required this.onBgPageChanged,
    required this.onInfo,
  });

  final PageController bgCtrl;
  final List<String> bgImages;
  final int bgIndex;
  final void Function(int) onBgPageChanged;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Carousel de fond
          PageView.builder(
            controller: bgCtrl,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bgImages.length,
            onPageChanged: onBgPageChanged,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: bgImages[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF0A1F14)),
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF0A1F14)),
            ),
          ),

          // Overlay gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0x88000000),
                  Color(0x44000000),
                  Color(0xFF060E0B),
                ],
              ),
            ),
          ),

          // AppBar custom
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Détection IA',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Colors.white, size: 18),
                  ),
                  onPressed: onInfo,
                ),
              ],
            ),
          ),

          // Texte central
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'MODÈLE IA v2.1',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Détectez les maladies\nde vos plantes',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Indicateurs
          Positioned(
            bottom: 12,
            right: 20,
            child: Row(
              children: List.generate(
                bgImages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 5),
                  width: i == bgIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == bgIndex
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
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

// ── Bouton d'action principal ────────────────────────────────────

class _BoutonAction extends StatefulWidget {
  const _BoutonAction({
    required this.label,
    required this.sousTitre,
    required this.icone,
    required this.gradient,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final String sousTitre;
  final IconData icone;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool outlined;

  @override
  State<_BoutonAction> createState() => _BoutonActionState();
}

class _BoutonActionState extends State<_BoutonAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.outlined ? null : widget.gradient,
            borderRadius: BorderRadius.circular(18),
            border: widget.outlined
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.outlined
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icone,
                    color: widget.outlined ? AppColors.primary : Colors.white,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        color: widget.outlined ? AppColors.primary : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.sousTitre,
                      style: GoogleFonts.inter(
                        color: widget.outlined
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.outlined
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Historique vide ──────────────────────────────────────────────

class _EmptyHistorique extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 44, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            'Aucun diagnostic pour l\'instant',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Photographiez une plante pour commencer',
            style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Section "Comment ça marche" ──────────────────────────────────

class _CommentCaMarche extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final etapes = [
      (Icons.camera_alt_outlined, '1', 'Photographiez',
          'Prenez une photo nette de la feuille malade'),
      (Icons.psychology_outlined, '2', 'Analyse IA',
          'Notre modèle identifie la maladie en 2s'),
      (Icons.medical_services_outlined, '3', 'Traitement',
          'Recevez les traitements adaptés à votre culture'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment ça marche ?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...etapes.asMap().entries.map((e) {
            final step = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        step.$2,
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(step.$1, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$3,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          step.$4,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate(delay: Duration(milliseconds: 100 * e.key)).fadeIn(),
            );
          }),
        ],
      ),
    );
  }
}

// ── Info IA Sheet ────────────────────────────────────────────────

class _InfoIASheet extends StatelessWidget {
  const _InfoIASheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modèle IA AgriSmart',
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(
                        'Entraîné sur 50 000+ images de plantes africaines',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _InfoRow(icone: Icons.speed_outlined,
              texte: 'Analyse en moins de 2 secondes'),
          const _InfoRow(icone: Icons.verified_outlined,
              texte: 'Précision moyenne de 87% sur les maladies courantes'),
          const _InfoRow(icone: Icons.eco_outlined,
              texte: '8 maladies détectables — cultures africaines'),
          const _InfoRow(icone: Icons.wifi_off_outlined,
              texte: 'Mode hors-ligne disponible (modèle embarqué)'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icone, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
