import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/models/user_model.dart';
import 'package:careconnect_app/services/appointment_service.dart';
import 'package:careconnect_app/services/user_service.dart';
import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../core/widgets/cards/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  final VoidCallback onClose;
  const AppointmentsScreen({super.key, required this.onClose});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final UserService _userService = UserService();
  final AppointmentService _appointmentService = AppointmentService();

  late final Future<UserProfileData> _userDataFuture;
  UserType? _userType;
  UserModel? _selfUser;
  CaregiverProfile? _selfCaregiver;
  Map<String, dynamic>? _selfUserMap;
  Map<String, dynamic>? _selfCaregiverMap;

  String _selectedFilter = 'todos';
  final Map<String, String> _filterOptions = {
    'todos': 'Todos os Agendamentos',
    'pago': 'Aguardando Aceite',
    'confirmado': 'Confirmados',
    'concluido': 'Concluídos',
    'recusado': 'Recusados/Cancelados',
    'distantes': 'Histórico Completo (Antigos)',
  };

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<UserProfileData> _fetchUserData() async {
    try {
      final (userModel, caregiverProfile, userMap, caregiverMap) =
          await _userService.getFullUserProfileAndMaps();

      setState(() {
        _selfUser = userModel;
        _userType = userModel.userType;
        _selfCaregiver = caregiverProfile;
        _selfUserMap = userMap;
        _selfCaregiverMap = caregiverMap;
      });
      return (userModel, caregiverProfile, userMap, caregiverMap);
    } catch (e) {
      debugPrint("Erro em _fetchUserData: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      throw Exception('Falha ao carregar dados do usuário.');
    }
  }

  Future<void> _updateAppointmentStatus(String id, String newStatusKey) async {
    final status = AppointmentStatus.values.firstWhere(
      (e) => e.dbValue == newStatusKey,
      orElse: () => AppointmentStatus.cancelado,
    );

    try {
      await _appointmentService.updateStatus(id, status);

      String message = 'Agendamento atualizado!';
      if (status == AppointmentStatus.confirmado) {
        message = 'Agendamento aceito!';
      }
      if (status == AppointmentStatus.recusado) {
        message = 'Agendamento recusado.';
      }
      if (status == AppointmentStatus.concluido) {
        message = 'Serviço finalizado!';
      }
      if (status == AppointmentStatus.cancelado) {
        message = 'Agendamento cancelado.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
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

  void _refreshData() {
    setState(() {});
  }

  Widget _buildFilterDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
          items: _filterOptions.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _selectedFilter = newValue);
            }
          },
        ),
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
          title: const Text('Meus Agendamentos'),
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
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              if (!snapshot.hasData ||
                  _userType == null ||
                  _selfUserMap == null) {
                return const Center(
                  child: Text('Erro ao carregar dados do usuário.'),
                );
              }

              final userId = _selfUser!.id;
              final cuidadorId = _selfCaregiver?.id;

              return Column(
                children: [
                  _buildFilterDropdown(),
                  Expanded(
                    child: StreamBuilder<List<AppointmentDetails>>(
                      stream: _appointmentService.getAppointmentsStream(
                        userId: userId,
                        cuidadorId: cuidadorId,
                        userType: _userType!,
                        filterKey: _selectedFilter,
                        selfUserMap: _selfUserMap!,
                        selfCaregiverMap: _selfCaregiverMap,
                      ),
                      builder: (context, streamSnapshot) {
                        if (streamSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro no stream: ${streamSnapshot.error}',
                            ),
                          );
                        }
                        if (!streamSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final agendamentos = streamSnapshot.data!;

                        if (agendamentos.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Nenhum agendamento encontrado.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: agendamentos.length,
                          itemBuilder: (context, index) {
                            return AppointmentCard(
                              agendamento: agendamentos[index],
                              userType: _userType!.toDb,
                              onUpdateStatus: (newStatusKey) {
                                _updateAppointmentStatus(
                                  agendamentos[index].id,
                                  newStatusKey,
                                );
                              },
                              onReviewSubmitted: _refreshData,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
