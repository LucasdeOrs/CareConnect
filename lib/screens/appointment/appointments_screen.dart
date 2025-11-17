// lib/screens/appointments/appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/appointment_model.dart';
import 'widgets/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  // 1. ADICIONADO: Callback para fechar
  final VoidCallback onClose;

  // 2. MODIFICADO: Construtor
  const AppointmentsScreen({super.key, required this.onClose});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late final Future<Map<String, dynamic>> _userDataFuture;

  String? _userType;
  Map<String, dynamic>? _selfUserMap;
  Map<String, dynamic>? _selfCaregiverMap;
  String? _cuidadorId;

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

  Future<Map<String, dynamic>> _fetchUserData() async {
    // ... (código original, sem alteração)
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final userProfile = await supabase
        .from('usuarios')
        .select('*')
        .eq('id', user.id)
        .single();

    _selfUserMap = userProfile;
    _userType = userProfile['tipo'] as String?;

    if (_userType == 'cuidador') {
      final caregiverProfile = await supabase
          .from('cuidadores')
          .select('*')
          .eq('usuario_id', user.id)
          .single();

      _selfCaregiverMap = caregiverProfile;
      _cuidadorId = caregiverProfile['id'] as String?;
    }

    return userProfile;
  }

  Future<void> _updateAppointmentStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('agendamentos')
          .update({'status': newStatus})
          .eq('id', id)
          .select();

      String message = 'Agendamento atualizado!';
      if (newStatus == 'confirmado') message = 'Agendamento aceito!';
      if (newStatus == 'recusado') message = 'Agendamento recusado.';
      if (newStatus == 'concluido') message = 'Serviço finalizado com sucesso!';
      if (newStatus == 'cancelado') {
        message = 'Agendamento cancelado com sucesso.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
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
          icon: const Icon(Icons.filter_list_rounded, color: Colors.indigo),
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
          backgroundColor: Colors.transparent,
          elevation: 1,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              if (_userType == null || _selfUserMap == null) {
                return const Center(
                  child: Text('Erro ao carregar dados do usuário.'),
                );
              }

              // A Column original do 'body'
              return Column(
                children: [
                  _buildFilterDropdown(),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: () {
                        // ... (código original do stream, sem alteração)
                        final userId = supabase.auth.currentUser!.id;
                        final today = DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.now());
                        dynamic queryStream = supabase
                            .from('agendamentos')
                            .stream(primaryKey: ['id']);
                        if (_userType == 'cuidador') {
                          if (_cuidadorId == null) {
                            return Stream<List<Map<String, dynamic>>>.value([]);
                          }
                          queryStream = queryStream.eq(
                            'cuidador_id',
                            _cuidadorId!,
                          );
                        } else {
                          queryStream = queryStream.eq('familiar_id', userId);
                        }
                        if (_selectedFilter == 'pago') {
                          queryStream = queryStream.eq('status', 'pago');
                        } else if (_selectedFilter == 'confirmado') {
                          queryStream = queryStream.eq('status', 'confirmado');
                        } else if (_selectedFilter == 'concluido') {
                          queryStream = queryStream.eq('status', 'concluido');
                        } else if (_selectedFilter == 'recusado') {
                          queryStream = queryStream.inFilter('status', [
                            'recusado',
                            'cancelado',
                          ]);
                        } else if (_selectedFilter == 'distantes') {
                          queryStream = queryStream.lt(
                            'data_agendamento',
                            today,
                          );
                        }
                        if (_selectedFilter == 'todos') {
                          queryStream = queryStream.order(
                            'data_agendamento',
                            ascending: false,
                          );
                        } else if (_selectedFilter == 'distantes') {
                          queryStream = queryStream.order(
                            'data_agendamento',
                            ascending: true,
                          );
                        } else {
                          queryStream = queryStream.order(
                            'data_agendamento',
                            ascending: true,
                          );
                        }
                        final rawStream = (queryStream as Stream<List<dynamic>>)
                            .map((list) => list.cast<Map<String, dynamic>>());
                        return rawStream.asyncMap((rawDataList) async {
                          final enrichedList = <Map<String, dynamic>>[];
                          for (var rawAgendamento in rawDataList) {
                            try {
                              if (rawAgendamento['paciente_id'] != null) {
                                final pacienteData = await supabase
                                    .from('pacientes')
                                    .select()
                                    .eq('id', rawAgendamento['paciente_id'])
                                    .single();
                                rawAgendamento['pacientes'] = pacienteData;
                              }

                              if (_userType == 'cuidador') {
                                final familiarId =
                                    rawAgendamento['familiar_id'];
                                final familiarData = await supabase
                                    .from('usuarios')
                                    .select('*')
                                    .eq('id', familiarId)
                                    .single();
                                rawAgendamento['familiar'] = familiarData;
                              } else {
                                final cuidadorId =
                                    rawAgendamento['cuidador_id'];
                                final cuidadorData = await supabase
                                    .from('cuidadores')
                                    .select('*, usuarios(*)')
                                    .eq('id', cuidadorId)
                                    .single();
                                rawAgendamento['cuidador'] = cuidadorData;
                              }
                              enrichedList.add(rawAgendamento);
                            } catch (e) {
                              debugPrint(
                                'Erro ao enriquecer agendamento ${rawAgendamento['id']}: $e',
                              );
                            }
                          }
                          return enrichedList;
                        });
                      }(),
                      builder: (context, streamSnapshot) {
                        // ... (código original do builder, sem alteração)
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
                        final fullData = streamSnapshot.data!;
                        if (fullData.isEmpty) {
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
                        final agendamentos = fullData.map((map) {
                          return AppointmentDetails.fromMap(
                            map,
                            userType: _userType!,
                            selfUserMap: _selfUserMap!,
                            selfCaregiverMap: _selfCaregiverMap,
                          );
                        }).toList();
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: agendamentos.length,
                          itemBuilder: (context, index) {
                            return AppointmentCard(
                              agendamento: agendamentos[index],
                              userType: _userType!,
                              onUpdateStatus: (newStatus) {
                                _updateAppointmentStatus(
                                  agendamentos[index].id,
                                  newStatus,
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
