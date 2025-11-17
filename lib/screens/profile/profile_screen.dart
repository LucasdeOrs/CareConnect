import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/auth/reset_password/update_password_screen.dart';
import 'package:careconnect_app/screens/profile/caregiver_screens/edit_professional_profile_screen.dart';
import 'package:careconnect_app/screens/profile/caregiver_screens/my_schedule_screen.dart';
import 'package:careconnect_app/screens/profile/caregiver_screens/manage_certificates_screen.dart';
import 'package:careconnect_app/screens/profile/caregiver_screens/my_receits_screen.dart';
import 'package:careconnect_app/screens/profile/familiar_screens/my_patients_screen.dart';
import 'package:careconnect_app/screens/profile/familiar_screens/payment_history_screen.dart';
import 'package:careconnect_app/screens/settings/help_center_screen.dart';
import 'package:careconnect_app/screens/settings/settings_screen.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/user_service.dart';
import 'package:flutter/material.dart';
import '../auth/login/login_screen.dart';
import 'edit_personal_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onClose;
  final Function(CaregiverProfile) onShowPublicProfile;

  const ProfileScreen({
    super.key,
    required this.onClose,
    required this.onShowPublicProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  late final Future<UserProfileData> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _userService.getFullUserProfileAndMaps();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Você tem certeza que deseja deslogar?'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Sim, Sair',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onClose,
            tooltip: 'Voltar para a Home',
          ),
          title: const Text('Meu Perfil'),
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: FutureBuilder<UserProfileData>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('Nenhum dado encontrado.'));
              }

              final (userModel, caregiverProfile, userDataMap, _) =
                  snapshot.data!;
              final userType = userModel.userType?.toDb ?? 'familiar';

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildProfileHeader(userDataMap),
                  const Divider(height: 1, thickness: 0.5),
                  if (userType == 'familiar')
                    ..._buildFamiliarMenu(context, userDataMap)
                  else
                    ..._buildCaregiverMenu(
                      context,
                      userDataMap,
                      caregiverProfile,
                    ),
                  ..._buildCommonMenu(context),
                  const Divider(height: 1, thickness: 0.5),
                  ..._buildLogout(context),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final String nome = userData['nome'] ?? 'Usuário';
    final String email = userData['email'] ?? 'Sem e-mail';
    final String? avatarUrl = userData['avatar_url'];

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (avatarUrl != null)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null)
                ? const Icon(Icons.person, size: 35, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  List<Widget> _buildFamiliarMenu(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    return [
      _buildSectionTitle('Minha Conta'),
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text('Editar Perfil Pessoal'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _navigateTo(EditPersonalProfileScreen(userData: userData));
        },
      ),
      ListTile(
        leading: const Icon(Icons.people_alt_outlined),
        title: const Text('Meus Pacientes'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateTo(const MyPatientsScreen()),
      ),
      ListTile(
        leading: const Icon(Icons.credit_card_outlined),
        title: const Text('Formas de Pagamento'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showComingSoon(),
      ),
      ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: const Text('Histórico de Pagamentos'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _navigateTo(const PaymentHistoryScreen());
        },
      ),
    ];
  }

  List<Widget> _buildCaregiverMenu(
    BuildContext context,
    Map<String, dynamic> userData,
    CaregiverProfile? caregiverProfile,
  ) {
    return [
      _buildSectionTitle('Meu Negócio'),
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text('Editar Perfil Pessoal'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _navigateTo(EditPersonalProfileScreen(userData: userData));
        },
      ),
      ListTile(
        leading: const Icon(Icons.work_outline),
        title: const Text('Editar Perfil Profissional'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (caregiverProfile != null) {
            _navigateTo(
              EditProfessionalProfileScreen(caregiverProfile: caregiverProfile),
            );
          } else {
            _showError("Não foi possível carregar seu perfil profissional.");
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Minha Agenda'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (caregiverProfile != null) {
            _navigateTo(MinhaAgendaScreen(caregiverProfile: caregiverProfile));
          } else {
            _showError("Não foi possível carregar seu perfil.");
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.attach_money_outlined),
        title: const Text('Meus Recebimentos'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (caregiverProfile != null) {
            _navigateTo(
              MeusRecebimentosScreen(caregiverProfile: caregiverProfile),
            );
          } else {
            _showError("Não foi possível carregar seu perfil financeiro.");
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.badge_outlined),
        title: const Text('Gerenciar Certificados'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (caregiverProfile != null) {
            _navigateTo(
              ManageCertificatesScreen(caregiverProfile: caregiverProfile),
            );
          } else {
            _showError("Não foi possível carregar seu perfil.");
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: const Text('Ver meu perfil público'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (caregiverProfile != null) {
            widget.onShowPublicProfile(caregiverProfile);
          } else {
            _showError("Não foi possível carregar seu perfil público.");
          }
        },
      ),
    ];
  }

  List<Widget> _buildCommonMenu(BuildContext context) {
    return [
      _buildSectionTitle('Aplicativo'),
      ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Segurança (Alterar Senha)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateTo(const UpdatePasswordScreen()),
      ),
      ListTile(
        leading: const Icon(Icons.notifications_none_outlined),
        title: const Text('Notificações'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateTo(const SettingsScreen()),
      ),
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Central de Ajuda (FAQ)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateTo(const HelpCenterScreen()),
      ),
    ];
  }

  List<Widget> _buildLogout(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: TextButton.icon(
          icon: const Icon(Icons.logout, color: AppColors.error), // Cor
          label: const Text(
            'Sair da Conta',
            style: TextStyle(color: AppColors.error, fontSize: 16), // Cor
          ),
          onPressed: _showLogoutDialog,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.transparent),
            ),
          ),
        ),
      ),
    ];
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showComingSoon() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error), // Cor
    );
  }
}
