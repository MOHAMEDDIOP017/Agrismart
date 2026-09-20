import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message_chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(ref.read(dioProvider)),
);

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.conversationId,
    this.envoiEnCours = false,
    this.erreur,
  });

  final List<MessageChatEntity> messages;

  /// Fil de discussion en cours côté serveur (MessageChat.conversationId).
  /// Null tant qu'aucun message n'a encore été envoyé.
  final String? conversationId;
  final bool envoiEnCours;
  final String? erreur;

  ChatState copyWith({
    List<MessageChatEntity>? messages,
    String? conversationId,
    bool? envoiEnCours,
    String? erreur,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        conversationId: conversationId ?? this.conversationId,
        envoiEnCours: envoiEnCours ?? this.envoiEnCours,
        erreur: erreur,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  ChatState build() => const ChatState();

  Future<void> envoyer(String texte) async {
    final message = texte.trim();
    if (message.isEmpty || state.envoiEnCours) return;

    final messageUtilisateur = MessageChatEntity(
      role: RoleChat.utilisateur,
      contenu: message,
      horodatage: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, messageUtilisateur],
      envoiEnCours: true,
      erreur: null,
    );

    try {
      final reponse = await _repo.envoyerMessage(
        message: message,
        conversationId: state.conversationId,
      );
      state = state.copyWith(
        messages: [...state.messages, reponse.message],
        conversationId: reponse.conversationId,
        envoiEnCours: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          MessageChatEntity(
            role: RoleChat.assistant,
            contenu: "Je n'ai pas pu répondre : ${e.toString()}",
            horodatage: DateTime.now(),
            enErreur: true,
          ),
        ],
        envoiEnCours: false,
        erreur: e.toString(),
      );
    }
  }

  void reinitialiser() {
    state = const ChatState();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
