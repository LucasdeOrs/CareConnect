import 'package:careconnect_app/screens/payment/payment_screen.dart';
import 'package:careconnect_app/screens/profile/familiar_screens/my_patients_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../main.dart';
import '../../models/caregiver_profile.dart';

class AppointmentFormModal extends StatefulWidget {
  final CaregiverProfile caregiver;

  const AppointmentFormModal({super.key, required this.caregiver});

  @override
  State<AppointmentFormModal> createState() => _AppointmentFormModalState();
}

class _AppointmentFormModalState extends State<AppointmentFormModal> {
  final _formKey = GlobalKey<FormState>();

  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<Map<String, dynamic>> _myPatients = [];
  String? _selectedPatientId;
  bool _isLoadingPatients = true;

  bool _isLoading = false;

  final _timeMaskFormatter = MaskTextInputFormatter(
    mask: '##:##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _serviceTypes = [
    'Acompanhamento',
    'Cuidados Básicos',
    'Higiene e Conforto',
    'Administração de Medicamentos',
    'Pernoite',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyPatients();
  }

  Future<void> _fetchMyPatients() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('pacientes')
          .select('id, nome')
          .eq('familiar_id', userId)
          .order('nome', ascending: true);

      setState(() {
        _myPatients = List<Map<String, dynamic>>.from(data);
        _isLoadingPatients = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar pacientes: $e');
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

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
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

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione o paciente.')),
      );
      return;
    }

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, verifique a data e os horários.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final novoInicio = _timeOfDayToDouble(_startTime!);
    final novoFim = _timeOfDayToDouble(_endTime!);

    try {
      final bloqueios = await supabase
          .from('bloqueios_agenda')
          .select('hora_inicio, hora_fim')
          .eq('cuidador_id', widget.caregiver.id)
          .eq('data_bloqueio', dateStr);

      for (var bloqueio in bloqueios) {
        final existingStart = _timeStringToDouble(bloqueio['hora_inicio']);
        final existingEnd = _timeStringToDouble(bloqueio['hora_fim']);
        if (novoInicio < existingEnd && novoFim > existingStart) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Este cuidador está bloqueado das ${bloqueio['hora_inicio'].substring(0, 5)} às ${bloqueio['hora_fim'].substring(0, 5)}.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final agendamentos = await supabase
          .from('agendamentos')
          .select('hora_inicio, hora_fim')
          .eq('cuidador_id', widget.caregiver.id)
          .eq('data_agendamento', dateStr)
          .inFilter('status', ['pago', 'confirmado']);

      for (var agendamento in agendamentos) {
        final existingStart = _timeStringToDouble(agendamento['hora_inicio']);
        final existingEnd = _timeStringToDouble(agendamento['hora_fim']);
        if (novoInicio < existingEnd && novoFim > existingStart) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'O cuidador já possui um agendamento neste horário.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar agenda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não logado');
      final startStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

      final response = await supabase
          .from('agendamentos')
          .insert({
            'cuidador_id': widget.caregiver.id,
            'familiar_id': user.id,
            'paciente_id': _selectedPatientId,
            'tipo_servico': _selectedService,
            'data_agendamento': dateStr,
            'hora_inicio': startStr,
            'hora_fim': endStr,
            'endereco_local': _addressController.text.trim(),
            'observacao': _notesController.text.trim(),
            'valor_total': _totalValue,
            'status': 'aguardando_pagamento',
          })
          .select()
          .single();

      final agendamentoId = response['id'];
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              agendamentoId: agendamentoId,
              caregiver: widget.caregiver,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao agendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_startTime != null && _endTime != null) {
      final startMin = _startTime!.hour * 60 + _startTime!.minute;
      final endMin = _endTime!.hour * 60 + _endTime!.minute;
      if (endMin <= startMin) return 'Fim deve ser > Início';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

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
                  const Text(
                    'Novo Agendamento',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  children: [
                    const SizedBox(height: 16),
                    if (_isLoadingPatients)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
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
                              onChanged: (val) =>
                                  setState(() => _selectedPatientId = val),
                              validator: (value) =>
                                  value == null ? 'Selecione o paciente' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.indigo,
                              ),
                              tooltip: 'Novo Paciente',
                              onPressed: _goToCreatePatient,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedService,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Serviço',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      items: _serviceTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedService = val),
                      validator: (value) =>
                          value == null ? 'Selecione um serviço' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
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
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço do Local',
                        hintText: 'Rua, Número, Bairro...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Informe o endereço'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações (Opcional)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Valor Estimado:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormat.format(_totalValue),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
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
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ir para Pagamento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
