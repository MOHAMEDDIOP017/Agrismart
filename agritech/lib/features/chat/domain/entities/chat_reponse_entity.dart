import 'package:equatable/equatable.dart';
import 'message_chat_entity.dart';

/// Réponse de l'agent à un envoi de message : le message assistant produit,
/// et le conversationId du fil (généré par le serveur au premier message,
/// à renvoyer tel quel pour les messages suivants — l'historique est
/// désormais autoritaire côté serveur, voir MessageChat).
class ChatReponseEntity extends Equatable {
  const ChatReponseEntity({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final MessageChatEntity message;

  @override
  List<Object?> get props => [conversationId, message];
}
