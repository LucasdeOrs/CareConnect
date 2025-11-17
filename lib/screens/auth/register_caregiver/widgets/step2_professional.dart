import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/named_certificate_model.dart';
import 'package:careconnect_app/core/widgets/certificate_upload_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Step2Professional extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
  final TextEditingController profissaoController;
  final ValueNotifier<bool> formacaoSaudeNotifier;
  final TextEditingController experienceController;
  final TextEditingController yearsExperienceController;
  final ValueNotifier<List<String>> selectedSpecialtiesNotifier;
  final ValueNotifier<List<NamedCertificate>> certificateNotifier;
  final TextEditingController hourlyRateController;
  final ValueNotifier<String?> availabilityDaysNotifier;
  final ValueNotifier<String?> availabilityTimeNotifier;

  const Step2Professional({
    super.key,
    required this.formKey,
    required this.autovalidateMode,
    required this.profissaoController,
    required this.formacaoSaudeNotifier,
    required this.experienceController,
    required this.yearsExperienceController,
    required this.selectedSpecialtiesNotifier,
    required this.certificateNotifier,
    required this.hourlyRateController,
    required this.availabilityDaysNotifier,
    required this.availabilityTimeNotifier,
  });

  @override
  State<Step2Professional> createState() => _Step2ProfessionalState();
}

class _Step2ProfessionalState extends State<Step2Professional> {
  final TextEditingController _specialtyInputController =
      TextEditingController();

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
  void dispose() {
    _specialtyInputController.dispose();
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
        !widget.selectedSpecialtiesNotifier.value.contains(cleanSpecialty)) {
      widget.selectedSpecialtiesNotifier.value = [
        ...widget.selectedSpecialtiesNotifier.value,
        cleanSpecialty,
      ];
      _specialtyInputController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 5.0),
        children: [
          TextFormField(
            controller: widget.profissaoController,
            decoration: const InputDecoration(
              labelText: 'Profissão Principal*',
              hintText: 'Ex: Cuidador de Idosos, Técnico de Enfermagem',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work_outline),
            ),
            validator: (value) => _validateRequired(value, 'Profissão'),
            autovalidateMode: widget.autovalidateMode,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: widget.experienceController,
            decoration: const InputDecoration(
              labelText: 'Experiência como cuidador*',
              hintText: 'Descreva sua trajetória, habilidades e motivações...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description_outlined),
            ),
            maxLines: 5,
            validator: (value) => _validateRequired(value, 'Experiência'),
            autovalidateMode: widget.autovalidateMode,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          ValueListenableBuilder<bool>(
            valueListenable: widget.formacaoSaudeNotifier,
            builder: (context, isChecked, _) {
              return CheckboxListTile(
                title: const Text('Possui formação na área da saúde?'),
                subtitle: const Text(
                  '(Ex: Técnico de enfermagem, Enfermeiro, etc.)',
                ),
                value: isChecked,
                onChanged: (bool? value) {
                  widget.formacaoSaudeNotifier.value = value ?? false;
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
            controller: widget.yearsExperienceController,
            decoration: const InputDecoration(
              labelText: 'Anos de Experiência*',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                _validateRequired(value, 'Anos de Experiência'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),

          ValueListenableBuilder<List<String>>(
            valueListenable: widget.selectedSpecialtiesNotifier,
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
                          widget.selectedSpecialtiesNotifier.value =
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
            controller: widget.hourlyRateController,
            decoration: const InputDecoration(
              labelText: 'Preço por Hora*',
              hintText: 'Ex: 30,00',
              border: OutlineInputBorder(),
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.attach_money_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_currencyFormatter],
            validator: (value) => _validateNumber(value, 'Preço por Hora'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: widget.availabilityDaysNotifier.value,
            decoration: const InputDecoration(
              labelText: 'Disponibilidade (Dias)*',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.date_range_outlined),
            ),
            items: _availabilityDayOptions.map((String day) {
              return DropdownMenuItem<String>(value: day, child: Text(day));
            }).toList(),
            onChanged: (String? newValue) {
              widget.availabilityDaysNotifier.value = newValue;
            },
            validator: (value) =>
                _validateRequired(value, 'Disponibilidade de dias'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: widget.availabilityTimeNotifier.value,
            decoration: const InputDecoration(
              labelText: 'Disponibilidade (Período)*',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time_outlined),
            ),
            items: _availabilityTimeOptions.map((String time) {
              return DropdownMenuItem<String>(value: time, child: Text(time));
            }).toList(),
            onChanged: (String? newValue) {
              widget.availabilityTimeNotifier.value = newValue;
            },
            validator: (value) =>
                _validateRequired(value, 'Disponibilidade de período'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 24),

          CertificateUploadWidget(
            uploadedCertificatesNotifier: widget.certificateNotifier,
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
