import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// BottomSheet de sélection d'un expert agricole pour partager un diagnostic
class ExpertSelectionSheet extends StatefulWidget {
  const ExpertSelectionSheet({required this.diagnosticId, super.key});

  final String diagnosticId;

  @override
  State<ExpertSelectionSheet> createState() => _ExpertSelectionSheetState();
}

class _ExpertSelectionSheetState extends State<ExpertSelectionSheet> {
  int? _expertSelectionne;
  bool _envoiConfirme = false;
  final _messageCtrl = TextEditingController();

  final _experts = const [
    _Expert('exp_001', 'Dr. Moussa Diallo', 'Phytopathologie', 'Thiès', true),
    _Expert('exp_002', 'Mme Aïssatou Ndiaye', 'Agronomie générale', 'Dakar', true),
    _Expert('exp_003', 'M. Ibrahima Sarr', 'Cultures céréalières', 'Kaolack', false),
    _Expert('exp_004', 'Dr. Fatou Ba', 'Maraîchage', 'Ziguinchor', true),
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_expertSelectionne == null) return;
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _envoiConfirme = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _envoiConfirme
              ? _ConfirmationView()
              : Column(
                  children: [
                    _Handle(),
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Partager avec un expert',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Experts disponibles dans votre zone',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._experts.asMap().entries.map((e) {
                            final i = e.key;
                            final expert = e.value;
                            return _ExpertCard(
                              expert: expert,
                              selectionne: _expertSelectionne == i,
                              onTap: () => setState(() => _expertSelectionne = i),
                            );
                          }),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _messageCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Ajouter un message (optionnel)...',
                              hintStyle: GoogleFonts.inter(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed:
                                _expertSelectionne != null ? _envoyer : null,
                            child: const Text('Envoyer le diagnostic'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({
    required this.expert,
    required this.selectionne,
    required this.onTap,
  });

  final _Expert expert;
  final bool selectionne;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectionne
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectionne ? AppColors.primary : AppColors.border,
            width: selectionne ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                expert.nom.substring(expert.nom.lastIndexOf(' ') + 1)[0],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert.nom,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${expert.specialite} • ${expert.zone}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _DispoIndicateur(enLigne: expert.enLigne),
          ],
        ),
      ),
    );
  }
}

class _DispoIndicateur extends StatefulWidget {
  const _DispoIndicateur({required this.enLigne});

  final bool enLigne;

  @override
  State<_DispoIndicateur> createState() => _DispoIndicateurState();
}

class _DispoIndicateurState extends State<_DispoIndicateur>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.enLigne) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleur = widget.enLigne ? AppColors.primary : AppColors.textSecondary;
    final label = widget.enLigne ? 'En ligne' : 'Hors ligne';

    if (!widget.enLigne) {
      return _buildChip(couleur, label, 1.0);
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => _buildChip(couleur, label, _anim.value),
    );
  }

  Widget _buildChip(Color couleur, String label, double opacity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1 * opacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: couleur,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
          const SizedBox(height: 16),
          Text(
            'Diagnostic envoyé !',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'expert vous répondra dans les 24 heures.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Expert {
  const _Expert(this.id, this.nom, this.specialite, this.zone, this.enLigne);

  final String id;
  final String nom;
  final String specialite;
  final String zone;
  final bool enLigne;
}
