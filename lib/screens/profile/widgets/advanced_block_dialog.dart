import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:flutter/material.dart';

class AdvancedBlockDialog extends StatefulWidget {
  const AdvancedBlockDialog({super.key});

  @override
  State<AdvancedBlockDialog> createState() => _AdvancedBlockDialogState();
}

class _AdvancedBlockDialogState extends State<AdvancedBlockDialog> {
  final _formKey = GlobalKey<FormState>();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _startDate;
  DateTime? _endDate;

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
      color: AppColors.primary,
      selectedColor: Colors.white,
      fillColor: AppColors.primary,
      // ignore: deprecated_member_use
      borderColor: AppColors.primary.withOpacity(0.5),
      selectedBorderColor: AppColors.primary,
      children: List<Widget>.generate(7, (int index) {
        return Text(weekdays[index]);
      }),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = isStartDate
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final firstDate = isStartDate ? now : (_startDate ?? now);

    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
    );

    if (newDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = newDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = newDate;
        }
      });
    }
  }

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

  void _submit() {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      if (!_selectedWeekdays.any((day) => day)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione pelo menos um dia da semana.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final inicioDouble = _startTime!.hour + (_startTime!.minute / 60.0);
      final fimDouble = _endTime!.hour + (_endTime!.minute / 60.0);
      if (fimDouble <= inicioDouble) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A hora de fim deve ser depois da hora de início.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

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
    final startDateText = _startDate == null
        ? 'Data Início'
        : AppFormatters.date.format(_startDate!);
    final endDateText = _endDate == null
        ? 'Data Fim'
        : AppFormatters.date.format(_endDate!);
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
            Text(
              'Bloqueio Avançado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

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
                backgroundColor: AppColors.primary,
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
