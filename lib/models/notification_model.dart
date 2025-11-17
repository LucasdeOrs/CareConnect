import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      type: map['type'] ?? 'sistema',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  IconData get icon {
    switch (type) {
      case 'agendamento':
        return Icons.calendar_month;
      case 'chat':
        return Icons.chat_bubble;
      case 'financeiro':
        return Icons.attach_money;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'agendamento':
        return Colors.blue;
      case 'chat':
        return Colors.indigo;
      case 'financeiro':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
