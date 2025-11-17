import '../main.dart';

class ChatService {
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
    }).select();

    await supabase
        .from('conversas')
        .update({
          'last_message': content,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversaId)
        .select();
  }
}
