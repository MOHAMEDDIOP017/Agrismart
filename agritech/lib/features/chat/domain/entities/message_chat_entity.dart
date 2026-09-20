import 'package:equatable/equatable.dart';

/// Rôle de l'émetteur d'un message dans la conversation avec l'agent IA
enum RoleChat { utilisateur, assistant }

/// Un message échangé avec l'agent conversationnel AgriSmart (français/wolof)
class MessageChatEntity extends Equatable {
  const MessageChatEntity({
    required this.role,
    required this.contenu,
    required this.horodatage,
    this.enErreur = false,
  });

  final RoleChat role;
  final String contenu;
  final DateTime horodatage;

  /// true si ce message représente une erreur d'envoi (affiché différemment)
  final bool enErreur;

  bool get estUtilisateur => role == RoleChat.utilisateur;

  /// Rôle au format attendu par l'API backend ('user' / 'assistant')
  String get roleApi => estUtilisateur ? 'user' : 'assistant';

  @override
  List<Object?> get props => [role, contenu, horodatage];
}
