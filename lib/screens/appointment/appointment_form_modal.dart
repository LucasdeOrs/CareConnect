import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/screens/profile/familiar_screens/my_patients_screen.dart';
import 'package:careconnect_app/services/appointment_service.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/enums/status_enums.dart';
import '../../models/caregiver_profile.dart';

class AppointmentFormModal extends StatefulWidget {
  final CaregiverProfile caregiver;

  const AppointmentFormModal({super.key, required this.caregiver});

  @override
  State<AppointmentFormModal> createState() => _AppointmentFormModalState();
}

class _AppointmentFormModalState extends State<AppointmentFormModal> {
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();
  final AppointmentService _appointmentService = AppointmentService();

  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  bool _isRecurrent = false;
  DateTime? _recurrentStartDate;
  DateTime? _recurrentEndDate;
  final Set<int> _selectedDays = {};

  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _showRecurrenceErrors = false;

  List<Map<String, dynamic>> _myPatients = [];
  String? _selectedPatientId;
  bool _isLoadingPatients = true;

  bool _isLoading = false;

  final _timeMaskFormatter = MaskTextInputFormatter(
    mask: '##:##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _serviceTypes = [
    'Acompanhamento e Companhia',
    'Higiene e Conforto (Banho/Trocas)',
    'Administração de Medicamentos',
    'Preparação de Refeições',
    'Mobilidade e Exercícios',
    'Cuidados Pós-Cirúrgicos',
    'Plantão Noturno (Pernoite)',
    'Outros (Especifique nas Observações)',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyPatients();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyPatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final userId = _authService.currentUser!.id;
      final data = await _patientService.getSimplePatients(userId);
      setState(() {
        _myPatients = data;
        _isLoadingPatients = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar pacientes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoadingPatients = false);
    }
  }

