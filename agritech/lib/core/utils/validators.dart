/// Validateurs de formulaire pour AgriSmart
class Validators {
  Validators._();

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email requis';
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Email invalide';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Téléphone requis';
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.trim().replaceAll(' ', ''))) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  static String? Function(String?) confirmPassword(String? password) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Confirmation requise';
      if (value != password) return 'Les mots de passe ne correspondent pas';
      return null;
    };
  }

  static String? superficie(String? value) {
    if (value == null || value.trim().isEmpty) return 'Superficie requise';
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return 'Valeur numérique invalide';
    if (parsed <= 0) return 'La superficie doit être positive';
    if (parsed > 10000) return 'Superficie trop grande';
    return null;
  }

  static String? nom(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nom requis';
    if (value.trim().length < 2) return 'Minimum 2 caractères';
    return null;
  }
}
