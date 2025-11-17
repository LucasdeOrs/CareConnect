import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/models/named_certificate_model.dart';
import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step1_personal.dart';
import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step3_profile.dart';
import 'package:careconnect_app/screens/auth/register_caregiver/widgets/step_indicator.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/caregiver_service.dart';
import 'package:careconnect_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../register_caregiver/widgets/step2_professional.dart';
import '../login/login_screen.dart';

class CompleteCaregiverProfileScreen extends StatefulWidget {
  const CompleteCaregiverProfileScreen({super.key});

  @override
  State<CompleteCaregiverProfileScreen> createState() =>
      _CompleteCaregiverProfileScreenState();
}

class _CompleteCaregiverProfileScreenState
    extends State<CompleteCaregiverProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final CaregiverService _caregiverService = CaregiverService();

  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  late final User? _user = _authService.currentUser;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _cidadeUFController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _selectedGeneroNotifier = ValueNotifier<String?>(null);
  final _profileImageNotifier = ValueNotifier<XFile?>(null);
  final _profissaoController = TextEditingController();
  final _formacaoSaudeNotifier = ValueNotifier<bool>(false);
  final _experienceController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _selectedSpecialtiesNotifier = ValueNotifier<List<String>>([]);
  final _certificateNotifier = ValueNotifier<List<NamedCertificate>>([]);
  final _hourlyRateController = TextEditingController();
  final _availabilityDaysNotifier = ValueNotifier<String?>(null);
  final _availabilityTimeNotifier = ValueNotifier<String?>(null);
  final _availabilityController = TextEditingController();
  final _acceptTermsNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _pageController.dispose();

    _cpfController.dispose();
    _birthDateController.dispose();
    _fullAddressController.dispose();
    _cidadeUFController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _selectedGeneroNotifier.dispose();
    _profileImageNotifier.dispose();

    _profissaoController.dispose();
    _formacaoSaudeNotifier.dispose();
    _experienceController.dispose();
    _yearsExperienceController.dispose();
    _selectedSpecialtiesNotifier.dispose();
    for (var cert in _certificateNotifier.value) {
      cert.dispose();
    }
    _certificateNotifier.dispose();
    _hourlyRateController.dispose();
    _availabilityDaysNotifier.dispose();
    _availabilityTimeNotifier.dispose();

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
          _availabilityController.text = '$days, $time';
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
          backgroundColor: Colors.white,
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
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        ),
      );

      if (didRequestSignOut == true) {
        try {
          await _authService.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }
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
      final String? avatarUrl = _profileImageNotifier.value != null
          ? await _storageService.uploadAvatar(
              _user.id,
              _profileImageNotifier.value!,
            )
          : null;

      final List<Map<String, String>>? certificateUrls = await _storageService
          .uploadCertificates(_user.id, _certificateNotifier.value);

      final String? birthDate = _birthDateController.text.trim().isNotEmpty
          ? DateFormat(
              'dd/MM/yyyy',
              'pt_BR',
            ).parseStrict(_birthDateController.text.trim()).toIso8601String()
          : null;
      final parts = _cidadeUFController.text.split(', ');
      final String? city = parts.length == 2 ? parts[0].trim() : null;
      final String? state = parts.length == 2 ? parts[1].trim() : null;

      final Map<String, dynamic> userData = {
        'birthDate': birthDate,
        'full_address': _fullAddressController.text.trim(),
        'city': city,
        'state': state,
        'genero': _selectedGeneroNotifier.value,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'profile_completed': true,
        'status': 'Ativo',
      };

      final double hourlyRate =
          double.tryParse(
            _hourlyRateController.text.trim().replaceAll(',', '.'),
          ) ??
          0.0;

      final Map<String, dynamic> caregiverData = {
        'cpf': _cpfController.text.trim(),
        'experiencia': _experienceController.text.trim(),
        'especialidades': _selectedSpecialtiesNotifier.value.join(','),
        'experience_years':
            int.tryParse(_yearsExperienceController.text.trim()) ?? 0,
        'hourly_rate': hourlyRate,
        'availability': _availabilityController.text,
        'profissao': _profissaoController.text.trim(),
        'formacao_saude': _formacaoSaudeNotifier.value,
        if (certificateUrls != null) 'certificado_url': certificateUrls,
        'approval_status': 'Pendente',
      };

      await _caregiverService.updateProfile(_user.id, caregiverData);

      await _authService.updateUserData(_user.id, userData);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (error) {
      debugPrint("Erro geral ao completar perfil do cuidador: $error");
      String errorMessage = error.toString().replaceAll('Exception: ', '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
                        backgroundColor: AppColors.primary,
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
