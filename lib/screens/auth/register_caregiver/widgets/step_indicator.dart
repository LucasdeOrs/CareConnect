import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  const StepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildStep(context, '1', 'Dados\nPessoais', 0),
        ),
        Expanded(child: _buildLine(context, 0)),
        Expanded(
          flex: 2,
          child: _buildStep(context, '2', 'Informações Profissionais', 1),
        ),
        Expanded(child: _buildLine(context, 1)),
        Expanded(flex: 2, child: _buildStep(context, '3', 'Perfil', 2)),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String label,
    int stepIndex,
  ) {
    final bool isActive = currentStep == stepIndex;
    final bool isCompleted = currentStep > stepIndex;
    final color = isActive || isCompleted
        ? AppColors.primary
        : Colors.grey.shade400;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(BuildContext context, int stepIndex) {
    final bool isCompleted = currentStep > stepIndex;
    return Container(
      height: 2,
      color: isCompleted ? AppColors.primary : Colors.grey.shade400,
      margin: const EdgeInsets.only(top: 16.0),
    );
  }
}
