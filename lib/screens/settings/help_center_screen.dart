import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Ajuda'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FAQItem(
            question: 'Como funcionam os pagamentos?',
            answer:
                'Os pagamentos são feitos via PIX ou Cartão de Crédito. O valor fica retido na plataforma e só é liberado para o cuidador após a conclusão do serviço e a confirmação do código de segurança.',
          ),
          _FAQItem(
            question: 'Como cancelar um agendamento?',
            answer:
                'Vá até a aba "Agendamentos", encontre o serviço desejado e clique no botão "Cancelar". Se feito com antecedência (24h), o reembolso é integral.',
          ),
          _FAQItem(
            question: 'O que é o Código de Confirmação?',
            answer:
                'É um código de segurança de 5 dígitos que aparece no card do agendamento do Familiar. Ele deve ser informado ao Cuidador apenas ao final do serviço para liberar o pagamento.',
          ),
          _FAQItem(
            question: 'Como denuncio um comportamento inadequado?',
            answer:
                'No card do agendamento ou no perfil do usuário, clique no ícone de alerta (triângulo com exclamação). Nossa equipe analisará o caso imediatamente.',
          ),
          _FAQItem(
            question: 'Como recebo pelas minhas horas trabalhadas?',
            answer:
                'Cadastre sua chave PIX na tela "Meus Recebimentos" dentro do seu Perfil. Após finalizar o serviço, o valor ficará disponível para solicitação de saque.',
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        collapsedIconColor: AppColors.primary,
        iconColor: AppColors.primary,
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
