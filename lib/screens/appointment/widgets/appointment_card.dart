import 'package:careconnect_app/screens/chat/chat_screen.dart';
import 'package:careconnect_app/screens/payment/payment_screen.dart';
import 'package:careconnect_app/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../main.dart';
import '../../../models/appointment_model.dart';
import '../../../models/caregiver_profile.dart';
import 'report_dialog.dart';
import 'review_dialog.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentDetails agendamento;
  final String userType;
  final Function(String newStatus) onUpdateStatus;
  final VoidCallback onReviewSubmitted;

  const AppointmentCard({
    super.key,
    required this.agendamento,
    required this.userType,
    required this.onUpdateStatus,
    required this.onReviewSubmitted,
  });

  void _showChangePatientDialog(BuildContext context) async {
    final response = await supabase
        .from('pacientes')
        .select('id, nome')
        .eq('familiar_id', agendamento.familiarId)
        .order('nome', ascending: true);

    final List<Map<String, dynamic>> patients = List<Map<String, dynamic>>.from(
      response,
    );

    String? selectedId = agendamento.paciente?.id;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        String? localSelectedId = selectedId;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Trocar Paciente'),
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Selecione quem receberá o cuidado:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: localSelectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: patients.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['nome']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => localSelectedId = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (localSelectedId != null &&
                        localSelectedId != agendamento.paciente?.id) {
                      try {
                        await supabase
                            .from('agendamentos')
                            .update({'paciente_id': localSelectedId})
                            .eq('id', agendamento.id);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Paciente atualizado!'),
                            ),
                          );
                          onReviewSubmitted();
                        }
                      } catch (e) {
                        debugPrint('Erro ao trocar paciente: $e');
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      final familiarId = agendamento.familiarId;
      final cuidadorId = agendamento.cuidadorId;

      final conversaId = await ChatService.startConversation(
        familiarId: familiarId,
        cuidadorId: cuidadorId,
      );

      final otherUserName = (userType == 'cuidador')
          ? agendamento.familiar.nome
          : agendamento.cuidador.nome;

      final otherUserAvatar = (userType == 'cuidador')
          ? agendamento.familiar.avatarUrl
          : agendamento.cuidador.avatarUrl;

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversaId: conversaId,
              otherUserName: otherUserName,
              otherUserAvatar: otherUserAvatar,
              currentUserId: supabase.auth.currentUser!.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPatientDetailsDialog(BuildContext context) {
    if (agendamento.paciente == null) return;
    final p = agendamento.paciente!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.nome),
        backgroundColor: Colors.white,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Idade:', '${p.idade ?? "N/A"} anos'),
              const SizedBox(height: 12),
              _buildDetailItem('Condições:', p.condicoes ?? 'Nenhuma'),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Rotina / Observações:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                (p.observacoes != null && p.observacoes!.isNotEmpty)
                    ? p.observacoes!
                    : 'Nenhuma observação informada.',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _showFinalizeDialog(BuildContext context) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Finalizar Serviço'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Por favor, peça ao familiar o código de 5 dígitos.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 5,
                  validator: (v) => v!.length < 5 ? 'Inválido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (codeController.text == agendamento.codigoConfirmacao) {
                    Navigator.pop(context);
                    onUpdateStatus('concluido');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código incorreto!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showRecusarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Agendamento'),
        content: const Text('Deseja recusar? O familiar será reembolsado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdateStatus('recusado');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Recusar'),
          ),
        ],
      ),
    );
  }

  void _showCancelAcceptanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Aceite'),
        content: const Text('Deseja cancelar? O valor será estornado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdateStatus('cancelado');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showFamiliarCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: const Text('Deseja cancelar? Você será reembolsado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdateStatus('cancelado');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        agendamentoId: agendamento.id,
        cuidadorId: agendamento.cuidadorId,
        familiarId: agendamento.familiarId,
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReviewDialog(
        agendamentoId: agendamento.id,
        cuidadorId: agendamento.cuidadorId,
        familiarId: agendamento.familiarId,
        onSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SimpleUser otherUser = (userType == 'cuidador')
        ? agendamento.familiar
        : agendamento.cuidador;

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    final now = DateTime.now();
    final agendamentoData = agendamento.dataAgendamento;
    final agendamentoStartDateTime = DateTime(
      agendamentoData.year,
      agendamentoData.month,
      agendamentoData.day,
      agendamento.horaInicio.hour,
      agendamento.horaInicio.minute,
    );

    final bool isServiceDayOrLater = agendamentoData.isBefore(
      DateTime(now.year, now.month, now.day + 1),
    );
    final bool canCancelTimeLimit = agendamentoStartDateTime.isAfter(
      now.add(const Duration(hours: 1)),
    );

    final bool isFamiliarPendingPayment =
        (userType == 'familiar' &&
        agendamento.status == 'aguardando_pagamento');
    final bool isCaregiverPending =
        (userType == 'cuidador' && agendamento.status == 'pago');
    final bool isCaregiverConfirmed =
        (userType == 'cuidador' &&
        agendamento.status == 'confirmado' &&
        isServiceDayOrLater);
    final bool isCaregiverCanCancelAcceptance =
        (userType == 'cuidador' &&
        agendamento.status == 'confirmado' &&
        !isServiceDayOrLater);
    final bool isFamiliarShowCode =
        (userType == 'familiar' &&
        (agendamento.status == 'pago' || agendamento.status == 'confirmado'));
    final bool isFamiliarCanCancel =
        (userType == 'familiar' &&
        (agendamento.status == 'aguardando_pagamento' ||
            agendamento.status == 'pago' ||
            agendamento.status == 'confirmado') &&
        canCancelTimeLimit);
    final bool isFinished =
        (agendamento.status == 'concluido' ||
        agendamento.status == 'recusado' ||
        agendamento.status == 'cancelado');
    final bool isFamiliarCanReview =
        (userType == 'familiar' &&
        agendamento.status == 'concluido' &&
        !agendamento.avaliado);
    final bool isFamiliarCanChangePatient =
        (userType == 'familiar' &&
        (agendamento.status == 'aguardando_pagamento' ||
            agendamento.status == 'pago'));

    return Card(
      elevation: 1,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, otherUser),

            if (agendamento.paciente != null) ...[
              const SizedBox(height: 12),
              _buildPatientInfo(
                context,
                agendamento.paciente!,
                canEdit: isFamiliarCanChangePatient,
                canViewDetails: userType == 'cuidador',
              ),
            ],

            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              dateFormat.format(agendamento.dataAgendamento),
            ),
            _buildInfoRow(
              Icons.access_time,
              '${agendamento.horaInicio.format(context)} às ${agendamento.horaFim.format(context)}',
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              agendamento.enderecoLocal,
            ),
            _buildInfoRow(
              Icons.medical_services_outlined,
              agendamento.tipoServico,
            ),
            const Divider(height: 24),
            _buildStatusAndPrice(context, currencyFormat),

            if (isCaregiverPending) _buildCaregiverActions(context),
            if (isCaregiverConfirmed) _buildFinalizeServiceButton(context),
            if (isCaregiverCanCancelAcceptance)
              _buildCaregiverCancelAcceptanceButton(context),
            if (isFamiliarShowCode) _buildConfirmationCode(context, isFinished),
            if (isFamiliarPendingPayment) _buildFinishPaymentButton(context),
            if (isFamiliarCanCancel) _buildFamiliarCancelButton(context),
            if (isFamiliarCanReview) _buildReviewButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo(
    BuildContext context,
    SimplePatient paciente, {
    bool canEdit = false,
    bool canViewDetails = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.teal.shade100,
            child: const Icon(
              Icons.person_outline,
              color: Colors.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paciente: ${paciente.nome}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                if (paciente.idade != null)
                  Text(
                    '${paciente.idade} anos',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
                  ),
                if (paciente.condicoes != null &&
                    paciente.condicoes!.isNotEmpty)
                  Text(
                    paciente.condicoes!,
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
              tooltip: 'Trocar Paciente',
              onPressed: () => _showChangePatientDialog(context),
            ),
          if (canViewDetails)
            IconButton(
              icon: const Icon(
                Icons.info_outline,
                color: Colors.teal,
                size: 20,
              ),
              tooltip: 'Ver Detalhes e Rotina',
              onPressed: () => _showPatientDetailsDialog(context),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SimpleUser otherUser) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: otherUser.avatarUrl != null
              ? NetworkImage(otherUser.avatarUrl!)
              : null,
          child: otherUser.avatarUrl == null
              ? const Icon(Icons.person, size: 25)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userType == 'cuidador' ? 'Solicitação de:' : 'Serviço com:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                otherUser.nome,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (userType == 'familiar' &&
            (agendamento.status == 'confirmado' ||
                agendamento.status == 'concluido' ||
                agendamento.status == 'cancelado' ||
                agendamento.status == 'pago'))
          _buildReportButton(context),
        if (agendamento.status == 'pago' ||
            agendamento.status == 'confirmado' ||
            agendamento.status == 'concluido')
          _buildChatButton(context),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildFinishPaymentButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.payment),
          label: const Text('Concluir Pagamento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            if (agendamento.rawCaregiverData == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro: Dados do cuidador não encontrados.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final caregiverProfile = CaregiverProfile.fromSupabase(
              agendamento.rawCaregiverData!,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  agendamentoId: agendamento.id,
                  caregiver: caregiverProfile,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'aguardando_pagamento':
        return 'AGUARDANDO PAGAMENTO';
      case 'pago':
        return 'AGUARDANDO ACEITE';
      case 'confirmado':
        return 'CONFIRMADO';
      case 'concluido':
        return 'CONCLUÍDO';
      case 'recusado':
        return 'RECUSADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aguardando_pagamento':
      case 'pago':
        return Colors.orange.shade700;
      case 'confirmado':
        return Colors.blue.shade700;
      case 'concluido':
        return Colors.green.shade700;
      case 'recusado':
      case 'cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildStatusAndPrice(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status:', style: Theme.of(context).textTheme.bodySmall),
            Text(
              _getStatusText(agendamento.status),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(agendamento.status),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Valor:', style: Theme.of(context).textTheme.bodySmall),
            Text(
              currencyFormat.format(agendamento.valorTotal),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaregiverActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRecusarDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Recusar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onUpdateStatus('confirmado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceitar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeServiceButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Finalizar Serviço'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            _showFinalizeDialog(context);
          },
        ),
      ),
    );
  }

  Widget _buildCaregiverCancelAcceptanceButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.cancel_schedule_send_outlined),
          label: const Text('Cancelar Aceite'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            _showCancelAcceptanceDialog(context);
          },
        ),
      ),
    );
  }

  Widget _buildConfirmationCode(BuildContext context, bool isFinished) {
    if (isFinished) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            const Text(
              'Código de Confirmação',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mostre este código ao cuidador no final do serviço.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              agendamento.codigoConfirmacao,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamiliarCancelButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar Agendamento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            _showFamiliarCancelDialog(context);
          },
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
      tooltip: 'Reportar Cuidador',
      onPressed: () {
        _showReportDialog(context);
      },
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.indigo),
      tooltip: 'Abrir Chat',
      onPressed: () => _openChat(context),
    );
  }

  Widget _buildReviewButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.star_half_rounded),
          label: const Text('Avalie o Serviço'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            _showReviewDialog(context);
          },
        ),
      ),
    );
  }
}
