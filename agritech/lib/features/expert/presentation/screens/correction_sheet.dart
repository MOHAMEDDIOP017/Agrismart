import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../mock_data/maladies_mock.dart';
import '../../domain/enums/decision_expert.dart';
import '../../../detection/domain/enums/type_traitement.dart';
import '../../../detection/domain/enums/niveau_gravite.dart';
import '../providers/expert_provider.dart';

/// BottomSheet de correction complète d'un diagnostic IA
class CorrectionSheet extends StatefulWidget {
  const CorrectionSheet({
    super.key,
    required this.diagnosticId,
    required this.notifier,
    required this.onDone,
  });

  final String diagnosticId;
  final DiagnosticsNotifier notifier;
  final VoidCallback onDone;

  @override
  State<CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<CorrectionSheet> {
  DecisionExpert _decision = DecisionExpert.partiellement;
  String? _maladieSelecteeId;
  String _maladieNom = '';
  NiveauGravite _gravite = NiveauGravite.modere;
  TypeTraitement _typeTraitement = TypeTraitement.chimique;

  final _traitementCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  double _duree = 14;
  bool _notifier = true;
  bool _isLoading = false;
  bool _showSearch = false;

  @override
  void dispose() {
    _traitementCtrl.dispose();
    _dosageCtrl.dispose();
    _observationsCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _maladiesFiltrees {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return maladiesMock;
    return maladiesMock
        .where((m) => m.nom.toLowerCase().contains(q) ||
            m.nomScientifique.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corriger le diagnostic IA',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Posez votre propre diagnostic',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // ── Section A : Décision ──────────────────────
                  _sectionTitle('A. Votre décision'),
                  const SizedBox(height: 8),
                  Row(
                    children: DecisionExpert.values
                        .map((d) => Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _decision = d),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _decision == d
                                        ? d.couleurFond
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _decision == d
                                          ? d.couleur
                                          : AppColors.border,
                                      width: _decision == d ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(d.icone, color: d.couleur, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        d.libelle,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: d.couleur,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Section B : Maladie ───────────────────────
                  _sectionTitle('B. Vraie maladie'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() => _showSearch = true),
                    onTap: () => setState(() => _showSearch = true),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une maladie...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      suffixText:
                          _maladieSelecteeId != null ? _maladieNom : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  if (_showSearch) ...[
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: _maladiesFiltrees
                            .map((m) => ListTile(
                                  dense: true,
                                  title: Text(m.nom,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, fontWeight: FontWeight.w600)),
                                  subtitle: Text(m.nomScientifique,
                                      style: GoogleFonts.inter(
                                          fontSize: 11, fontStyle: FontStyle.italic)),
                                  onTap: () {
                                    setState(() {
                                      _maladieSelecteeId = m.id;
                                      _maladieNom = m.nom;
                                      _searchCtrl.text = m.nom;
                                      _showSearch = false;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Section C : Gravité ───────────────────────
                  _sectionTitle('C. Niveau de gravité réel'),
                  const SizedBox(height: 8),
                  Row(
                    children: NiveauGravite.values
                        .map((g) => Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _gravite = g),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _gravite == g ? g.couleurFond : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _gravite == g ? g.couleur : AppColors.border,
                                      width: _gravite == g ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(g.icone, color: g.couleur, size: 16),
                                      const SizedBox(height: 2),
                                      Text(
                                        g.libelle,
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: g.couleur,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Section D : Traitement ────────────────────
                  _sectionTitle('D. Traitement recommandé'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _traitementCtrl,
                    label: 'Produit / traitement',
                    hint: 'ex: Mancozèbe 80 WP',
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _dosageCtrl,
                    label: 'Dosage',
                    hint: 'ex: 2,5 kg/ha',
                  ),
                  const SizedBox(height: 10),
                  // Type traitement
                  SegmentedButton<TypeTraitement>(
                    segments: TypeTraitement.values
                        .map((t) => ButtonSegment(
                              value: t,
                              label: Text(
                                t.libelle,
                                style: GoogleFonts.poppins(fontSize: 10),
                              ),
                            ))
                        .toList(),
                    selected: {_typeTraitement},
                    onSelectionChanged: (s) =>
                        setState(() => _typeTraitement = s.first),
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Durée slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Durée traitement',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('${_duree.round()} jours',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _duree,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _duree = v),
                  ),

                  const SizedBox(height: 20),

                  // ── Section E : Observations ──────────────────
                  _sectionTitle('E. Observations'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observationsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Observations détaillées...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notifier l\'agriculteur immédiatement',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _notifier,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _notifier = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Bouton soumettre ──────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _soumettre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Soumettre la correction'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );

  Future<void> _soumettre() async {
    if (_traitementCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un traitement.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await widget.notifier.corrigerDiagnostic(
      diagnosticId: widget.diagnosticId,
      decision: _decision,
      maladieId: _maladieSelecteeId ?? 'mil_001',
      niveauGravite: _gravite,
      traitement: _traitementCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
      duree: _duree.round(),
      typeTraitement: _typeTraitement,
      observations: _observationsCtrl.text.trim().isEmpty
          ? null
          : _observationsCtrl.text.trim(),
      notifierAgriculteur: _notifier,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      widget.onDone();
    }
  }
}
