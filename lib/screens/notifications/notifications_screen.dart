import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  late final Stream<List<Map<String, dynamic>>> _notificationsStream;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user == null) {
      _userId = 'INVALID';
      _notificationsStream = Stream.value([]);
    } else {
      _userId = user.id;
      _notificationsStream = _notificationService.getNotificationsStream(
        _userId,
      );
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
    } catch (e) {
      debugPrint('Erro ao marcar notificação: $e');
      _showError('Erro ao marcar como lida.');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_userId == 'INVALID') return;
    try {
      await _notificationService.markAllAsRead(_userId);
    } catch (e) {
      debugPrint('Erro ao marcar todas: $e');
      _showError('Erro ao marcar todas como lidas.');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
    } catch (e) {
      debugPrint('Erro ao deletar notificação: $e');
      _showError('Erro ao deletar notificação.');
    }
  }

  Icon _getIconForType(String type) {
    Color color;
    IconData icon;
    switch (type) {
      case 'agendamento':
        color = AppColors.primary;
        icon = Icons.calendar_month;
        break;
      case 'chat':
        color = AppColors.primary;
        icon = Icons.chat_bubble;
        break;
      case 'financeiro':
        color = AppColors.success;
        icon = Icons.attach_money;
        break;
      case 'sistema':
      default:
        color = AppColors.warning;
        icon = Icons.notifications;
        break;
    }
    return Icon(icon, color: color);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = AppFormatters.dateTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como lidas',
            onPressed: _markAllAsRead,
            color: AppColors.primary,
          ),
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
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
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
              final timeAgo = dateFormat.format(date);

              return Dismissible(
                key: Key(notification['id']),
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNotification(notification['id']);
                },
                child: Container(
                  color: isRead ? Colors.white : AppColors.primaryLight,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: _getIconForType(notification['type']),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notification['id']);
                      }
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
