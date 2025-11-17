// lib/screens/profile/widgets/advanced_block_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdvancedBlockDialog extends StatefulWidget {
  const AdvancedBlockDialog({super.key});

  @override
  State<AdvancedBlockDialog> createState() => _AdvancedBlockDialogState();
}

class _AdvancedBlockDialogState extends State<AdvancedBlockDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de estado do formulário
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _startDate;
  DateTime? _endDate;
  // Lista de booleanos para [Seg, Ter, Qua, Qui, Sex, Sab, Dom]
  final List<bool> _selectedWeekdays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  bool _isLoading = false;

  /// Constrói o seletor de dias da semana
  Widget _buildWeekdaySelector() {
    final weekdays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return ToggleButtons(
      isSelected: _selectedWeekdays,
      onPressed: (int index) {
        setState(() {
          _selectedWeekdays[index] = !_selectedWeekdays[index];
        });
      },
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
      children: List<Widget>.generate(7, (int index) {
        return Text(weekdays[index]);
      }),
    );
  }

  /// Mostra um DatePicker e atualiza o estado
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final firstDate = isStartDate
        ? DateTime.now()
        : (_startDate ?? DateTime.now());

    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 2),
      ), // 2 anos no futuro
    );

    if (newDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = newDate;
          // Se a data final for anterior à nova data inicial, reseta a data final
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = newDate;
        }
      });
    }
  }

  /// Mostra um TimePicker e atualiza o estado
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = isStartTime
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));

    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStartTime
          ? 'SELECIONE HORA DE INÍCIO'
          : 'SELECIONE HORA DE FIM',
    );

    if (newTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = newTime;
        } else {
          _endTime = newTime;
        }
      });
    }
  }

  /// Valida e submete o formulário
  void _submit() {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      // Validação 1: Pelo menos um dia da semana
      if (!_selectedWeekdays.any((day) => day)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione pelo menos um dia da semana.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validação 2: Horário de fim > horário de início
      final inicioDouble = _startTime!.hour + (_startTime!.minute / 60.0);
      final fimDouble = _endTime!.hour + (_endTime!.minute / 60.0);
      if (fimDouble <= inicioDouble) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A hora de fim deve ser depois da hora de início.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Retorna os dados para a tela anterior (MinhaAgendaScreen)
      Navigator.pop(context, {
        'startTime': _startTime,
        'endTime': _endTime,
        'startDate': _startDate,
        'endDate': _endDate,
        'weekdays': _selectedWeekdays,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formata as datas e horas para os botões
    final startDateText = _startDate == null
        ? 'Data Início'
        : DateFormat('dd/MM/yyyy').format(_startDate!);
    final endDateText = _endDate == null
        ? 'Data Fim'
        : DateFormat('dd/MM/yyyy').format(_endDate!);
    final startTimeText = _startTime == null
        ? 'Hora Início'
        : _startTime!.format(context);
    final endTimeText = _endTime == null
        ? 'Hora Fim'
        : _endTime!.format(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bloqueio Avançado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Seleção de Horário
            Text(
              '1. Selecione o horário a ser bloqueado:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(startTimeText),
                    onPressed: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_filled_outlined),
                    label: Text(endTimeText),
                    onPressed: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            // Validador "fantasma" para os horários
            FormField(
              validator: (_) {
                if (_startTime == null || _endTime == null) {
                  return 'Defina um horário de início e fim.';
                }
                return null;
              },
              builder: (state) => state.hasError
                  ? Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),
            Text(
              '2. Selecione os dias da semana:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Center(child: _buildWeekdaySelector()),
            const SizedBox(height: 24),

            Text(
              '3. Selecione o período de datas:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(startDateText),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(endDateText),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            // Validador "fantasma" para as datas
            FormField(
              validator: (_) {
                if (_startDate == null || _endDate == null) {
                  return 'Defina uma data de início e fim.';
                }
                return null;
              },
              builder: (state) => state.hasError
                  ? Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Salvar Bloqueio em Massa'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
