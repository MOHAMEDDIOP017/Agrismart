import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/chat_reponse_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/message_chat_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<ChatReponseEntity> envoyerMessage({
    required String message,
    String? conversationId,
    String? champId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.agentChat,
      data: {
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
        if (champId != null) 'champId': champId,
      },
    );
    return ChatReponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}
