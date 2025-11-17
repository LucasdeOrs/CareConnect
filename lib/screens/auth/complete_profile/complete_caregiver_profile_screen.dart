// [COLE ESTE CÓDIGO INTEIRO EM: complete_caregiver_profile_screen.dart]

import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step1_personal.dart';
import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step3_profile.dart';
import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../main.dart';
import '../register_caregiver/widgets/step2_professional.dart'
    show NamedCertificate, Step2Professional;
import '../login/login_screen.dart';

class CompleteCaregiverProfileScreen extends StatefulWidget {
  const CompleteCaregiverProfileScreen({super.key});

  @override
  State<CompleteCaregiverProfileScreen> createState() =>
      _CompleteCaregiverProfileScreenState();
}

class _CompleteCaregiverProfileScreenState
    extends State<CompleteCaregiverProfileScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  final User? _user = supabase.auth.currentUser;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Keys dos formulários
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // --- Controllers Step 1 (Dados Pessoais) ---
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _cidadeUFController = TextEditingController();
  final _cityController = TextEditingController(); // Interno
  final _stateController = TextEditingController(); // Interno
  final _selectedGeneroNotifier = ValueNotifier<String?>(null);
  final _profileImageNotifier = ValueNotifier<XFile?>(null);

  // --- Controllers Step 2 (Dados Profissionais) ---
  final _profissaoController = TextEditingController();
  final _formacaoSaudeNotifier = ValueNotifier<bool>(false);
  final _experienceController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _selectedSpecialtiesNotifier = ValueNotifier<List<String>>([]);
  final _certificateNotifier = ValueNotifier<List<NamedCertificate>>([]);
  final _hourlyRateController = TextEditingController();

  // --- Controllers de Disponibilidade (para Step 2) ---
  final _availabilityDaysNotifier = ValueNotifier<String?>(null);
  final _availabilityTimeNotifier = ValueNotifier<String?>(null);
  final _availabilityController = TextEditingController();

  // --- Controllers Step 3 (Perfil) ---
  final _acceptTermsNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _pageController.dispose();

    // Step 1
    _cpfController.dispose();
    _birthDateController.dispose();
    _fullAddressController.dispose();
    _cidadeUFController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _selectedGeneroNotifier.dispose();
    _profileImageNotifier.dispose();

    // Step 2
    _profissaoController.dispose();
    _formacaoSaudeNotifier.dispose();
    _experienceController.dispose();
    _yearsExperienceController.dispose();
    _selectedSpecialtiesNotifier.dispose();
    _certificateNotifier.dispose();
    _hourlyRateController.dispose();
    _availabilityDaysNotifier.dispose();
    _availabilityTimeNotifier.dispose();

    // Step 3
    _availabilityController.dispose();
    _acceptTermsNotifier.dispose();

    super.dispose();
  }

  void _nextPage() {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid = _formKeyStep1.currentState!.validate();
    } else if (_currentStep == 1) {
      isValid = _formKeyStep2.currentState!.validate();
    }

    if (isValid && _currentStep < 2) {
      if (_currentStep == 1) {
        final days = _availabilityDaysNotifier.value;
        final time = _availabilityTimeNotifier.value;

        if (days != null && time != null) {
          _availabilityController.text = '$days - $time';
        } else {
          _availabilityController.text = 'Disponibilidade não definida';
        }
      }

      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  void _previousPage() {
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  Future<void> _onBackPressed() async {
    if (_currentStep > 0) {
      _previousPage();
    } else {
      final didRequestSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair do Cadastro?'),
          content: const Text(
            'Seu progresso não será salvo. Deseja deslogar e voltar para o login?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        ),
      );

      if (didRequestSignOut == true) {
        await supabase.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    final avatarFile = _profileImageNotifier.value;
    if (avatarFile == null) return null;
    final fileExt = avatarFile.name.split('.').last.toLowerCase();
    final filePath = '$userId/profile.$fileExt';
    final fileBytes = await avatarFile.readAsBytes();
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: avatarFile.mimeType,
          ),
        );
    return supabase.storage.from('avatars').getPublicUrl(filePath);
  }

  Future<List<Map<String, String>>?> _uploadCertificates(String userId) async {
    final certificates = _certificateNotifier.value;
    if (certificates.isEmpty) return null;
    final List<Map<String, String>> certificateUrls = [];
    final bucketName = 'certificates';
    for (final NamedCertificate cert in certificates) {
      final safeFileName = cert.controller.text.trim().replaceAll(
        RegExp(r'[^a-zA-Z0-9.-]'),
        '_',
      );
      final certPath = '$userId/certificates/${safeFileName}_${cert.file.name}';
      if (kIsWeb) {
        if (cert.file.bytes == null) continue;
        await supabase.storage
            .from(bucketName)
            .uploadBinary(
              certPath,
              cert.file.bytes!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      } else {
        if (cert.file.path == null) continue;
        await supabase.storage
            .from(bucketName)
            .upload(
              certPath,
              File(cert.file.path!),
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      }
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(certPath);
      certificateUrls.add({
        'name': cert.controller.text.trim(),
        'url': publicUrl,
      });
    }
    return certificateUrls;
  }

  Future<void> _saveProfile() async {
    if (!_formKeyStep3.currentState!.validate()) {
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
      final String? avatarUrl = await _uploadAvatar(_user.id);
      final List<Map<String, String>>? certificateUrls =
          await _uploadCertificates(_user.id);

      final String? birthDate = _birthDateController.text.trim().isNotEmpty
          ? DateFormat(
              'dd/MM/yyyy',
              'pt_BR',
            ).parseStrict(_birthDateController.text.trim()).toIso8601String()
          : null;
      final String? genero = _selectedGeneroNotifier.value;
      final String fullAddress = _fullAddressController.text.trim();
      final parts = _cidadeUFController.text.split(', ');
      final String? city = parts.length == 2 ? parts[0].trim() : null;
      final String? state = parts.length == 2 ? parts[1].trim() : null;
      final String cpf = _cpfController.text.trim();

      final String experiencia = _experienceController.text.trim();
      final int experienceYears =
          int.tryParse(_yearsExperienceController.text.trim()) ?? 0;
      final String especialidades = _selectedSpecialtiesNotifier.value.join(
        ', ',
      );
      final String profissao = _profissaoController.text.trim();
      final bool formacaoSaude = _formacaoSaudeNotifier.value;
      final double hourlyRate =
          double.tryParse(
            _hourlyRateController.text.trim().replaceAll(',', '.'),
          ) ??
          0.0;
      final String availability = _availabilityController.text;

      await supabase
          .from('usuarios')
          .update({
            'birthDate': birthDate,
            'full_address': fullAddress,
            'city': city,
            'state': state,
            'genero': genero,
            'avatar_url': avatarUrl,
            'profile_completed': true,
            'status': 'Ativo',
          })
          .eq('id', _user.id);

      await supabase
          .from('cuidadores')
          .update({
            'cpf': cpf,
            'experiencia': experiencia,
            'especialidades': especialidades,
            'experience_years': experienceYears,
            'hourly_rate': hourlyRate,
            'availability': availability,
            'profissao': profissao,
            'formacao_saude': formacaoSaude,
            'certificado_url': certificateUrls,
            'approval_status': 'Pendente',
          })
          .eq('usuario_id', _user.id);

      await supabase.auth.updateUser(
        UserAttributes(
          data: {...?_user.userMetadata, 'profile_completed': true},
        ),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (error) {
      debugPrint("Erro geral ao completar perfil do cuidador: $error");
      String errorMessage = 'Erro inesperado ao salvar perfil.';
      if (error is PostgrestException) {
        errorMessage = 'Erro no banco: ${error.message} (Code: ${error.code})';
      } else {
        errorMessage = 'Erro: ${error.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
    final parts = _cidadeUFController.text.split(', ');
    _cityController.text = parts.length == 2 ? parts[0].trim() : '';
    _stateController.text = parts.length == 2 ? parts[1].trim() : '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Olá, ${_user?.userMetadata?['nome'] ?? 'Cuidador'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Faltam só mais alguns dados para ativar seu perfil.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    StepIndicator(currentStep: _currentStep),
                    const SizedBox(height: 32),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Step1Personal(
                            formKey: _formKeyStep1,
                            autovalidateMode: _autovalidateMode,
                            cpfController: _cpfController,
                            birthDateController: _birthDateController,
                            fullAddressController: _fullAddressController,
                            cidadeUFController: _cidadeUFController,
                            selectedGeneroNotifier: _selectedGeneroNotifier,
                            profileImageNotifier: _profileImageNotifier,
                          ),
                          Step2Professional(
                            formKey: _formKeyStep2,
                            autovalidateMode: _autovalidateMode,
                            profissaoController: _profissaoController,
                            formacaoSaudeNotifier: _formacaoSaudeNotifier,
                            experienceController: _experienceController,
                            yearsExperienceController:
                                _yearsExperienceController,
                            selectedSpecialtiesNotifier:
                                _selectedSpecialtiesNotifier,
                            certificateNotifier: _certificateNotifier,
                            hourlyRateController: _hourlyRateController,
                            availabilityDaysNotifier: _availabilityDaysNotifier,
                            availabilityTimeNotifier: _availabilityTimeNotifier,
                          ),
                          Step3Profile(
                            formKey: _formKeyStep3,
                            autovalidateMode: _autovalidateMode,
                            acceptTermsNotifier: _acceptTermsNotifier,

                            // Para a Pré-visualização
                            nameController: TextEditingController(
                              text: _user?.userMetadata?['nome'] ?? '',
                            ),
                            phoneController: TextEditingController(
                              text: _user?.userMetadata?['phoneNumber'] ?? '',
                            ),
                            emailController: TextEditingController(
                              text: _user?.email ?? '',
                            ),
                            cityController: _cityController,
                            stateController: _stateController,
                            experienceController: _experienceController,
                            yearsExperienceController:
                                _yearsExperienceController,
                            selectedSpecialtiesNotifier:
                                _selectedSpecialtiesNotifier,
                            hourlyRateController: _hourlyRateController,
                            availabilityController: _availabilityController,

                            // *** A MUDANÇA ESTÁ AQUI ***
                            profileImageNotifier: _profileImageNotifier,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        if (_currentStep == 2) {
                          _saveProfile();
                        } else {
                          _nextPage();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentStep == 2
                            ? 'Salvar e Enviar para Análise'
                            : 'Próximo Passo',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
