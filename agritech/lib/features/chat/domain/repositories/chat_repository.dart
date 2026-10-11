import '../entities/chat_reponse_entity.dart';

/// Contrat d'accès à l'agent conversationnel IA (POST /agent/chat).
///
/// L'historique est autoritaire côté serveur (persisté comme MessageChat,
/// diagramme UML) : on n'envoie plus la conversation complète à chaque appel,
/// seulement le [conversationId] du fil en cours (null pour en démarrer un
/// nouveau — le serveur en génère un et le renvoie dans la réponse).
/// [champId] désigne le champ actuellement consulté dans l'application. Quand
/// il est fourni, l'agent privilégie une recommandation à l'échelle de cette
/// parcelle plutôt qu'à l'échelle de la commune.
abstract class ChatRepository {
  Future<ChatReponseEntity> envoyerMessage({
    required String message,
    String? conversationId,
    String? champId,
  });
}
