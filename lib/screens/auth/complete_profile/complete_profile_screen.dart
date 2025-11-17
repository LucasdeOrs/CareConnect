import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/location_service.dart';
import 'package:careconnect_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/image_upload_widget.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  final _formKey = GlobalKey<FormState>();
  late final User? _user = _authService.currentUser;
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

  List<String> _todasCidadesComUF = [];
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
    if (LocationService.citiesCache.isNotEmpty) {
      setState(() {
        _todasCidadesComUF = LocationService.citiesCache;
      });
      return;
    }

    if (mounted) setState(() => _isLocalLoading = true);
    try {
      _todasCidadesComUF = await LocationService.getBrazilianCities();
    } catch (e) {
      debugPrint("Erro ao carregar cidades: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
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
        profileImageUrl = await _storageService.uploadAvatar(
          _user.id,
          profileImage,
        );
      }

      final date = DateFormat(
        'dd/MM/yyyy',
        'pt_BR',
      ).parseStrict(_birthDateController.text);

      final Map<String, dynamic> userUpdates = {
        if (profileImageUrl != null) 'avatar_url': profileImageUrl,
        'birthDate': date.toIso8601String(),
        'genero': _selectedGenero,
        'full_address': _fullAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'profile_completed': true,
        'status': 'Ativo',
      };

      await _authService.updateUserData(_user.id, userUpdates);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      debugPrint("Erro ao completar perfil: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete seu Perfil'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Olá, ${_user?.userMetadata?['nome'] ?? 'usuário'}!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                      prefixIcon: const Icon(Icons.location_city_outlined),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullAddressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço Completo (Rua, N°, Bairro)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (value) => _validateRequired(value, 'Endereço'),
                autovalidateMode: _autovalidateMode,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento*',
                  hintText: 'dd/MM/yyyy',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                inputFormatters: [_birthDateFormatter],
                validator: _validateBirthDate,
                autovalidateMode: _autovalidateMode,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGenero,
                decoration: const InputDecoration(
                  labelText: 'Gênero*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc_outlined),
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
                        backgroundColor: AppColors.primary,
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
