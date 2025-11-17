// [COLE ESTE CÓDIGO INTEIRO EM: step2_professional.dart]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// (Seu CurrencyInputFormatter fica aqui)
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    final value = int.parse(digitsOnly);
    final double realValue = value / 100.0;
    String formattedText = _formatter.format(realValue);
    String finalValue = formattedText
        .replaceAll(_formatter.currencySymbol, '')
        .trim();
    return TextEditingValue(
      text: finalValue,
      selection: TextSelection.collapsed(offset: finalValue.length),
    );
  }
}

// A classe NamedCertificate precisa ser visível para a tela principal
class NamedCertificate {
  final PlatformFile file;
  String name;
  TextEditingController controller;

  NamedCertificate({required this.file, required this.name})
    : controller = TextEditingController(text: name);
}

class Step2Professional extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;

  // CAMPOS DESTE STEP
  final TextEditingController profissaoController;
  final ValueNotifier<bool> formacaoSaudeNotifier;
  final TextEditingController experienceController;
  final TextEditingController yearsExperienceController;
  final ValueNotifier<List<String>> selectedSpecialtiesNotifier;
  final ValueNotifier<List<NamedCertificate>> certificateNotifier;

  // --- CAMPOS MOVIDOS PARA CÁ ---
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
    // --- CAMPOS MOVIDOS PARA CÁ ---
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
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
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
          // --- ORDEM CORRIGIDA ---

          // 1. Profissão (MUDADO PARA TEXTFIELD)
          TextFormField(
            controller: widget.profissaoController,
            decoration: const InputDecoration(
              labelText: 'Profissão Principal*',
              hintText: 'Ex: Cuidador de Idosos, Técnico de Enfermagem',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateRequired(value, 'Profissão'),
            autovalidateMode: widget.autovalidateMode,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // 2. Experiência (Descrição)
          TextFormField(
            controller: widget.experienceController,
            decoration: const InputDecoration(
              labelText: 'Experiência como cuidador*',
              hintText: 'Descreva sua trajetória, habilidades e motivações...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: (value) => _validateRequired(value, 'Experiência'),
            autovalidateMode: widget.autovalidateMode,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // 3. Formação Saúde (MOVIDO PARA CÁ)
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
                  color: Colors.blue.shade700,
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
          const SizedBox(height: 16),

          // 4. Anos de Experiência
          TextFormField(
            controller: widget.yearsExperienceController,
            decoration: const InputDecoration(
              labelText: 'Anos de Experiência*',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                _validateRequired(value, 'Anos de Experiência'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),

          // 5. Especialidades
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

          // 6. Preço/Hora (ESPAÇAMENTO CORRIGIDO)
          const SizedBox(height: 16), // <-- MUDADO DE 24 para 16
          TextFormField(
            controller: widget.hourlyRateController,
            decoration: const InputDecoration(
              labelText: 'Preço por Hora*',
              hintText: 'Ex: 30,00',
              border: OutlineInputBorder(),
              prefixText: 'R\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_currencyFormatter],
            validator: (value) => _validateNumber(value, 'Preço por Hora'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),

          // 7. Disponibilidade (Dias)
          DropdownButtonFormField<String>(
            value: widget.availabilityDaysNotifier.value,
            decoration: const InputDecoration(
              labelText: 'Disponibilidade (Dias)*',
              border: OutlineInputBorder(),
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

          // 8. Disponibilidade (Período)
          DropdownButtonFormField<String>(
            value: widget.availabilityTimeNotifier.value,
            decoration: const InputDecoration(
              labelText: 'Disponibilidade (Período)*',
              border: OutlineInputBorder(),
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
          const SizedBox(height: 24), // Espaço maior para agrupar
          // 9. Certificados (Por último)
          CertificateUploadWidget(
            uploadedCertificatesNotifier: widget.certificateNotifier,
            autovalidateMode: widget.autovalidateMode,
            validator: _validateRequired,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- WIDGET DE UPLOAD DE CERTIFICADO (COLE NO FIM DO ARQUIVO) ---

class CertificateUploadWidget extends StatelessWidget {
  final ValueNotifier<List<NamedCertificate>> uploadedCertificatesNotifier;
  final AutovalidateMode autovalidateMode;
  final String? Function(String?, String) validator;

  const CertificateUploadWidget({
    super.key,
    required this.uploadedCertificatesNotifier,
    required this.autovalidateMode,
    required this.validator,
  });

  Future<void> _pickCertificates(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'doc', 'docx'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final newCertificates = result.files
            .where((file) => file.name.isNotEmpty)
            .map((file) {
              final fileName = file.name;
              final nameWithoutExtension = fileName.split('.').first;
              return NamedCertificate(
                file: file,
                name: nameWithoutExtension.isEmpty
                    ? 'Novo Certificado'
                    : nameWithoutExtension,
              );
            })
            .toList();

        uploadedCertificatesNotifier.value = [
          ...uploadedCertificatesNotifier.value,
          ...newCertificates,
        ];
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao selecionar: $e')));
      }
    }
  }

  void _removeCertificate(NamedCertificate certificate) {
    uploadedCertificatesNotifier.value = uploadedCertificatesNotifier.value
        .where((c) => c != certificate)
        .toList();
    certificate.controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificados e Cursos (Opcional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pickCertificates(context),
          icon: const Icon(Icons.upload_file),
          label: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text('Upload de certificados (PNG, PDF, etc.)'),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            alignment: Alignment.centerLeft,
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        ValueListenableBuilder<List<NamedCertificate>>(
          valueListenable: uploadedCertificatesNotifier,
          builder: (context, uploadedCertificates, child) {
            if (uploadedCertificates.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...uploadedCertificates.map((cert) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: cert.controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome do Certificado',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (newName) => cert.name = newName,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) =>
                                      validator(value, 'Nome do Certificado'),
                                  autovalidateMode: autovalidateMode,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Arquivo: ${cert.file.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeCertificate(cert),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
