import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/widgets/image_upload_widget.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditPersonalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditPersonalProfileScreen({super.key, required this.userData});

  @override
  State<EditPersonalProfileScreen> createState() =>
      _EditPersonalProfileScreenState();
}

class _EditPersonalProfileScreenState extends State<EditPersonalProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _estadoController;
  String? _generoSelecionado;
  String? _currentAvatarUrl;

  final _profileImageNotifier = ValueNotifier<XFile?>(null);
  final _imagePicker = ImagePicker();

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.userData['nome']);
    _telefoneController = TextEditingController(
      text: widget.userData['phoneNumber'],
    );
    _enderecoController = TextEditingController(
      text: widget.userData['full_address'],
    );
    _cidadeController = TextEditingController(text: widget.userData['city']);
    _estadoController = TextEditingController(text: widget.userData['state']);
    _generoSelecionado = widget.userData['genero'];
    _currentAvatarUrl = widget.userData['avatar_url'];
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _profileImageNotifier.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser!.id;

      String? newAvatarUrl;
      if (_profileImageNotifier.value != null) {
        newAvatarUrl = await _storageService.uploadAvatar(
          userId,
          _profileImageNotifier.value!,
        );
      }

      final Map<String, dynamic> userUpdates = {
        'nome': _nomeController.text.trim(),
        'phoneNumber': _telefoneController.text.trim(),
        'full_address': _enderecoController.text.trim(),
        'city': _cidadeController.text.trim(),
        'state': _estadoController.text.trim(),
        'genero': _generoSelecionado,
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      };

      await _authService.updateUserData(userId, userUpdates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Pessoal'),
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
              ImageUploadWidget(
                profileImageNotifier: _profileImageNotifier,
                imagePicker: _imagePicker,
                initialImageUrl: _currentAvatarUrl,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Nome não pode ser vazio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _generoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Gênero',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items:
                    ['Masculino', 'Feminino', 'Outro', 'Prefiro não informar']
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _generoSelecionado = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Endereço',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: 'Endereço Completo (Rua, N°, Bairro)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _estadoController,
                      decoration: const InputDecoration(
                        labelText: 'Estado (UF)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.save_outlined),
                label: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isLoading ? null : _updateProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
