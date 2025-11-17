// lib/screens/profile/minha_agenda_screen.dart

import 'dart:async';
import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/profile/widgets/advanced_block_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MinhaAgendaScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;
  const MinhaAgendaScreen({super.key, required this.caregiverProfile});

  @override
  State<MinhaAgendaScreen> createState() => _MinhaAgendaScreenState();
}

class _MinhaAgendaScreenState extends State<MinhaAgendaScreen> {
  late final String _cuidadorId;
  late final Stream<List<Map<String, dynamic>>> _bloqueiosStream;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<dynamic>> _events = {};
  late final StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _cuidadorId = widget.caregiverProfile.id;
    _selectedDay = _focusedDay;

    _bloqueiosStream = supabase
        .from('bloqueios_agenda')
        .stream(primaryKey: ['id'])
        .eq('cuidador_id', _cuidadorId)
        .order('hora_inicio', ascending: true);

    _streamSubscription = _bloqueiosStream.listen((listaDeBloqueios) {
      _updateEventsMap(listaDeBloqueios);
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  void _updateEventsMap(List<Map<String, dynamic>> bloqueios) {
    Map<DateTime, List<dynamic>> newEvents = {};
    for (var bloqueio in bloqueios) {
      final data = DateTime.parse(bloqueio['data_bloqueio']);
      final dataUtc = DateTime.utc(data.year, data.month, data.day);

      if (newEvents[dataUtc] == null) {
        newEvents[dataUtc] = [];
      }
      newEvents[dataUtc]!.add(bloqueio);
    }
    setState(() {
      _events = newEvents;
    });
  }

  Future<void> _refetchData() async {
    try {
      final listaDeBloqueios = await supabase
          .from('bloqueios_agenda')
          .select()
          .eq('cuidador_id', _cuidadorId)
          .order('hora_inicio', ascending: true);

      _updateEventsMap(listaDeBloqueios);
    } catch (e) {
      debugPrint("Erro ao re-buscar dados: $e");
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _events[dayUtc] ?? [];
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    return time.hour + (time.minute / 60.0);
  }

  double _timeStringToDouble(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour + (minute / 60.0);
    } catch (e) {
      debugPrint("Erro ao converter time string: $e");
      return 0.0;
    }
  }

  Future<void> _addNovoBloqueio() async {
    TimeOfDay? inicio;
    TimeOfDay? fim;

    inicio = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Selecione a Hora de Início',
    );
    if (inicio == null) return;

    fim = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay(hour: inicio.hour + 1, minute: inicio.minute),
      helpText: 'Selecione a Hora de Fim',
    );
    if (fim == null) return;

    final inicioDouble = _timeOfDayToDouble(inicio);
    final fimDouble = _timeOfDayToDouble(fim);

    if (fimDouble <= inicioDouble) {
      _showError('A hora de fim deve ser depois da hora de início.');
      return;
    }

    final dataSelecionada = _selectedDay ?? DateTime.now();
    final dataFormatada = DateFormat('yyyy-MM-dd').format(dataSelecionada);
    final horaInicioStr =
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
    final horaFimStr =
        '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';

    final eventosDoDia = _getEventsForDay(dataSelecionada);
    for (var evento in eventosDoDia) {
      final existingStart = _timeStringToDouble(evento['hora_inicio']);
      final existingEnd = _timeStringToDouble(evento['hora_fim']);

      if (inicioDouble < existingEnd && fimDouble > existingStart) {
        _showError('Este horário conflita com um bloqueio já existente.');
        return;
      }
    }

    try {
      final agendamentos = await supabase
          .from('agendamentos')
          .select('id, hora_inicio, hora_fim')
          .eq('cuidador_id', _cuidadorId)
          .eq('data_agendamento', dataFormatada)
          .inFilter('status', ['pago', 'confirmado']);

      List<String> conflictingAppointmentIds = [];
      for (var agendamento in agendamentos) {
        final existingStart = _timeStringToDouble(agendamento['hora_inicio']);
        final existingEnd = _timeStringToDouble(agendamento['hora_fim']);

        if (inicioDouble < existingEnd && fimDouble > existingStart) {
          conflictingAppointmentIds.add(agendamento['id'] as String);
        }
      }

      if (conflictingAppointmentIds.isNotEmpty) {
        final count = conflictingAppointmentIds.length;
        final confirma = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              count == 1
                  ? 'Agendamento em Conflito'
                  : 'Agendamentos em Conflito',
            ),
            content: Text(
              'Você tem $count agendamento(s) neste horário. Se continuar, ele(s) será(ão) cancelado(s) e o(s) familiar(es) reembolsado(s). Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Sim, Cancelar Agendamento(s)',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirma != true) {
          return;
        }

        await supabase
            .from('agendamentos')
            .update({'status': 'cancelado'})
            .inFilter('id', conflictingAppointmentIds);
      }
    } catch (e) {
      _showError('Erro ao verificar conflitos: $e');
      return;
    }

