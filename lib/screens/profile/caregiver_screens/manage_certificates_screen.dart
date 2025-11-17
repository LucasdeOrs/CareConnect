import 'dart:io';
import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageCertificatesScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;
  const ManageCertificatesScreen({super.key, required this.caregiverProfile});

  @override
  State<ManageCertificatesScreen> createState() =>
      _ManageCertificatesScreenState();
}

class _ManageCertificatesScreenState extends State<ManageCertificatesScreen> {
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
      withData: kIsWeb,
    );

    if (result != null &&
        (result.files.single.path != null ||
            result.files.single.bytes != null)) {
      final file = result.files.single;
      final fileName = file.name;
      final filePath = '${widget.caregiverProfile.id}/certificates/$fileName';

      setState(() {
        _isLoading = true;
        _uploadingMessage = 'Enviando arquivo: $fileName...';
      });

      try {
        final fileBytes = kIsWeb
            ? file.bytes!
            : await File(file.path!).readAsBytes();

        await supabase.storage
            .from('certificates')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: file.extension != null
                    ? 'image/${file.extension}'
                    : 'application/pdf',
              ),
            );

        final publicUrl = supabase.storage
            .from('certificates')
            .getPublicUrl(filePath);

        final newCertificate = {'name': fileName, 'url': publicUrl};

        await _updateDatabase([..._certificates, newCertificate]);
      } on StorageException catch (e) {
        _showError('Erro de Storage: ${e.message}');
      } catch (e) {
        _showError('Erro ao enviar: $e');
      } finally {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      final path = url.split('/certificates/').last;

      await supabase.storage.from('certificates').remove([path]);

      final newList = List<Map<String, String>>.from(_certificates);
      newList.removeWhere((c) => c['url'] == url);

      await _updateDatabase(newList);
    } catch (e) {
      _showError('Erro ao excluir: $e');
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

        await _updateDatabase(newList);
      } catch (e) {
        _showError('Erro ao renomear: $e');
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
      validUrl = supabase.storage.from('certificates').getPublicUrl(url);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            FullScreenImageViewer(imageUrl: validUrl, title: name),
      ),
    );
  }

  Future<void> _updateDatabase(List<Map<String, String>> newList) async {
    await supabase
        .from('cuidadores')
        .update({'certificado_url': newList})
        .eq('id', widget.caregiverProfile.id);

    setState(() {
      _certificates = newList;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
        backgroundColor: _isLoading ? Colors.grey : Colors.indigo,
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
                ? const Center(
                    child: Text(
                      'Nenhum certificado enviado.\nToque no botão + para adicionar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
                            color: isPdf ? Colors.red : Colors.blue,
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
                                    Icon(Icons.visibility, size: 20),
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
                                    Icon(Icons.delete, size: 20),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
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

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.broken_image, color: Colors.white54, size: 50),
                  SizedBox(height: 8),
                  Text(
                    "Não foi possível carregar a imagem.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