  void _goToCreatePatient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyPatientsScreen()),
    );
    _fetchMyPatients();
  }

  double get _totalValue {
    if (_startTime == null || _endTime == null) return 0.0;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    int durationMinutes = endMinutes - startMinutes;
    if (durationMinutes < 0) {
      durationMinutes += 24 * 60;
    }
    final hours = durationMinutes / 60.0;

    return hours * widget.caregiver.hourlyRate;
  }

  void _calculateUniqueDays() {
    _selectedDays.clear();
    if (_recurrentStartDate == null || _recurrentEndDate == null) {
      setState(() {});
      return;
    }

    DateTime currentDate = _recurrentStartDate!;
    final endDate = _recurrentEndDate!;

    final tempDays = <int>{};

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      tempDays.add(currentDate.weekday);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    setState(() {
      _selectedDays.addAll(tempDays);
    });
  }

  Future<void> _pickDate({bool isRecurrentStart = false}) async {
    final now = DateTime.now();
    final initialDate = isRecurrentStart ? _recurrentStartDate : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        if (_isRecurrent) {
          if (isRecurrentStart) {
            _recurrentStartDate = picked;
            if (_recurrentEndDate != null &&
                _recurrentEndDate!.isBefore(picked)) {
              _recurrentEndDate = picked;
            }
          } else {
            if (_recurrentStartDate != null &&
                picked.isBefore(_recurrentStartDate!)) {
              _recurrentStartDate = picked;
            }
            _recurrentEndDate = picked;
          }
          _calculateUniqueDays();
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _updateTimeVariables(isStart, picked);
    }
  }

  void _updateTimeVariables(bool isStart, TimeOfDay time) {
    setState(() {
      final formatted =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        _startTime = time;
        _startTimeController.text = formatted;
        if (_endTime != null) {
          final startMin = _startTime!.hour * 60 + _startTime!.minute;
          final endMin = _endTime!.hour * 60 + _endTime!.minute;
          if (endMin <= startMin) {
            _endTime = null;
            _endTimeController.clear();
          }
        }
      } else {
        _endTime = time;
        _endTimeController.text = formatted;
      }
    });
  }

  void _onTimeFieldChanged(bool isStart, String value) {
    if (value.length == 5) {
      try {
        final parts = value.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          setState(() {
            if (isStart) {
              _startTime = TimeOfDay(hour: hour, minute: minute);
            } else {
              _endTime = TimeOfDay(hour: hour, minute: minute);
            }
          });
        }
      } catch (e) {
        // ignora
      }
    }
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    return time.hour + (time.minute / 60.0);
  }

  String? _validateTime(String? val) {
    if (val == null || val.isEmpty) return 'Obrigatório';
    if (val.length != 5) return 'Formato HH:mm';
    try {
      final parts = val.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour < 0 || hour > 23) return 'Hora inválida';
      if (minute < 0 || minute > 59) return 'Minuto inválido';
    } catch (e) {
      return 'Formato inválido';
    }
    return null;
  }

  List<Map<String, dynamic>> _generateAppointments() {
    final List<Map<String, dynamic>> appointments = [];
    final user = _authService.currentUser;
    if (user == null ||
        _selectedPatientId == null ||
        _selectedService == null ||
        _startTime == null ||
        _endTime == null) {
      return [];
    }

    final startStr =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endStr =
        '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

    final baseData = {
      'cuidador_id': widget.caregiver.id,
      'familiar_id': user.id,
      'paciente_id': _selectedPatientId,
      'tipo_servico': _selectedService,
      'hora_inicio': startStr,
      'hora_fim': endStr,
      'endereco_local': _addressController.text.trim(),
      'observacao': _notesController.text.trim(),
      'valor_total': _totalValue,
      'status': AppointmentStatus.pendenteAceite.dbValue,
    };

    if (!_isRecurrent) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      appointments.add({...baseData, 'data_agendamento': dateStr});
    } else {
      DateTime currentDate = _recurrentStartDate!;
      final endDate = _recurrentEndDate!;

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        if (_selectedDays.contains(currentDate.weekday)) {
          final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
          appointments.add({...baseData, 'data_agendamento': dateStr});
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return appointments;
  }

  String? _validateRecurrenceFields(DateTime? date, String fieldName) {
    if (date == null) return '$fieldName é obrigatório.';
    if (fieldName == 'Data Final' &&
        _recurrentStartDate != null &&
        date.isBefore(_recurrentStartDate!)) {
      return 'Data final deve ser posterior ou igual à inicial.';
    }
    return null;
  }

  String? _validateSelectedDays() {
    if (_selectedDays.isEmpty) {
      return 'O intervalo de datas não gerou dias válidos.';
    }
    return null;
  }

  Future<void> _submitAppointment() async {
    setState(() => _showRecurrenceErrors = true);

    if (!_formKey.currentState!.validate()) return;

    if (_isRecurrent) {
      if (_validateRecurrenceFields(_recurrentStartDate, 'Data Inicial') !=
              null ||
          _validateRecurrenceFields(_recurrentEndDate, 'Data Final') != null ||
          _validateSelectedDays() != null) {
        return;
      }
    } else {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione a data para o agendamento único.'),
          ),
        );
        return;
      }
    }

    if (_totalValue <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O serviço deve ter uma duração positiva.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final appointmentsToCreate = _generateAppointments();
    if (appointmentsToCreate.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nenhum agendamento gerado. Verifique as datas e dias selecionados.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final novoInicio = _timeOfDayToDouble(_startTime!);
    final novoFim = _timeOfDayToDouble(_endTime!);

    try {
      for (var appointmentData in appointmentsToCreate) {
        final dateStr = appointmentData['data_agendamento']!;

        bool hasConflict = await _appointmentService.checkConflict(
          caregiverId: widget.caregiver.id,
          dateStr: dateStr,
          startTime: novoInicio,
          endTime: novoFim,
        );

        if (hasConflict) {
          final conflictDate = DateFormat(
            'dd/MM/yyyy',
          ).format(DateTime.parse(dateStr));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Conflito na agenda do cuidador na data: $conflictDate. Por favor, ajuste o horário ou a data.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (appointmentsToCreate.length == 1) {
        await _appointmentService.createAppointment(appointmentsToCreate.first);
      } else {
        await _appointmentService.createMultipleAppointments(
          appointmentsToCreate,
        );
      }

      String successMessage = appointmentsToCreate.length > 1
          ? '${appointmentsToCreate.length} solicitações recorrentes enviadas para ${widget.caregiver.nome}!'
          : 'Solicitação de agendamento enviada com sucesso para ${widget.caregiver.nome}!';

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = AppFormatters.currency;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Novo Agendamento',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildPatientSelection(),
                    const SizedBox(height: 16),
                    _buildServiceTypeDropdown(),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Agendamento Recorrente?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _isRecurrent,
                          onChanged: (val) {
                            setState(() {
                              _isRecurrent = val;
                              if (val) {
                                _selectedDate = null;
                                _showRecurrenceErrors = false;
                                if (_recurrentStartDate != null &&
                                    _recurrentEndDate != null) {
                                  _calculateUniqueDays();
                                }
                              } else {
                                _recurrentStartDate = null;
                                _recurrentEndDate = null;
                                _selectedDays.clear();
                                _showRecurrenceErrors = false;
                              }
                            });
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _isRecurrent
                        ? _buildRecurrentFields()
                        : _buildSingleDateField(),

                    const SizedBox(height: 16),

                    _buildTimeFields(),

                    const SizedBox(height: 16),
                    _buildAddressField(),
                    const SizedBox(height: 16),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildPriceAndSubmit(context, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelection() {
    if (_isLoadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPatientId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Para quem é o cuidado?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            items: _myPatients.map((patient) {
              return DropdownMenuItem(
                value: patient['id'] as String,
                child: Text(
                  patient['nome'] as String,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedPatientId = val),
            validator: (value) => value == null ? 'Selecione o paciente' : null,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            tooltip: 'Novo Paciente',
            onPressed: _goToCreatePatient,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedService,
      decoration: const InputDecoration(
        labelText: 'Tipo de Serviço',
        border: OutlineInputBorder(),
      ),
      items: _serviceTypes.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (val) => setState(() => _selectedService = val),
      validator: (value) => value == null ? 'Selecione um serviço' : null,
    );
  }

  Widget _buildSingleDateField() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data do Serviço',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate == null
              ? 'Selecione a data'
              : AppFormatters.date.format(_selectedDate!),
          style: TextStyle(
            color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateInput(
                label: 'Data Inicial',
                date: _recurrentStartDate,
                onTap: () => _pickDate(isRecurrentStart: true),
                validator: (date) =>
                    _validateRecurrenceFields(date, 'Data Inicial'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateInput(
                label: 'Data Final',
                date: _recurrentEndDate,
                onTap: () => _pickDate(isRecurrentStart: false),
                validator: (date) =>
                    _validateRecurrenceFields(date, 'Data Final'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Dias da Semana:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        if (_showRecurrenceErrors && _selectedDays.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _validateSelectedDays()!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        _buildDaysSelector(),
      ],
    );
  }

  Widget _buildDateInput({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required String? Function(DateTime?) validator,
  }) {
    final String? errorMsg = _showRecurrenceErrors ? validator(date) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
              errorText: errorMsg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: Text(
              date == null
                  ? '00/00/0000'
                  : AppFormatters.date.format(date),
              style: TextStyle(
                color: date == null ? Colors.grey.shade600 : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    final List<String> weekDays = [
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb',
      'Dom',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = _selectedDays.contains(dayIndex);
        final onTapAction = _isRecurrent
            ? null
            : () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(dayIndex);
                  } else {
                    _selectedDays.add(dayIndex);
                  }
                });
              };
        final bool isDisabled = _isRecurrent;
        return GestureDetector(
          onTap: onTapAction,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDisabled ? Colors.grey.shade200 : Colors.grey.shade200),
              shape: BoxShape.circle,
              border: _showRecurrenceErrors && _selectedDays.isEmpty
                  ? Border.all(color: AppColors.error, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                weekDays[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _startTimeController,
            keyboardType: TextInputType.number,
            inputFormatters: [_timeMaskFormatter],
            decoration: InputDecoration(
              labelText: 'Início (HH:mm)',
              hintText: '08:00',
              border: const OutlineInputBorder(),
              prefixIcon: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickTime(true),
              ),
            ),
            onChanged: (val) => _onTimeFieldChanged(true, val),
            validator: _validateTime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _endTimeController,
            keyboardType: TextInputType.number,
            inputFormatters: [_timeMaskFormatter],
            decoration: InputDecoration(
              labelText: 'Fim (HH:mm)',
              hintText: '17:00',
              border: const OutlineInputBorder(),
              prefixIcon: IconButton(
                icon: const Icon(Icons.access_time_filled),
                onPressed: () => _pickTime(false),
              ),
            ),
            onChanged: (val) => _onTimeFieldChanged(false, val),
            validator: _validateTime,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Endereço do Local',
        hintText: 'Rua, Número, Bairro...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      validator: (val) =>
          val == null || val.isEmpty ? 'Informe o endereço' : null,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Observações (Opcional)',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note_alt_outlined),
      ),
    );
  }

  Widget _buildPriceAndSubmit(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    int occurrenceCount = 1;
    if (_isRecurrent &&
        _recurrentStartDate != null &&
        _recurrentEndDate != null) {
      DateTime currentDate = _recurrentStartDate!;
      final endDate = _recurrentEndDate!;
      occurrenceCount = 0;
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        if (_selectedDays.contains(currentDate.weekday)) {
          occurrenceCount++;
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
    } else if (!_isRecurrent && _selectedDate != null) {
      occurrenceCount = 1;
    } else {
      occurrenceCount = 0;
    }

    final totalValue = _totalValue * occurrenceCount;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.shade100),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecurrent ? 'Total de Turnos:' : 'Turnos:',
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _isRecurrent
                          ? 'Valor Estimado Total:'
                          : 'Valor Estimado:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${occurrenceCount}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      currencyFormat.format(totalValue),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || occurrenceCount == 0
                    ? null
                    : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        _isRecurrent
                            ? 'Solicitar $occurrenceCount Agendamentos'
                            : 'Solicitar Agendamento',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
