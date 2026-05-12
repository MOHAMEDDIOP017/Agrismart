import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_form_helpers.dart';

/// Formulaire de création d'un champ agricole — vue Administrateur
class CreerChampAdminScreen extends ConsumerStatefulWidget {
  const CreerChampAdminScreen({super.key});

  @override
  ConsumerState<CreerChampAdminScreen> createState() =>
      _CreerChampAdminScreenState();
}

class _CreerChampAdminScreenState extends ConsumerState<CreerChampAdminScreen> {
  static const Color _adminPrimary = Color(0xFF534AB7);

  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  final _agriculteurIdCtrl = TextEditingController();

  String? _typeSolSelectionne;
  String? _cultureSelectionnee;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isGpsLoading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _superficieCtrl.dispose();
    _agriculteurIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isGpsLoading = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (_) {
      setState(() {
        _latitude = 14.6937 + (DateTime.now().millisecond / 100000);
        _longitude = -17.4441 + (DateTime.now().millisecond / 100000);
      });
    } finally {
      setState(() => _isGpsLoading = false);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_typeSolSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner le type de sol'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ok = await ref.read(champsAdminProvider.notifier).creerChamp(
          nom: _nomCtrl.text.trim(),
          superficie:
              double.parse(_superficieCtrl.text.replaceAll(',', '.')),
          typeSol: _typeSolSelectionne!,
          latitude: _latitude,
          longitude: _longitude,
          culture: _cultureSelectionnee,
          agriculteurId: _agriculteurIdCtrl.text.trim().isEmpty
              ? null
              : _agriculteurIdCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Champ créé avec succès'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création du champ'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _adminPrimary,
        title: const Text(
          'Créer un champ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Informations principales ─────────────────────────
              const AdminSectionTitre(
                titre: 'Informations du champ',
                icone: Icons.terrain_rounded,
              ),
              const SizedBox(height: 12),

              // Nom du champ
              TextFormField(
                controller: _nomCtrl,
                decoration: adminDecorChamp('Nom du champ', Icons.label_outline),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),

              // Superficie
              TextFormField(
                controller: _superficieCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}')),
                ],
                decoration: adminDecorChamp('Superficie (ha)', Icons.straighten_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Valeur invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Type de sol
              DropdownButtonFormField<String>(
                value: _typeSolSelectionne,
                decoration: adminDecorChamp('Type de sol', Icons.layers_outlined),
                hint: const Text('Sélectionner'),
                items: AppConstants.typesSol
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _typeSolSelectionne = v),
                validator: (v) => v == null ? 'Type de sol requis' : null,
              ),
              const SizedBox(height: 12),

              // Culture
              DropdownButtonFormField<String>(
                value: _cultureSelectionnee,
                decoration: adminDecorChamp('Culture (optionnel)', Icons.grass_rounded),
                hint: const Text('Aucune'),
                items: AppConstants.cultures
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _cultureSelectionnee = v),
              ),

              const SizedBox(height: 24),

              // ── Propriétaire ──────────────────────────────────────
              const AdminSectionTitre(
                titre: 'Agriculteur propriétaire',
                icone: Icons.agriculture_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Optionnel — laissez vide pour attribuer le champ à votre compte admin.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _agriculteurIdCtrl,
                decoration: adminDecorChamp(
                  'ID de l\'agriculteur',
                  Icons.person_pin_outlined,
                ),
              ),

              const SizedBox(height: 24),

              // ── Localisation GPS ──────────────────────────────────
              const AdminSectionTitre(
                titre: 'Localisation',
                icone: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),

              if (_latitude != null && _longitude != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _isGpsLoading ? null : _getLocation,
                  icon: _isGpsLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                      _isGpsLoading ? 'Localisation...' : 'Obtenir ma position GPS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _adminPrimary,
                    side: const BorderSide(color: Color(0xFF534AB7)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Bouton créer ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _adminPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Créer le champ',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
