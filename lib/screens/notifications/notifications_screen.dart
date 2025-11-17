import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser!.id;
    _notificationsStream = supabase
        .from('notificacoes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> _markAsRead(String id) async {
    try {
      await supabase
          .from('notificacoes')
          .update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('Erro ao marcar notificação: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = supabase.auth.currentUser!.id;
    try {
      await supabase
          .from('notificacoes')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Erro ao marcar todas: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await supabase.from('notificacoes').delete().eq('id', id);
    } catch (e) {
      debugPrint('Erro ao deletar notificação: $e');
    }
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'agendamento':
        return const Icon(Icons.calendar_month, color: Colors.blue);
      case 'chat':
        return const Icon(Icons.chat_bubble, color: Colors.indigo);
      case 'financeiro':
        return const Icon(Icons.attach_money, color: Colors.green);
      case 'sistema':
      default:
        return const Icon(Icons.notifications, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como lidas',
            onPressed: _markAllAsRead,
          )
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          
          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação por enquanto.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] as bool;
              final date = DateTime.parse(notification['created_at']).toLocal();
              final timeAgo = DateFormat('dd/MM HH:mm').format(date);

              return Dismissible(
                key: Key(notification['id']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNotification(notification['id']);
                },
                child: Container(
                  color: isRead ? Colors.white : Colors.blue.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: _getIconForType(notification['type']),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification['body']),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notification['id']);
                      }
                      // Futuro: Redirecionar baseado no 'related_id' e 'type'
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}