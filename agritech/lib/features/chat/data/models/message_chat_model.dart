import '../../domain/entities/chat_reponse_entity.dart';
import '../../domain/entities/message_chat_entity.dart';

class MessageChatModel extends MessageChatEntity {
  const MessageChatModel({
    required super.role,
    required super.contenu,
    required super.horodatage,
    super.enErreur,
  });
}

class ChatReponseModel extends ChatReponseEntity {
  const ChatReponseModel({
    required super.conversationId,
    required super.message,
  });

  /// Construit la réponse depuis le corps de POST /agent/chat
  /// (`ReponseChat` côté backend : { conversationId, reponse, outilsUtilises }).
  factory ChatReponseModel.fromJson(Map<String, dynamic> json) =>
      ChatReponseModel(
        conversationId: json['conversationId'] as String,
        message: MessageChatModel(
          role: RoleChat.assistant,
          contenu: (json['reponse'] as String?) ??
              "Désolé, je n'ai pas pu formuler de réponse.",
          horodatage: DateTime.now(),
        ),
      );
}
