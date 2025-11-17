import 'package:careconnect_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversaId) {
    return supabase
        .from('mensagens')
        .stream(primaryKey: ['id'])
        .eq('conversa_id', conversaId)
        .order('created_at', ascending: true);
  }

  Future<void> markConversationAsRead({
    required String conversaId,
    required String currentUserId,
  }) async {
    try {
      await supabase
          .from('mensagens')
          .update({'is_read': true})
          .eq('conversa_id', conversaId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Falha ao marcar mensagens como lidas: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchConversations(
    String currentUserId,
  ) async {
    try {
      final data = await supabase
          .from('conversas')
          .select(
            '*, familiar:familiar_id(id, nome, avatar_url), cuidador:cuidador_id(id, usuarios(id, nome, avatar_url))',
          )
          .order('updated_at', ascending: false);

      final List<Map<String, dynamic>> conversas =
          List<Map<String, dynamic>>.from(data);

      for (var chat in conversas) {
        final countResponse = await supabase
            .from('mensagens')
            .select('id')
            .eq('conversa_id', chat['id'])
            .neq('sender_id', currentUserId)
            .eq('is_read', false)
            .count(CountOption.exact);

        chat['unread_count'] = countResponse.count;
      }

      return conversas;
    } catch (e) {
      throw Exception('Erro ao carregar conversas: $e');
    }
  }

  static Future<String> startConversation({
    required String familiarId,
    required String cuidadorId,
  }) async {
    try {
      final existing = await supabase
          .from('conversas')
          .select('id')
          .eq('familiar_id', familiarId)
          .eq('cuidador_id', cuidadorId)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      final newChat = await supabase
          .from('conversas')
          .insert({
            'familiar_id': familiarId,
            'cuidador_id': cuidadorId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return newChat['id'] as String;
    } catch (e) {
      throw Exception('Erro ao iniciar chat: $e');
    }
  }

  static Future<void> sendMessage({
    required String conversaId,
    required String content,
    required String senderId,
  }) async {
    await supabase.from('mensagens').insert({
      'conversa_id': conversaId,
      'sender_id': senderId,
      'content': content,
    });

    await supabase
        .from('conversas')
        .update({
          'last_message': content,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversaId);
  }

  static Stream<int> getUnreadCountStream(String userId) {
    return supabase
        .from('mensagens')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .map((list) {
          final unreadCount = list.where((msg) {
            return msg['sender_id'] != userId;
          }).length;
          return unreadCount;
        });
  }
}
