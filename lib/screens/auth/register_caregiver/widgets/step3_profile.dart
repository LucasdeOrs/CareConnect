// [COLE ESTE CÓDIGO INTEIRO EM: step3_profile.dart]

import 'dart:io'; // <-- ADICIONADO
import 'package:flutter/foundation.dart' show kIsWeb; // <-- ADICIONADO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // <-- ADICIONADO

class Step3Profile extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
  final ValueNotifier<bool> acceptTermsNotifier;

  // CAMPOS PARA A PRÉ-VISUALIZAÇÃO
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController experienceController;
  final TextEditingController yearsExperienceController;
  final ValueNotifier<List<String>> selectedSpecialtiesNotifier;
  final TextEditingController hourlyRateController;
  final TextEditingController availabilityController;
  final ValueNotifier<XFile?> profileImageNotifier; // <-- ADICIONADO

  const Step3Profile({
    super.key,
    required this.formKey,
    required this.autovalidateMode,
    required this.acceptTermsNotifier,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.cityController,
    required this.stateController,
    required this.experienceController,
    required this.yearsExperienceController,
    required this.selectedSpecialtiesNotifier,
    required this.hourlyRateController,
    required this.availabilityController,
    required this.profileImageNotifier, // <-- ADICIONADO
  });

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termos de Uso - Plataforma de Cuidadores de Idosos'),
        content: const SingleChildScrollView(
          child: Text(
            'Ao se cadastrar como cuidador nesta plataforma, você declara que leu, compreendeu e concorda com os seguintes termos:\n\n'
            '1. Veracidade das Informações:\n'
            'Declaro que todas as informações fornecidas neste cadastro são verdadeiras e de minha responsabilidade. Estou ciente de que qualquer informação falsa poderá acarretar na suspensão ou exclusão da minha conta.\n\n'
            '2. Conduta Profissional:\n'
            'Comprometo-me a manter uma conduta ética, respeitosa e profissional no atendimento aos contratantes, zelando pelo bem-estar e segurança dos idosos sob meus cuidados.\n\n'
            '3. Autorização de Uso de Dados:\n'
            'Autorizo a plataforma a utilizar meus dados pessoais e profissionais para fins de exibição no sistema, exclusivamente para fins de contratação e comunicação entre usuários.\n\n'
            '4. Responsabilidade Legal:\n'
            'Estou ciente de que a plataforma atua apenas como intermediadora entre cuidadores e familiares, não sendo responsável por eventuais condutas, ações ou omissões nos atendimentos realizados.\n\n'
            '5. Direito de Recusa:\n'
            'A plataforma reserva-se o direito de recusar cadastros que estejam em desacordo com os princípios éticos ou contenham informações incompletas ou incompatíveis com o serviço oferecido.\n\n'
            '6. Atualização de Informações:\n'
            'Comprometo-me a manter meus dados atualizados, especialmente em relação à disponibilidade, certificações e contato.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String? _validateTerms(bool? value) {
    if (value == null || !value) {
      return 'Você deve aceitar os termos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- CAMPO: TERMOS (Único campo de entrada aqui) ---
          ValueListenableBuilder<bool>(
            valueListenable: acceptTermsNotifier,
            builder: (context, isAccepted, child) {
              return FormField<bool>(
                initialValue: isAccepted,
                validator: _validateTerms,
                autovalidateMode: autovalidateMode,
                builder: (FormFieldState<bool> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isAccepted,
                            onChanged: (value) {
                              acceptTermsNotifier.value = value ?? false;
                              field.didChange(value);
                            },
                            side: field.hasError
                                ? BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                  )
                                : null,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showTerms(context),
                              child: const Text.rich(
                                TextSpan(
                                  text: 'Aceito os ',
                                  children: [
                                    TextSpan(
                                      text: 'termos da plataforma',
                                      style: TextStyle(
                                        color: Colors.indigo,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 48.0, top: 0.0),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),

          // --- ESPAÇAMENTO CORRIGIDO ---
          const SizedBox(height: 16), // <-- MUDADO DE 32
          const Divider(),
          const SizedBox(height: 16),

          // --- PRÉ-VISUALIZAÇÃO ---
          const Text(
            'Pré-visualização do Perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // --- CORREÇÃO DA FOTO DE PERFIL ---
                      ValueListenableBuilder<XFile?>(
                        valueListenable: profileImageNotifier,
                        builder: (context, imageFile, _) {
                          ImageProvider? backgroundImage;
                          if (imageFile != null) {
                            if (kIsWeb) {
                              backgroundImage = NetworkImage(imageFile.path);
                            } else {
                              backgroundImage = FileImage(File(imageFile.path));
                            }
                          }

                          return CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: backgroundImage,
                            child: (backgroundImage == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.grey,
                                  )
                                : null,
                          );
                        },
                      ),

                      // --- FIM DA CORREÇÃO ---
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameController.text.isNotEmpty
                                  ? nameController.text
                                  : 'Seu Nome',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                cityController,
                                stateController,
                              ]),
                              builder: (context, _) {
                                return Text(
                                  cityController.text.isNotEmpty &&
                                          stateController.text.isNotEmpty
                                      ? '${cityController.text}, ${stateController.text}'
                                      : 'Sua Cidade, UF',
                                  style: TextStyle(color: Colors.grey.shade600),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contato:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${phoneController.text} | ${emailController.text}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Experiência:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AnimatedBuilder(
                    animation: experienceController,
                    builder: (context, _) {
                      return Text(
                        experienceController.text.isNotEmpty
                            ? experienceController.text
                            : 'Sua descrição de experiência...',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tempo de Exp.:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            AnimatedBuilder(
                              animation: yearsExperienceController,
                              builder: (context, _) {
                                return Text(
                                  yearsExperienceController.text.isNotEmpty
                                      ? '${yearsExperienceController.text} anos'
                                      : 'N/A',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preço/Hora:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            AnimatedBuilder(
                              animation: hourlyRateController,
                              builder: (context, _) {
                                return Text(
                                  hourlyRateController.text.isNotEmpty
                                      ? 'R\$ ${hourlyRateController.text}'
                                      : 'N/A',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Disponibilidade:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AnimatedBuilder(
                    animation: availabilityController,
                    builder: (context, _) {
                      return Text(
                        availabilityController.text.isNotEmpty
                            ? availabilityController.text
                            : 'Nenhuma definida',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
