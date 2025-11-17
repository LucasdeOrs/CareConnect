// [COLE ESTE CÓDIGO INTEIRO EM: step1_personal.dart]

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../widgets/image_upload_widget.dart';

class Step1Personal extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;

  // CAMPOS DESTE STEP
  final TextEditingController cpfController;
  final TextEditingController birthDateController;
  final TextEditingController fullAddressController;
  final TextEditingController cidadeUFController;
  final ValueNotifier<String?> selectedGeneroNotifier;
  final ValueNotifier<XFile?> profileImageNotifier;

  const Step1Personal({
    super.key,
    required this.formKey,
    required this.autovalidateMode,
    required this.cpfController,
    required this.birthDateController,
    required this.fullAddressController,
    required this.cidadeUFController,
    required this.selectedGeneroNotifier,
    required this.profileImageNotifier,
  });

  @override
  State<Step1Personal> createState() => _Step1PersonalState();
}

class _Step1PersonalState extends State<Step1Personal> {
  // Formatadores
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _birthDateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Lista de Gênero
  final List<String> _generoOptions = [
    'Masculino',
    'Feminino',
    'Outro',
    'Prefiro não informar',
  ];

  // Upload de Imagem
  final _imagePicker = ImagePicker();

  // API de Cidades
  static List<String> _todasCidadesComUF = [];
  static bool _isLoadingApi = false;
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarCidades();
  }

  // --- Funções de Validação ---
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório(a)';
    }
    return null;
  }

  String? _validateCPF(String? value) {
    if (value == null || value.isEmpty) return 'CPF é obrigatório';
    String cpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return 'CPF inválido (11 dígitos)';
    return null;
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.isEmpty)
      return 'Data de Nascimento é obrigatória';
    try {
      final date = DateFormat('dd/MM/yyyy', 'pt_BR').parseStrict(value);
      final eighteenYearsAgo = DateTime.now().subtract(
        const Duration(days: 365 * 18 + 4),
      );
      if (date.isAfter(eighteenYearsAgo)) return 'Deve ter no mínimo 18 anos';
    } catch (e) {
      return 'Data inválida (dd/MM/yyyy)';
    }
    return null;
  }

  String? _validateCidadeUF(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'O campo Cidade é obrigatório';
    final parts = value.split(', ');
    if (parts.length != 2) return 'Formato inválido. (Ex: Cidade, UF)';
    if (_todasCidadesComUF.isNotEmpty &&
        !_todasCidadesComUF.contains(value.trim())) {
      return 'Selecione uma cidade válida da lista.';
    }
    return null;
  }

  // --- Funções Auxiliares ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime eighteenYearsAgo = DateTime.now().subtract(
      const Duration(days: 365 * 18 + 4),
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: DateTime(1920),
      lastDate: eighteenYearsAgo,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      widget.birthDateController.text = DateFormat(
        'dd/MM/yyyy',
        'pt_BR',
      ).format(picked);
    }
  }

  Future<void> _carregarCidades() async {
    if (_todasCidadesComUF.isNotEmpty || _isLoadingApi) return;
    _isLoadingApi = true;
    if (mounted) setState(() => _isLocalLoading = true);
    try {
      final url = Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/municipios?orderBy=nome',
      );
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        _todasCidadesComUF = data.map((item) {
          final String nome = item['nome'];
          final String uf =
              item['regiao-imediata']['regiao-intermediaria']['UF']['sigla'];
          return "$nome, $uf";
        }).toList();
      }
    } catch (e) {
      debugPrint("Erro ao carregar cidades: $e");
    } finally {
      _isLoadingApi = false;
      if (mounted) setState(() => _isLocalLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 5.0),
        children: [
          ImageUploadWidget(
            profileImageNotifier: widget.profileImageNotifier,
            imagePicker: _imagePicker,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: widget.cpfController,
            decoration: const InputDecoration(
              labelText: 'CPF*',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [_cpfFormatter],
            validator: _validateCPF,
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),
          Autocomplete<String>(
            initialValue: TextEditingValue(
              text: widget.cidadeUFController.text,
            ),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (_isLocalLoading) return ["Carregando cidades..."];
              if (textEditingValue.text.isEmpty)
                return const Iterable<String>.empty();
              final query = textEditingValue.text.toLowerCase();
              return _todasCidadesComUF.where((String option) {
                return option.toLowerCase().contains(query);
              });
            },
            onSelected: (String selection) {
              widget.cidadeUFController.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Cidade e Estado*',
                  hintText: 'Ex: São Paulo, SP',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isLocalLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                validator: _validateCidadeUF,
                autovalidateMode: widget.autovalidateMode,
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.fullAddressController,
            decoration: const InputDecoration(
              labelText: 'Endereço Completo (Rua, N°, Bairro)*',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _validateRequired(value, 'Endereço'),
            autovalidateMode: widget.autovalidateMode,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.birthDateController,
            decoration: InputDecoration(
              labelText: 'Data de Nascimento*',
              hintText: 'dd/MM/yyyy',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            inputFormatters: [_birthDateFormatter],
            validator: _validateBirthDate,
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: widget.selectedGeneroNotifier.value,
            decoration: const InputDecoration(
              labelText: 'Gênero*',
              border: OutlineInputBorder(),
            ),
            items: _generoOptions.map((String genero) {
              return DropdownMenuItem<String>(
                value: genero,
                child: Text(genero),
              );
            }).toList(),
            onChanged: (String? newValue) {
              widget.selectedGeneroNotifier.value = newValue;
            },
            validator: (value) => _validateRequired(value, 'Gênero'),
            autovalidateMode: widget.autovalidateMode,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
