import '../entities/chat_reponse_entity.dart';

/// Contrat d'accès à l'agent conversationnel IA (POST /agent/chat).
///
/// L'historique est autoritaire côté serveur (persisté comme MessageChat,
/// diagramme UML) : on n'envoie plus la conversation complète à chaque appel,
/// seulement le [conversationId] du fil en cours (null pour en démarrer un
/// nouveau — le serveur en génère un et le renvoie dans la réponse).
abstract class ChatRepository {
  Future<ChatReponseEntity> envoyerMessage({
    required String message,
    String? conversationId,
  });
}
