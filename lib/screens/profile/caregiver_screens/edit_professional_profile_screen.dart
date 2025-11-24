import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/services/caregiver_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfessionalProfileScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;

  const EditProfessionalProfileScreen({
    super.key,
    required this.caregiverProfile,
  });

  @override
  State<EditProfessionalProfileScreen> createState() =>
      _EditProfessionalProfileScreenState();
}

class _EditProfessionalProfileScreenState
    extends State<EditProfessionalProfileScreen> {
  final CaregiverService _caregiverService = CaregiverService();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _profissaoController;
  late final TextEditingController _experienceController;
  late final TextEditingController _yearsExperienceController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _specialtyInputController;

  late final ValueNotifier<bool> _formacaoSaudeNotifier;
  late final ValueNotifier<String?> _availabilityDaysNotifier;
  late final ValueNotifier<String?> _availabilityTimeNotifier;
  late final ValueNotifier<List<String>> _selectedSpecialtiesNotifier;

  late final ValueNotifier<bool> _fumanteNotifier;
  late final ValueNotifier<bool> _cnhNotifier;
  late final ValueNotifier<bool> _carroNotifier;
  late final ValueNotifier<bool> _petsNotifier;

  late final ValueNotifier<bool> _cozinhaNotifier;
  late final ValueNotifier<bool> _limpezaNotifier;
  late final ValueNotifier<bool> _dormirNotifier;

  final CurrencyInputFormatter _currencyFormatter = CurrencyInputFormatter();

  final List<String> _availabilityDayOptions = [
    'Qualquer dia',
    'Dias de semana',
    'Finais de semana',
  ];
  final List<String> _availabilityTimeOptions = [
    'Qualquer Período',
    'Período do Dia',
    'Período da Noite',
    'Período da Tarde',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.caregiverProfile;

    _profissaoController = TextEditingController(text: profile.profissao);
    _experienceController = TextEditingController(text: profile.experiencia);
    _yearsExperienceController = TextEditingController(
      text: profile.experienceYears.toString(),
    );

    final formattedPrice = _currencyFormatter
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: (profile.hourlyRate * 100).toInt().toString()),
        )
        .text;
    _hourlyRateController = TextEditingController(text: formattedPrice);

    _specialtyInputController = TextEditingController();

    _formacaoSaudeNotifier = ValueNotifier(profile.formacaoSaude);
    _selectedSpecialtiesNotifier = ValueNotifier(profile.especialidades);

    _fumanteNotifier = ValueNotifier(profile.fumante);
    _cnhNotifier = ValueNotifier(profile.habilitaCnh);
    _carroNotifier = ValueNotifier(profile.possuiCarro);
    _petsNotifier = ValueNotifier(profile.gostaAnimais);

    _cozinhaNotifier = ValueNotifier(profile.cozinha);
    _limpezaNotifier = ValueNotifier(profile.limpeza);
    _dormirNotifier = ValueNotifier(profile.dormirLocal);

    final availability = profile.availabilityText.split(', ');
    _availabilityDaysNotifier = ValueNotifier(
      _availabilityDayOptions.contains(availability[0])
          ? availability[0]
          : _availabilityDayOptions[0],
    );
    _availabilityTimeNotifier = ValueNotifier(
      availability.length > 1 &&
              _availabilityTimeOptions.contains(availability[1])
          ? availability[1]
          : _availabilityTimeOptions[0],
    );
  }

  @override
  void dispose() {
    _profissaoController.dispose();
    _experienceController.dispose();
    _yearsExperienceController.dispose();
    _hourlyRateController.dispose();
    _specialtyInputController.dispose();
    _formacaoSaudeNotifier.dispose();
    _availabilityDaysNotifier.dispose();
    _availabilityTimeNotifier.dispose();
    _selectedSpecialtiesNotifier.dispose();
    _fumanteNotifier.dispose();
    _cnhNotifier.dispose();
    _carroNotifier.dispose();
    _petsNotifier.dispose();
    _cozinhaNotifier.dispose();
    _limpezaNotifier.dispose();
    _dormirNotifier.dispose();

    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório(a)';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório(a)';
    }
    final number = double.tryParse(
      value.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    if (number == null) return '$fieldName deve ser um número válido';
    if (number <= 0) return '$fieldName deve ser maior que zero';
    return null;
  }

  void _addSpecialty(String specialty) {
    final cleanSpecialty = specialty.trim();
    if (cleanSpecialty.isNotEmpty &&
        !_selectedSpecialtiesNotifier.value.contains(cleanSpecialty)) {
      _selectedSpecialtiesNotifier.value = [
        ..._selectedSpecialtiesNotifier.value,
        cleanSpecialty,
      ];
      _specialtyInputController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _updateProfessionalProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final priceString = _hourlyRateController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final hourlyRate = double.tryParse(priceString) ?? 0.0;

      final availability =
          '${_availabilityDaysNotifier.value}, ${_availabilityTimeNotifier.value}';

      final updates = {
        'profissao': _profissaoController.text.trim(),
        'experiencia': _experienceController.text.trim(),
        'experience_years':
            int.tryParse(_yearsExperienceController.text.trim()) ?? 0,
        'formacao_saude': _formacaoSaudeNotifier.value,
        'especialidades': _selectedSpecialtiesNotifier.value.join(','),
        'hourly_rate': hourlyRate,
        'availability': availability,

        'fumante': _fumanteNotifier.value,
        'habilita_cnh': _cnhNotifier.value,
        'possui_carro': _carroNotifier.value,
        'gosta_animais': _petsNotifier.value,
        'cozinha': _cozinhaNotifier.value,
        'limpeza': _limpezaNotifier.value,
        'dormir_local': _dormirNotifier.value,
      };

      await _caregiverService.updateProfile(
        widget.caregiverProfile.usuario_id,
        updates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil profissional atualizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    ValueNotifier<bool> notifier,
    IconData icon,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          value: value,
          onChanged: (val) => notifier.value = val,
          secondary: Icon(icon, color: AppColors.primary),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Profissional'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfessionalProfile,
            tooltip: 'Salvar',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              controller: _profissaoController,
              decoration: const InputDecoration(
                labelText: 'Profissão Principal*',
                hintText: 'Ex: Cuidador de Idosos, Técnico de Enfermagem',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (value) => _validateRequired(value, 'Profissão'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: 'Experiência como cuidador*',
                hintText:
                    'Descreva sua trajetória, habilidades e motivações...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 5,
              validator: (value) => _validateRequired(value, 'Experiência'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            const Text(
              "Informações Adicionais",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSwitchTile(
              "Fumante",
              "Você fuma?",
              _fumanteNotifier,
              Icons.smoking_rooms,
            ),
            _buildSwitchTile(
              "Carteira de Habilitação (CNH)",
              "Você possui habilitação válida?",
              _cnhNotifier,
              Icons.directions_car,
            ),
            _buildSwitchTile(
              "Veículo Próprio",
              "Possui carro para deslocamento?",
              _carroNotifier,
              Icons.car_rental,
            ),
            _buildSwitchTile(
              "Gosta de Animais",
              "Você se sente confortável em casas com pets?",
              _petsNotifier,
              Icons.pets,
            ),
            const Divider(height: 30),
            const Text(
              "Preferências de Serviço",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSwitchTile(
              "Cozinha para o paciente",
              "Aceita preparar refeições simples?",
              _cozinhaNotifier,
              Icons.soup_kitchen,
            ),
            _buildSwitchTile(
              "Limpeza leve",
              "Aceita manter o ambiente do paciente limpo?",
              _limpezaNotifier,
              Icons.cleaning_services,
            ),
            _buildSwitchTile(
              "Dormir no local",
              "Disponibilidade para pernoites/dormir?",
              _dormirNotifier,
              Icons.bedtime,
            ),
            const Divider(height: 30),

            ValueListenableBuilder<bool>(
              valueListenable: _formacaoSaudeNotifier,
              builder: (context, isChecked, _) {
                return CheckboxListTile(
                  title: const Text('Possui formação na área da saúde?'),
                  subtitle: const Text(
                    '(Ex: Técnico de enfermagem, Enfermeiro, etc.)',
                  ),
                  value: isChecked,
                  onChanged: (bool? value) {
                    _formacaoSaudeNotifier.value = value ?? false;
                  },
                  secondary: Icon(
                    Icons.health_and_safety,
                    color: AppColors.primary,
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearsExperienceController,
              decoration: const InputDecoration(
                labelText: 'Anos de Experiência*',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) =>
                  _validateRequired(value, 'Anos de Experiência'),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<String>>(
              valueListenable: _selectedSpecialtiesNotifier,
              builder: (context, selectedSpecialties, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _specialtyInputController,
                      decoration: const InputDecoration(
                        labelText: 'Especialidades (Opcional)',
                        hintText: 'Digite e pressione ENTER (Ex: Alzheimer)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star_outline),
                        suffixIcon: Icon(Icons.add),
                      ),
                      onSubmitted: _addSpecialty,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: selectedSpecialties.map((specialty) {
                        return Chip(
                          label: Text(specialty),
                          onDeleted: () {
                            _selectedSpecialtiesNotifier.value =
                                selectedSpecialties
                                    .where((s) => s != specialty)
                                    .toList();
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Preço por Hora*',
                hintText: 'Ex: 30,00',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.attach_money_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_currencyFormatter],
              validator: (value) => _validateNumber(value, 'Preço por Hora'),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: _availabilityDaysNotifier,
              builder: (context, value, _) {
                return DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: const InputDecoration(
                    labelText: 'Disponibilidade (Dias)*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                  items: _availabilityDayOptions.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    _availabilityDaysNotifier.value = newValue;
                  },
                  validator: (value) =>
                      _validateRequired(value, 'Disponibilidade de dias'),
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: _availabilityTimeNotifier,
              builder: (context, value, _) {
                return DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: const InputDecoration(
                    labelText: 'Disponibilidade (Período)*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  items: _availabilityTimeOptions.map((String time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    _availabilityTimeNotifier.value = newValue;
                  },
                  validator: (value) =>
                      _validateRequired(value, 'Disponibilidade de período'),
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfessionalProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
