import 'package:careconnect_app/main.dart';

class NotificationService {
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return supabase
        .from('notificacoes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> markAsRead(String id) async {
    try {
      await supabase
          .from('notificacoes')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao marcar notificação: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await supabase
          .from('notificacoes')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Erro ao marcar todas como lidas: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await supabase.from('notificacoes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar notificação: $e');
    }
  }
}
