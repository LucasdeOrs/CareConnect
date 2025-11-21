import 'dart:async';
import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  late final String _currentUserId;

  List<Map<String, dynamic>> _conversas = [];
  bool _isLoading = true;

  StreamSubscription? _inboxSubscription;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user == null) {
      _currentUserId = 'INVALID';
      _isLoading = false;
    } else {
      _currentUserId = user.id;
      _loadConversations(showLoading: true);
      _setupRealtimeListener();
    }
  }

  @override
  void dispose() {
    _inboxSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool showLoading = false}) async {
    if (_currentUserId == 'INVALID') return;

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final data = await _chatService.fetchConversations(_currentUserId);
      if (mounted) {
        setState(() {
          _conversas = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Erro ao atualizar inbox: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealtimeListener() {
    if (_currentUserId == 'INVALID') return;
    _inboxSubscription = Supabase.instance.client
        .from('conversas')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (mounted) {
            _loadConversations(showLoading: false);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa iniciada.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadConversations(showLoading: false);
              },
              child: ListView.builder(
                itemCount: _conversas.length,
                itemBuilder: (context, index) {
                  final chat = _conversas[index];
                  final familiarData = chat['familiar'];
                  final cuidadorDataWrapper = chat['cuidador'];
                  final cuidadorUserData = cuidadorDataWrapper != null
                      ? cuidadorDataWrapper['usuarios']
                      : null;

                  String otherName = 'Usuário';
                  String? otherAvatar;

                  if (_currentUserId == familiarData['id']) {
                    otherName = cuidadorUserData?['nome'] ?? 'Cuidador';
                    otherAvatar = cuidadorUserData?['avatar_url'];
                  } else {
                    otherName = familiarData['nome'] ?? 'Familiar';
                    otherAvatar = familiarData['avatar_url'];
                  }

                  final lastMessage =
                      chat['last_message'] ?? 'Inicie a conversa...';
                  final date = DateTime.parse(chat['updated_at']).toLocal();
                  final dateString = AppFormatters.dateTime.format(date);
                  final int unreadCount = chat['unread_count'] ?? 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          (otherAvatar != null && otherAvatar.isNotEmpty)
                          ? NetworkImage(otherAvatar)
                          : null,
                      child: (otherAvatar == null || otherAvatar.isEmpty)
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? Colors.black87
                            : Colors.grey.shade600,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w900
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateString,
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversaId: chat['id'],
                            otherUserName: otherName,
                            otherUserAvatar: otherAvatar,
                            currentUserId: _currentUserId,
                          ),
                        ),
                      );
                      _loadConversations(showLoading: false);
                    },
                  );
                },
              ),
            ),
    );
  }
}
