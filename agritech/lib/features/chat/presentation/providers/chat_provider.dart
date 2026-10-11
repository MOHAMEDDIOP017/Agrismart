import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/erreurs/message_erreur.dart';
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
    this.champIdCourant,
    this.envoiEnCours = false,
    this.erreur,
  });

  final List<MessageChatEntity> messages;

  /// Fil de discussion en cours côté serveur (MessageChat.conversationId).
  /// Null tant qu'aucun message n'a encore été envoyé.
  final String? conversationId;

  /// Champ consulté dans l'application, transmis à l'agent comme contexte pour
  /// qu'il recommande à l'échelle de la parcelle et non de la commune.
  final String? champIdCourant;

  final bool envoiEnCours;
  final String? erreur;

  ChatState copyWith({
    List<MessageChatEntity>? messages,
    String? conversationId,
    String? champIdCourant,
    bool? envoiEnCours,
    String? erreur,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        conversationId: conversationId ?? this.conversationId,
        champIdCourant: champIdCourant ?? this.champIdCourant,
        envoiEnCours: envoiEnCours ?? this.envoiEnCours,
        erreur: erreur,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  ChatState build() => const ChatState();

  /// Déclare le champ actuellement consulté : l'agent le recevra comme
  /// contexte et préférera une recommandation à l'échelle de la parcelle.
  void definirChampCourant(String? champId) {
    if (champId == state.champIdCourant) return;
    state = state.copyWith(champIdCourant: champId);
  }

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
        champId: state.champIdCourant,
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
            // Seule ligne de ce provider touchée par la refonte : elle
            // produit un texte lu par l'utilisateur, et affichait la trace
            // d'exception dans la bulle de l'agent.
            contenu: MessageErreur.pour(e),
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

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
