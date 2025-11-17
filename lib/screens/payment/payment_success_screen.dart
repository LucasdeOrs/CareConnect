import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> agendamento;

  const PaymentSuccessScreen({super.key, required this.agendamento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.success.shade700,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Pagamento Aprovado!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'O cuidador será notificado. Este é o seu código de confirmação para o dia do serviço:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.shade100),
                ),
                child: Text(
                  agendamento['codigo_confirmacao'] ?? 'ERRO',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Voltar para o Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
