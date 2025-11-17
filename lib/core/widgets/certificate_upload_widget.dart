import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/named_certificate_model.dart';

class CertificateUploadWidget extends StatelessWidget {
  final ValueNotifier<List<NamedCertificate>> uploadedCertificatesNotifier;
  final AutovalidateMode autovalidateMode;

  const CertificateUploadWidget({
    super.key,
    required this.uploadedCertificatesNotifier,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  Future<void> _pickCertificates(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newCertificates = result.files
            .where((file) => file.name.isNotEmpty)
            .map((file) {
              final fileName = file.name;
              final nameWithoutExtension = fileName.lastIndexOf('.') != -1
                  ? fileName.substring(0, fileName.lastIndexOf('.'))
                  : fileName;
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.files.length} certificado(s) adicionado(s).',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar arquivos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeCertificate(NamedCertificate certificate) {
    uploadedCertificatesNotifier.value = uploadedCertificatesNotifier.value
        .where((c) => c != certificate)
        .toList();
    certificate.dispose();
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
            child: Text('Upload de certificados (PDF, PNG, JPG)'),
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
                                    labelText: 'Nome do Certificado*',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (newName) => cert.name = newName,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nome obrigatório';
                                    }
                                    return null;
                                  },
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
