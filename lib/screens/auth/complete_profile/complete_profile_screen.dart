import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../main.dart';
import '../../../widgets/image_upload_widget.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? _user = supabase.auth.currentUser;
  bool _isLoading = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _birthDateController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _cidadeUFController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String? _selectedGenero;

  final _profileImageNotifier = ValueNotifier<XFile?>(null);
  final _imagePicker = ImagePicker();

  static List<String> _todasCidadesComUF = [];
  static bool _isLoadingApi = false;
  bool _isLocalLoading = false;

  final _birthDateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _generoOptions = [
    'Masculino',
    'Feminino',
    'Outro',
    'Prefiro não informar',
  ];

  @override
  void initState() {
    super.initState();
    _carregarCidades();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cidadeUFController.dispose();
    _profileImageNotifier.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório(a)';
    }
    return null;
  }

  String? _validateCidadeUF(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O campo Cidade é obrigatório';
    }
    final parts = value.split(', ');
    if (parts.length != 2) {
      return 'Formato inválido. Selecione na lista (Ex: Cidade, UF)';
    }
    if (_todasCidadesComUF.isNotEmpty &&
        !_todasCidadesComUF.contains(value.trim())) {
      return 'Selecione uma cidade válida da lista.';
    }
    _cityController.text = parts[0].trim();
    _stateController.text = parts[1].trim();
    return null;
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Data de Nascimento é obrigatória';
    }
    try {
      final date = DateFormat('dd/MM/yyyy', 'pt_BR').parseStrict(value);
      final eighteenYearsAgo = DateTime.now().subtract(
        const Duration(days: 365 * 18 + 4),
      );
      if (date.isAfter(eighteenYearsAgo)) {
        return 'Deve ter no mínimo 18 anos';
      }
    } catch (e) {
      return 'Data inválida (dd/MM/yyyy)';
    }
    return null;
  }

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
      _birthDateController.text = DateFormat(
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
      if (mounted) {
        setState(() => _isLocalLoading = false);
      }
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? profileImageUrl;
      final profileImage = _profileImageNotifier.value;

      if (profileImage != null) {
        final fileExt = profileImage.name.split('.').last.toLowerCase();
        final filePath = '${_user.id}/profile.$fileExt';
        final fileBytes = await profileImage.readAsBytes();

        await supabase.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: profileImage.mimeType,
              ),
            );
        profileImageUrl = supabase.storage
            .from('avatars')
            .getPublicUrl(filePath);
      }

      final date = DateFormat(
        'dd/MM/yyyy',
        'pt_BR',
      ).parseStrict(_birthDateController.text);

      final Map<String, dynamic> userUpdates = {
        'avatar_url': profileImageUrl,
        'birthDate': date.toIso8601String(),
        'genero': _selectedGenero,
        'full_address': _fullAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'profile_completed': true,
        'status': 'Ativo',
      };

      await supabase.from('usuarios').update(userUpdates).eq('id', _user.id);
      await supabase.auth.updateUser(
        UserAttributes(
          data: {...?_user.userMetadata, 'profile_completed': true},
        ),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      debugPrint("Erro ao completar perfil: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar dados: ${e.toString()}'),
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
        title: const Text('Complete seu Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Olá, ${_user?.userMetadata?['nome'] ?? 'usuário'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Faltam só mais alguns dados para ativarmos sua conta.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              ImageUploadWidget(
                profileImageNotifier: _profileImageNotifier,
                imagePicker: _imagePicker,
              ),
              const SizedBox(height: 24),

              Autocomplete<String>(
                initialValue: TextEditingValue(text: _cidadeUFController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (_isLocalLoading) return ["Carregando cidades..."];
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return _todasCidadesComUF.where((String option) {
                    return option.toLowerCase().contains(query);
                  });
                },
                onSelected: (String selection) {
                  final parts = selection.split(', ');
                  if (parts.length == 2) {
                    _cityController.text = parts[0];
                    _stateController.text = parts[1];
                    _cidadeUFController.text = selection;
                  }
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
                    autovalidateMode: _autovalidateMode,
                  );
                },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _birthDateController,
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
                autovalidateMode: _autovalidateMode,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _fullAddressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço Completo (Rua, N°, Bairro)*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateRequired(value, 'Endereço'),
                autovalidateMode: _autovalidateMode,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedGenero,
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
                  setState(() {
                    _selectedGenero = newValue;
                  });
                },
                validator: (value) => _validateRequired(value, 'Gênero'),
                autovalidateMode: _autovalidateMode,
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _completeProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salvar e Concluir'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
