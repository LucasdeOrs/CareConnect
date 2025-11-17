import 'package:careconnect_app/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final String _currentUserId = supabase.auth.currentUser!.id;
  late Future<List<Map<String, dynamic>>> _conversasFuture;

  @override
  void initState() {
    super.initState();
    _conversasFuture = _fetchConversations();
  }

  Future<List<Map<String, dynamic>>> _fetchConversations() async {
    final data = await supabase
        .from('conversas')
        .select(
          '*, familiar:familiar_id(id, nome, avatar_url), cuidador:cuidador_id(id, usuarios(id, nome, avatar_url))',
        )
        .order('updated_at', ascending: false);

    final List<Map<String, dynamic>> conversas =
        List<Map<String, dynamic>>.from(data);

    for (var chat in conversas) {
      final count = await supabase
          .from('mensagens')
          .select(
            'id',
          )
          .eq('conversa_id', chat['id'])
          .neq('sender_id', _currentUserId)
          .eq('is_read', false)
          .count(CountOption.exact);
      chat['unread_count'] = count.count;
    }

    return conversas;
  }

  void _refreshInbox() {
    setState(() {
      _conversasFuture = _fetchConversations();
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final conversas = snapshot.data ?? [];

          if (conversas.isEmpty) {
            return Center(
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
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshInbox();
            },
            child: ListView.builder(
              itemCount: conversas.length,
              itemBuilder: (context, index) {
                final chat = conversas[index];
                final familiarData = chat['familiar'];
                final cuidadorDataWrapper = chat['cuidador'];
                final cuidadorUserData = cuidadorDataWrapper['usuarios'];

                String otherName = 'Usuário';
                String? otherAvatar;

                if (_currentUserId == familiarData['id']) {
                  otherName = cuidadorUserData['nome'] ?? 'Cuidador';
                  otherAvatar = cuidadorUserData['avatar_url'];
                } else {
                  otherName = familiarData['nome'] ?? 'Familiar';
                  otherAvatar = familiarData['avatar_url'];
                }

                final lastMessage =
                    chat['last_message'] ?? 'Inicie a conversa...';
                final date = DateTime.parse(chat['updated_at']).toLocal();
                final dateString = DateFormat('dd/MM HH:mm').format(date);

                final int unreadCount = chat['unread_count'] ?? 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: otherAvatar != null
                        ? NetworkImage(otherAvatar)
                        : null,
                    child: otherAvatar == null
                        ? const Icon(Icons.person)
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
                      color:
                          unreadCount >
                              0 
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
                          color: unreadCount > 0 ? Colors.indigo : Colors.grey,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
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
                    _refreshInbox();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
