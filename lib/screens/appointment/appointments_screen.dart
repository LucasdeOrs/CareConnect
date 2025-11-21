import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/core/widgets/cards/appointment_card.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/models/user_model.dart';
import 'package:careconnect_app/services/appointment_service.dart';
import 'package:careconnect_app/services/user_service.dart';
import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

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
    'todos': 'Todos',
    'pendente_aceite': 'Aguardando Aceite',
    'aguardando_pagamento': 'Aguardando Pagamento',
    'confirmado': 'Confirmados',
    'concluido': 'Concluídos',
    'recusado': 'Cancelados/Recusados',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      throw Exception('Falha ao carregar dados.');
    }
  }

  Future<void> _updateAppointmentStatus(String id, String newStatusKey) async {
    final status = AppointmentStatus.values.firstWhere(
      (e) => e.dbValue == newStatusKey,
      orElse: () => AppointmentStatus.cancelado,
    );

    try {
      await _appointmentService.updateStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atualizado!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _refreshData() {
    setState(() {});
  }

  Widget _buildFilterList() {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filterOptions.entries.map((entry) {
          final isSelected = _selectedFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() => _selectedFilter = entry.key);
                }
              },
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<UserProfileData>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData ||
                _userType == null ||
                _selfUserMap == null) {
              return const Center(child: Text('Erro ao carregar dados.'));
            }

            final userId = _selfUser!.id;
            final cuidadorId = _selfCaregiver?.id;

            return Column(
              children: [
                _buildFilterList(),
                const Divider(height: 1),
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
                      if (streamSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final agendamentos = streamSnapshot.data ?? [];

                      if (agendamentos.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum agendamento encontrado.',
                            style: TextStyle(color: Colors.grey),
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
    );
  }
}
