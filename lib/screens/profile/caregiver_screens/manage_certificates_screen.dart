import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/home/widgets/caregiver_detail_modal.dart';
import 'package:careconnect_app/services/certificate_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ManageCertificatesScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;
  const ManageCertificatesScreen({super.key, required this.caregiverProfile});

  @override
  State<ManageCertificatesScreen> createState() =>
      _ManageCertificatesScreenState();
}

class _ManageCertificatesScreenState extends State<ManageCertificatesScreen> {
  final CertificateService _certificateService = CertificateService();

  late List<Map<String, String>> _certificates;
  bool _isLoading = false;
  String? _uploadingMessage;

  @override
  void initState() {
    super.initState();
    _certificates = List<Map<String, String>>.from(
      widget.caregiverProfile.certificados,
    );
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final fileName = file.name;

    setState(() {
      _isLoading = true;
      _uploadingMessage = 'Enviando arquivo: $fileName...';
    });

    try {
      final Map<String, String> newCertificate = await _certificateService
          .uploadCertificate(
            caregiverId: widget.caregiverProfile.id,
            fileName: fileName,
            fileBytes: file.bytes!,
            mimeType: null,
          );

      final newList = [..._certificates, newCertificate];
      await _certificateService.updateCertificateListInDatabase(
        caregiverId: widget.caregiverProfile.id,
        newList: newList,
      );

      setState(() {
        _certificates = newList;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificado enviado e salvo!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError(
        'Erro ao enviar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadingMessage = null;
        });
      }
    }
  }

  Future<void> _deleteCertificate(Map<String, String> certificate) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Certificado'),
        backgroundColor: Colors.white,
        content: Text(
          'Tem certeza que deseja excluir o certificado "${certificate['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ), // Cor
            child: const Text(
              'Sim, Excluir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    setState(() {
      _isLoading = true;
      _uploadingMessage = 'Excluindo ${certificate['name']}...';
    });

    try {
      final url = certificate['url']!;

      await _certificateService.deleteCertificate(
        caregiverId: widget.caregiverProfile.id,
        filePathInBucket: url,
        currentCertificates: _certificates,
      );

      setState(() {
        _certificates.removeWhere((c) => c['url'] == url);
      });
    } catch (e) {
      _showError(
        'Erro ao excluir: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadingMessage = null;
      });
    }
  }

  Future<void> _renameCertificate(
    Map<String, String> certificate,
    int index,
  ) async {
    final nameController = TextEditingController(text: certificate['name']);

    final novoNome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Certificado'),
        backgroundColor: Colors.white,
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Arquivo',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novoNome != null &&
        novoNome.isNotEmpty &&
        novoNome != certificate['name']) {
      setState(() {
        _isLoading = true;
        _uploadingMessage = 'Atualizando...';
      });

      try {
        final newList = List<Map<String, String>>.from(_certificates);
        newList[index] = {'name': novoNome, 'url': certificate['url']!};

        await _certificateService.updateCertificateListInDatabase(
          caregiverId: widget.caregiverProfile.id,
          newList: newList,
        );

        setState(() {
          _certificates = newList;
        });
      } catch (e) {
        _showError(
          'Erro ao renomear: ${e.toString().replaceAll('Exception: ', '')}',
        );
      } finally {
        setState(() {
          _isLoading = false;
          _uploadingMessage = null;
        });
      }
    }
  }

  void _showPreview(String url, String name) {
    String validUrl = url;
    if (!url.startsWith('http')) {
      validUrl = _certificateService.getPublicUrl(url);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            FullScreenImageViewer(imageUrl: validUrl, title: name),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Certificados'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _pickAndUploadFile,
        backgroundColor: _isLoading ? Colors.grey : AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Certificado',
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: Column(
        children: [
          if (_isLoading && _uploadingMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_uploadingMessage!, textAlign: TextAlign.center),
                ],
              ),
            ),
          Expanded(
            child: _certificates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum certificado enviado.\nToque no botão + para adicionar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _certificates.length,
                    itemBuilder: (context, index) {
                      final cert = _certificates[index];
                      final name = cert['name'] ?? 'Certificado sem nome';
                      final isPdf =
                          cert['url']?.toLowerCase().endsWith('.pdf') ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.image_rounded,
                            color: isPdf ? AppColors.error : AppColors.primary,
                            size: 32,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (_isLoading) return;
                              if (value == 'view') {
                                _showPreview(cert['url']!, name);
                              } else if (value == 'rename') {
                                _renameCertificate(cert, index);
                              } else if (value == 'delete') {
                                _deleteCertificate(cert);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 20,
                                      color: Colors.blueGrey,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Visualizar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Renomear'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
