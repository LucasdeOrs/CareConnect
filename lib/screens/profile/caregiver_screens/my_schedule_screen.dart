import 'dart:async';
import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/profile/widgets/advanced_block_dialog.dart';
import 'package:careconnect_app/services/caregiver_service.dart';
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
  final CaregiverService _caregiverService = CaregiverService();

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

    _bloqueiosStream = _caregiverService.getBlocksStream(_cuidadorId);

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
      final listaDeBloqueios = (await _caregiverService
          .getBlocksStream(_cuidadorId)
          .first);
      _updateEventsMap(listaDeBloqueios);
    } catch (e) {
      _showError("Erro ao recarregar dados: $e");
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _events[dayUtc] ?? [];
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    return time.hour + (time.minute / 60.0);
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

    try {
      final alreadyBlocked = await _caregiverService.checkExistingBlockConflict(
        cuidadorId: _cuidadorId,
        dateStr: dataFormatada,
        newStart: inicioDouble,
        newEnd: fimDouble,
      );
      if (alreadyBlocked) {
        _showError('Este horário já está bloqueado.');
        return;
      }

      final conflictingIds = await _caregiverService
          .checkAndCancelConflictingAppointments(
            cuidadorId: _cuidadorId,
            dateStrings: [dataFormatada],
            newStart: inicioDouble,
            newEnd: fimDouble,
          );

      if (conflictingIds.isNotEmpty) {
        final count = conflictingIds.length;
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
              'Você tinha $count agendamento(s) neste horário. Eles foram cancelado(s) e o(s) familiar(es) reembolsado(s).',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (confirma != true) return;
      }

      await _caregiverService.addBlocks([
        {
          'cuidador_id': _cuidadorId,
          'data_bloqueio': dataFormatada,
          'hora_inicio': horaInicioStr,
          'hora_fim': horaFimStr,
        },
      ]);

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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
        await _caregiverService.deleteBlock(bloqueioId);
        await _refetchData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bloqueio removido com sucesso."),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        _showError('Erro ao remover bloqueio: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAdvancedBlockDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AdvancedBlockDialog(),
    );

    if (result == null) return;

    await _executeAdvancedBlock(result);
  }

  Future<void> _executeAdvancedBlock(Map<String, dynamic> blockData) async {
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

    if (mounted) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final conflictingIds = await _caregiverService
          .checkAndCancelConflictingAppointments(
            cuidadorId: _cuidadorId,
            dateStrings: dateStrings,
            newStart: newStart,
            newEnd: newEnd,
          );

      if (conflictingIds.isNotEmpty) {
        final count = conflictingIds.length;
        if (mounted) Navigator.pop(context);

        await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              count == 1 ? 'Agendamento Cancelado' : 'Agendamentos Cancelados',
            ),
            content: Text(
              'Encontramos $count agendamento(s) que conflitaram. Eles foram automaticamente cancelados e o(s) familiar(es) reembolsado(s).',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        }
      }

      List<Map<String, dynamic>> newBlocksToInsert = [];
      for (var date in datesToBlock) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final alreadyBlocked = await _caregiverService
            .checkExistingBlockConflict(
              cuidadorId: _cuidadorId,
              dateStr: dateStr,
              newStart: newStart,
              newEnd: newEnd,
            );

        if (!alreadyBlocked) {
          newBlocksToInsert.add({
            'cuidador_id': _cuidadorId,
            'data_bloqueio': dateStr,
            'hora_inicio': horaInicioStr,
            'hora_fim': horaFimStr,
          });
        }
      }

      if (newBlocksToInsert.isNotEmpty) {
        await _caregiverService.addBlocks(newBlocksToInsert);
      }

      if (mounted) Navigator.pop(context);
      await _refetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newBlocksToInsert.length} bloqueios criados com sucesso!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
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
            _showAdvancedBlockDialog();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'single',
            child: ListTile(
              leading: const Icon(Icons.block, color: AppColors.primary),
              title: const Text('Bloquear um horário'),
            ),
          ),
          PopupMenuItem<String>(
            value: 'advanced',
            child: ListTile(
              leading: const Icon(Icons.date_range, color: AppColors.primary),
              title: const Text('Bloqueio avançado'),
            ),
          ),
        ],
        child: FloatingActionButton(
          onPressed: null,
          backgroundColor: AppColors.primary,
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
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: (eventosDoDia.isEmpty)
                ? Center(
                    child: Text(
                      'Nenhum bloqueio para\n${AppFormatters.date.format(_selectedDay ?? _focusedDay)}',
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
                          leading: const Icon(
                            Icons.block,
                            color: AppColors.error,
                          ),
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
