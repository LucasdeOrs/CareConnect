import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step2_professional.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';

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
      final userId = supabase.auth.currentUser!.id;
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
      };

      await supabase
          .from('cuidadores')
          .update(updates)
          .eq('usuario_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil profissional atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              ),
              maxLines: 5,
              validator: (value) => _validateRequired(value, 'Experiência'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

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
                    color: Colors.blue.shade700,
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
                backgroundColor: Colors.indigo,
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