    try {
      await supabase.from('bloqueios_agenda').insert({
        'cuidador_id': _cuidadorId,
        'data_bloqueio': dataFormatada,
        'hora_inicio': horaInicioStr,
        'hora_fim': horaFimStr,
      });

      await _refetchData();
    } catch (e) {
      _showError('Erro ao salvar bloqueio: $e');
    }
  }

  Future<void> _deleteBloqueio(String bloqueioId) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Bloqueio'),
        content: const Text('Tem certeza que deseja remover este bloqueio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sim, Remover',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirma == true) {
      try {
        await supabase.from('bloqueios_agenda').delete().eq('id', bloqueioId);
        await _refetchData();
      } catch (e) {
        _showError('Erro ao remover bloqueio: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showAdvancedBlockDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true, // Permite que o modal cresça
      builder: (context) => const AdvancedBlockDialog(),
    );

    if (result == null) return;

    await _executeAdvancedBlock(result);
  }

  Future<void> _executeAdvancedBlock(Map<String, dynamic> blockData) async {
    // Extrai os dados do resultado do dialog
    final TimeOfDay startTime = blockData['startTime'];
    final TimeOfDay endTime = blockData['endTime'];
    final DateTime startDate = blockData['startDate'];
    final DateTime endDate = blockData['endDate'];
    final List<bool> weekdays = blockData['weekdays'];

    final newStart = _timeOfDayToDouble(startTime);
    final newEnd = _timeOfDayToDouble(endTime);
    final horaInicioStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final horaFimStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    List<DateTime> datesToBlock = [];
    for (
      var d = startDate;
      d.isBefore(endDate.add(const Duration(days: 1)));
      d = d.add(const Duration(days: 1))
    ) {
      if (weekdays[d.weekday - 1]) {
        datesToBlock.add(d);
      }
    }

    if (datesToBlock.isEmpty) {
      _showError('Nenhum dia correspondente encontrado no período.');
      return;
    }

    final dateStrings = datesToBlock
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList();

    // Mostra um spinner
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 2. Verificar conflitos de AGENDAMENTO
      final agendamentos = await supabase
          .from('agendamentos')
          .select('id, hora_inicio, hora_fim')
          .eq('cuidador_id', _cuidadorId)
          .inFilter('data_agendamento', dateStrings)
          .inFilter('status', ['pago', 'confirmado']);

      List<String> conflictingAppointmentIds = [];
      for (var agendamento in agendamentos) {
        final existingStart = _timeStringToDouble(agendamento['hora_inicio']);
        final existingEnd = _timeStringToDouble(agendamento['hora_fim']);
        if (newStart < existingEnd && newEnd > existingStart) {
          conflictingAppointmentIds.add(agendamento['id'] as String);
        }
      }

      // 3. Confirmar cancelamento de agendamentos
      if (conflictingAppointmentIds.isNotEmpty) {
        final count = conflictingAppointmentIds.length;
        final confirma = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              count == 1
                  ? 'Agendamento em Conflito'
                  : 'Agendamentos em Conflito',
            ),
            content: Text(
              'Encontramos $count agendamento(s) que conflitam com este bloqueio. Se continuar, eles serão cancelados. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Sim, Cancelar Agendamento(s)',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirma != true) {
          // Tira o spinner
          if (mounted) Navigator.pop(context);
          return;
        }

        // Cancela os agendamentos
        await supabase
            .from('agendamentos')
            .update({'status': 'cancelado'})
            .inFilter('id', conflictingAppointmentIds);
      }

      // 4. Verificar conflitos de BLOQUEIO (para não duplicar)
      final bloqueios = await supabase
          .from('bloqueios_agenda')
          .select('data_bloqueio, hora_inicio, hora_fim')
          .eq('cuidador_id', _cuidadorId)
          .inFilter('data_bloqueio', dateStrings);

      Set<String> conflictingBlockDates = {};
      for (var bloqueio in bloqueios) {
        final existingStart = _timeStringToDouble(bloqueio['hora_inicio']);
        final existingEnd = _timeStringToDouble(bloqueio['hora_fim']);
        if (newStart < existingEnd && newEnd > existingStart) {
          conflictingBlockDates.add(bloqueio['data_bloqueio'] as String);
        }
      }

      // 5. Preparar o INSERT em massa
      List<Map<String, dynamic>> newBlocksToInsert = [];
      for (var date in datesToBlock) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        // Só insere se NÃO houver conflito de bloqueio
        if (!conflictingBlockDates.contains(dateStr)) {
          newBlocksToInsert.add({
            'cuidador_id': _cuidadorId,
            'data_bloqueio': dateStr,
            'hora_inicio': horaInicioStr,
            'hora_fim': horaFimStr,
          });
        }
      }

      // 6. Executar o INSERT
      if (newBlocksToInsert.isNotEmpty) {
        await supabase.from('bloqueios_agenda').insert(newBlocksToInsert);
      }

      // 7. Fechar o spinner e recarregar os dados
      if (mounted) Navigator.pop(context);
      await _refetchData();

      // Feedback final
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newBlocksToInsert.length} bloqueios criados com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Fecha o spinner em caso de erro
      if (mounted) Navigator.pop(context);
      _showError('Erro ao processar bloqueio em massa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventosDoDia = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'single') {
            _addNovoBloqueio();
          } else if (value == 'advanced') {
            // 4. CHAMA A FUNÇÃO ATUALIZADA
            _showAdvancedBlockDialog();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'single',
            child: ListTile(
              leading: Icon(Icons.block),
              title: Text('Bloquear um horário'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'advanced',
            child: ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Bloqueio avançado'),
            ),
          ),
        ],
        child: FloatingActionButton(
          onPressed: null,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          tooltip: 'Adicionar Bloqueio',
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar(
              // ... (código do TableCalendar não muda)
              locale: 'pt_BR',
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: (eventosDoDia.isEmpty)
                ? Center(
                    child: Text(
                      'Nenhum bloqueio para\n${DateFormat('dd/MM/yyyy').format(_selectedDay ?? _focusedDay)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: eventosDoDia.length,
                    itemBuilder: (context, index) {
                      final evento = eventosDoDia[index];
                      final inicio = TimeOfDay.fromDateTime(
                        DateFormat('HH:mm:ss').parse(evento['hora_inicio']),
                      );
                      final fim = TimeOfDay.fromDateTime(
                        DateFormat('HH:mm:ss').parse(evento['hora_fim']),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.block, color: Colors.red),
                          title: Text(
                            'Bloqueado: ${inicio.format(context)} às ${fim.format(context)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () => _deleteBloqueio(evento['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
