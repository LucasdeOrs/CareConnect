import 'package:careconnect_app/screens/chat/inbox_screen.dart';
import 'package:careconnect_app/screens/notifications/notifications_screen.dart';
import 'package:careconnect_app/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../auth/login/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(String route) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  Future<void> _signOut(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: ${e.toString()}')),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saída'),
        backgroundColor: Colors.white,
        content: const Text('Você tem certeza que deseja deslogar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut(context);
            },
            child: const Text('Sim, Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) return const Drawer();

    return Drawer(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('usuarios')
            .stream(primaryKey: ['id'])
            .eq('id', user.id),
        builder: (context, snapshot) {
          String nome = 'Usuário';
          String? avatarUrl;

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final userData = snapshot.data!.first;
            nome = userData['nome'] ?? 'Usuário';
            avatarUrl = userData['avatar_url'];
          } else {
            final metadata = user.userMetadata;
            nome = metadata?['nome'] ?? 'Carregando...';
            avatarUrl = metadata?['avatar_url'];
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, bottom: 24),
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey.shade600,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Buscar Cuidador'),
                      onTap: () {
                        onNavigate('home');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Agendamentos'),
                      onTap: () {
                        onNavigate('appointments');
                      },
                    ),

                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('mensagens')
                          .stream(primaryKey: ['id'])
                          .eq('is_read', false),
                      builder: (context, msgSnapshot) {
                        int unreadCount = 0;
                        if (msgSnapshot.hasData) {
                          unreadCount = msgSnapshot.data!
                              .where((msg) => msg['sender_id'] != user.id)
                              .length;
                        }
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Row(
                            children: [
                              const Text('Mensagens'),
                              if (unreadCount > 0) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InboxScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Perfil'),
                      onTap: () {
                        onNavigate('profile');
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Sair',
                      onPressed: () => _showLogoutDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      tooltip: 'Notificações',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Configurações',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
