import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/services/report_service.dart';
import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  final String agendamentoId;
  final String cuidadorId;
  final String familiarId;

  const ReportDialog({
    super.key,
    required this.agendamentoId,
    required this.cuidadorId,
    required this.familiarId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _detalhesController = TextEditingController();
  bool _isLoading = false;

  final ReportService _reportService = ReportService();

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reportService.submitReport(
        agendamentoId: widget.agendamentoId,
        reporterId: widget.familiarId,
        reportedCuidadorId: widget.cuidadorId,
        motivo: _motivoController.text.trim(),
        detalhes: _detalhesController.text.trim(),
        anexosUrls: null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Denúncia enviada com sucesso.'),
            backgroundColor: AppColors.success,
          ),
        );
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
  void dispose() {
    _motivoController.dispose();
    _detalhesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar Cuidador'),
      backgroundColor: Colors.white,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo da Denúncia*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detalhesController,
                decoration: const InputDecoration(
                  labelText: 'Detalhes (o que aconteceu?)*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Anexar Fotos/Documentos'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Upload de arquivos será implementado futuramente.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar Denúncia'),
        ),
      ],
    );
  }
}
