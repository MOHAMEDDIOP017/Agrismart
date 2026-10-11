import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/champ_model.dart';
import '../../domain/entities/champ_entity.dart';
import '../providers/champ_provider.dart';
import '../../../../shared/widgets/widgets.dart';

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
  final _adresseCtrl = TextEditingController();
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
      _adresseCtrl.text = champ.adresse;
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
      await _proposerAdresse(pos.latitude, pos.longitude);
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

  /// Propose une adresse déduite des coordonnées GPS (géocodage inverse).
  ///
  /// Confort de saisie uniquement : le champ reste modifiable, et une adresse
  /// déjà saisie n'est jamais écrasée. Le géocodeur natif échoue hors ligne ou
  /// en zone rurale peu cartographiée — cas fréquent ici, d'où l'échec
  /// silencieux : l'agriculteur saisit alors l'adresse lui-même.
  Future<void> _proposerAdresse(double latitude, double longitude) async {
    if (_adresseCtrl.text.trim().isNotEmpty) return;
    try {
      final lieux = await placemarkFromCoordinates(latitude, longitude);
      if (lieux.isEmpty || !mounted) return;
      final l = lieux.first;
      final parties = [
        l.subLocality,
        l.locality,
        l.subAdministrativeArea,
        l.administrativeArea,
      ].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toSet();
      if (parties.isEmpty) return;
      setState(() => _adresseCtrl.text = parties.join(', '));
    } catch (_) {
      // Géocodeur indisponible : on laisse la saisie manuelle.
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
              superficie:
                  double.parse(_superficieCtrl.text.replaceAll(',', '.')),
              typeSol: _typeSolSelectionne!,
              adresse: _adresseCtrl.text.trim(),
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
            superficie: double.parse(_superficieCtrl.text.replaceAll(',', '.')),
            typeSol: _typeSolSelectionne!,
            adresse: _adresseCtrl.text.trim(),
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
      // Le dépôt renvoie un booléen sans porter la cause : le message reste
      // le plus général de ceux que traduit MessageErreur.
      RetourAction.echec(context, null);
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
            // Le rebond de la marque dit que quelque chose vient d'aboutir.
            // L'ancienne version animait cette coche sur une courbe élastique
            // écrite ici même ; elle est maintenant dans un composant partagé,
            // qui la supprime quand l'utilisateur a demandé moins
            // d'animations.
            MarqueSucces(
              texte: _isEditing ? 'Champ mis à jour' : 'Champ enregistré',
            ),
            const SizedBox(height: 8),
            Text(
              _isEditing
                  ? 'Les modifications ont été enregistrées.'
                  : 'Votre champ a été ajouté avec succès.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.couleurs.texteSecondaire,
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
    _adresseCtrl.dispose();
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
              ),

              const SizedBox(height: 24),

              // Nom du champ
              AppChampTexte(
                libelle: 'Nom du champ',
                exemple: 'Ex: Champ Nord Thiès',
                controleur: _nomCtrl,
                icone: Icons.terrain_rounded,
                validateur: Validators.nom,
                actionClavier: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Superficie
              AppChampTexte(
                libelle: 'Superficie',
                exemple: '2.5',
                controleur: _superficieCtrl,
                icone: Icons.straighten_rounded,
                suffixe: 'ha',
                clavier: const TextInputType.numberWithOptions(decimal: true),
                formateurs: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[\.,]?\d{0,2}')),
                ],
                validateur: Validators.superficie,
                actionClavier: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Adresse — obligatoire, comme côté serveur. Pré-remplie par
              // géocodage inverse après « Localiser », modifiable ensuite.
              AppChampTexte(
                libelle: 'Adresse',
                exemple: 'Ex: Ngoundiane, Thiès',
                controleur: _adresseCtrl,
                icone: Icons.place_outlined,
                validateur: (v) =>
                    Validators.required(v, fieldName: "L'adresse"),
                actionClavier: TextInputAction.next,
              ),
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
              ),
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
              ),
              const SizedBox(height: 24),

              // Section GPS
              _GpsSection(
                latitude: _latitude,
                longitude: _longitude,
                isLoading: _isGpsLoading,
                onGetLocation: _getLocation,
              ),

              const SizedBox(height: 32),

              // Bouton enregistrer
              AppBouton.principal(
                libelle: _isEditing ? 'Mettre à jour' : 'Enregistrer le champ',
                onPressed: _save,
                icone: Icons.save_rounded,
                enChargement: _isLoading,
              ),

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
          color: context.couleurs.primaire.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.couleurs.primaire.withValues(alpha: 0.3),
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
                  Icon(
                    Icons.add_a_photo_rounded,
                    color: context.couleurs.primaire,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une photo du champ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.couleurs.primaire,
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
              color: context.couleurs.primaire.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: context.couleurs.primaire.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: context.couleurs.primaire, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${latitude!.toStringAsFixed(4)}, Lng: ${longitude!.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.couleurs.primaire,
                      ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        AppBouton.secondaire(
          libelle: isLoading ? 'Localisation...' : 'Obtenir ma position GPS',
          onPressed: isLoading ? null : onGetLocation,
          icone: Icons.my_location_rounded,
          enChargement: isLoading,
        ),
      ],
    );
  }
}
