import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/champ_model.dart';
import '../../domain/entities/champ_entity.dart';
import '../providers/champ_provider.dart';

/// Formulaire création/modification d'un champ
class ChampFormScreen extends ConsumerStatefulWidget {
  const ChampFormScreen({super.key, this.champId});

  final String? champId;

  @override
  ConsumerState<ChampFormScreen> createState() => _ChampFormScreenState();
}

class _ChampFormScreenState extends ConsumerState<ChampFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  String? _typeSolSelectionne;
  String? _statutSelectionne = AppConstants.statutPrevu;
  String? _cultureSelectionnee;
  double? _latitude;
  double? _longitude;
  String? _photoPath;
  bool _isLoading = false;
  bool _isGpsLoading = false;
  ChampEntity? _champOriginal;

  bool get _isEditing => widget.champId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadChampData();
  }

  Future<void> _loadChampData() async {
    final champs = ref.read(champProvider).valueOrNull ?? [];
    final champ = champs.where((c) => c.id == widget.champId).firstOrNull;
    if (champ != null) {
      _champOriginal = champ;
      _nomCtrl.text = champ.nom;
      _superficieCtrl.text = champ.superficie.toString();
      setState(() {
        _typeSolSelectionne = champ.typeSol;
        _statutSelectionne = champ.statut;
        _cultureSelectionnee = champ.culture;
        _latitude = champ.latitude;
        _longitude = champ.longitude;
        // N'initialise _photoPath que si c'est un chemin local (pas une URL distante)
        final url = champ.photoUrl;
        if (url != null && !url.startsWith('http')) _photoPath = url;
      });
    }
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
    } catch (e) {
      // Coordonnées mock pour la démo
      setState(() {
        _latitude = 14.6937 + (DateTime.now().millisecond / 100000);
        _longitude = -17.4441 + (DateTime.now().millisecond / 100000);
      });
    } finally {
      setState(() => _isGpsLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_typeSolSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner le type de sol')),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (_isEditing) {
      final original = _champOriginal;
      if (original == null) {
        setState(() => _isLoading = false);
        return;
      }
      success = await ref.read(champProvider.notifier).updateChamp(
            ChampModel(
              id: original.id,
              nom: _nomCtrl.text.trim(),
              superficie: double.parse(
                  _superficieCtrl.text.replaceAll(',', '.')),
              typeSol: _typeSolSelectionne!,
              statut: _statutSelectionne!,
              culture: _cultureSelectionnee,
              latitude: _latitude,
              longitude: _longitude,
              photoUrl: _photoPath ?? original.photoUrl,
              dateCreation: original.dateCreation,
              userId: original.userId,
            ),
          );
    } else {
      success = await ref.read(champProvider.notifier).createChamp(
            nom: _nomCtrl.text.trim(),
            superficie: double.parse(
                _superficieCtrl.text.replaceAll(',', '.')),
            typeSol: _typeSolSelectionne!,
            statut: _statutSelectionne!,
            culture: _cultureSelectionnee,
            latitude: _latitude,
            longitude: _longitude,
            photoUrl: _photoPath,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sauvegarde'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 44),
            )
                .animate()
                .scale(begin: const Offset(0, 0), duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Champ mis à jour !' : 'Champ enregistré !',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isEditing
                  ? 'Les modifications ont été enregistrées.'
                  : 'Votre champ a été ajouté avec succès.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Voir mes champs'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _superficieCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le champ' : 'Nouveau champ'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo du champ
              _PhotoPicker(
                photoPath: _photoPath,
                onPick: _pickImage,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Nom du champ
              AppTextField(
                label: 'Nom du champ',
                hint: 'Ex: Champ Nord Thiès',
                controller: _nomCtrl,
                prefixIcon: Icons.terrain_rounded,
                validator: Validators.nom,
                textInputAction: TextInputAction.next,
              ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),

              // Superficie
              AppTextField(
                label: 'Superficie',
                hint: '2.5',
                controller: _superficieCtrl,
                prefixIcon: Icons.straighten_rounded,
                suffixText: 'ha',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}')),
                ],
                validator: Validators.superficie,
                textInputAction: TextInputAction.next,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),

              // Type de sol
              DropdownButtonFormField<String>(
                value: _typeSolSelectionne,
                hint: const Text('Sélectionner le type de sol'),
                decoration: const InputDecoration(
                  labelText: 'Type de sol',
                  prefixIcon: Icon(Icons.layers_outlined, size: 20),
                ),
                items: AppConstants.typesSol
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _typeSolSelectionne = v),
                validator: (v) => v == null ? 'Type de sol requis' : null,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),

              // Culture
              DropdownButtonFormField<String>(
                value: _cultureSelectionnee,
                hint: const Text('Culture actuelle (optionnel)'),
                decoration: const InputDecoration(
                  labelText: 'Culture',
                  prefixIcon: Icon(Icons.grass_rounded, size: 20),
                ),
                items: AppConstants.cultures
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _cultureSelectionnee = v),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),

              // Section GPS
              _GpsSection(
                latitude: _latitude,
                longitude: _longitude,
                isLoading: _isGpsLoading,
                onGetLocation: _getLocation,
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 32),

              // Bouton enregistrer
              AppButton(
                label: _isEditing ? 'Mettre à jour' : 'Enregistrer le champ',
                onPressed: _save,
                isLoading: _isLoading,
                icon: Icons.save_rounded,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onPick});

  final String? photoPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: photoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(photoPath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une photo du champ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GpsSection extends StatelessWidget {
  const _GpsSection({
    required this.latitude,
    required this.longitude,
    required this.isLoading,
    required this.onGetLocation,
  });

  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final VoidCallback onGetLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Localisation', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (latitude != null && longitude != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${latitude!.toStringAsFixed(4)}, Lng: ${longitude!.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 8),
        AppButton(
          label: isLoading ? 'Localisation...' : 'Obtenir ma position GPS',
          onPressed: isLoading ? null : onGetLocation,
          isLoading: isLoading,
          isOutlined: true,
          icon: Icons.my_location_rounded,
        ),
      ],
    );
  }
}
