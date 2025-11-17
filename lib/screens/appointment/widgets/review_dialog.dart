import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/services/review_service.dart';
import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  final String agendamentoId;
  final String cuidadorId;
  final String familiarId;
  final VoidCallback onSubmitted;

  const ReviewDialog({
    super.key,
    required this.agendamentoId,
    required this.cuidadorId,
    required this.familiarId,
    required this.onSubmitted,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final ReviewService _reviewService = ReviewService();

  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _currentRating = 0;
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_currentRating == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione uma nota (1 a 5 estrelas).'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reviewService.submitReview(
        agendamentoId: widget.agendamentoId,
        cuidadorId: widget.cuidadorId,
        familiarId: widget.familiarId,
        nota: _currentRating,
        comentario: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada com sucesso! Obrigado.'),
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
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return IconButton(
          onPressed: () {
            setState(() {
              _currentRating = starNumber;
            });
          },
          icon: Icon(
            _currentRating >= starNumber ? Icons.star : Icons.star_border,
            size: 36,
          ),
          color: AppColors.warning,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Avalie o Serviço')),
      backgroundColor: Colors.white,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Sua opinião é muito importante!\nPor favor, deixe sua nota:',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              _buildStarRating(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                child: Text(
                  'Comentário (Opcional):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
                maxLength: 255,
                maxLines: 4,
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
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
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
              : const Text('Enviar Avaliação'),
        ),
      ],
    );
  }
}
