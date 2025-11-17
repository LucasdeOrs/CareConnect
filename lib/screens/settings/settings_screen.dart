import 'package:careconnect_app/screens/auth/reset_password/update_password_screen.dart';
import 'package:careconnect_app/screens/settings/help_center_screen.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../auth/login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = false;

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza? Todos os seus dados, agendamentos e histórico serão apagados permanentemente. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sim, Excluir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userId = supabase.auth.currentUser!.id;
        await supabase
            .from('usuarios')
            .update({'status': 'Deletado'})
            .eq('id', userId);

        await supabase.auth.signOut();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sua conta foi desativada.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Preferências'),
          SwitchListTile(
            title: const Text('Notificações Push'),
            subtitle: const Text('Receber avisos sobre agendamentos e chat'),
            value: _notificationsEnabled,
            activeThumbColor: Colors.indigo,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              // TODO: Salvar preferência localmente ou no banco
            },
          ),
          SwitchListTile(
            title: const Text('Novidades por E-mail'),
            subtitle: const Text('Receber promoções e atualizações'),
            value: _emailUpdatesEnabled,
            activeThumbColor: Colors.indigo,
            onChanged: (val) {
              setState(() => _emailUpdatesEnabled = val);
            },
          ),
          const Divider(),
          _buildSectionHeader('Segurança'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar Senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateTo(const UpdatePasswordScreen()),
          ),
          const Divider(),
          _buildSectionHeader('Suporte e Sobre'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Central de Ajuda (FAQ)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateTo(const HelpCenterScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Termos de Uso e Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir WebView com termos...')),
              );
            },
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Excluir Minha Conta',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: _deleteAccount,
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.indigo.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
