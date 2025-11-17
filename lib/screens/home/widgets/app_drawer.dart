import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/models/user_model.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/chat_service.dart';
import 'package:careconnect_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../chat/inbox_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../settings/settings_screen.dart';
import '../../auth/login/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(String route) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  static final AuthService _authService = AuthService();
  static final UserService _userService = UserService();

  Future<void> _signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;
    if (user == null) return const Drawer();

    return Drawer(
      child: StreamBuilder<UserModel?>(
        stream: _userService.getUserProfileStream(user.id),
        builder: (context, snapshot) {
          String nome = 'Carregando...';
          String? avatarUrl;

          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!;
            nome = userData.nome;
            avatarUrl = userData.avatarUrl;
          } else if (user.userMetadata != null) {
            nome = user.userMetadata?['nome'] ?? 'Usuário';
            avatarUrl = user.userMetadata?['avatar_url'];
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, bottom: 24),
                color: AppColors.primaryLight,
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

                    StreamBuilder<int>(
                      stream: ChatService.getUnreadCountStream(user.id),
                      builder: (context, msgSnapshot) {
                        final unreadCount = msgSnapshot.data ?? 0;

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
                                    color: AppColors.error,
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
