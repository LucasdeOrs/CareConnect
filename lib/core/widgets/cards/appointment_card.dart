import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/patient_model.dart';
import 'package:careconnect_app/models/user_model.dart';
import 'package:careconnect_app/screens/chat/chat_screen.dart';
import 'package:careconnect_app/screens/payment/payment_screen.dart';
import 'package:careconnect_app/services/appointment_service.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:careconnect_app/services/chat_service.dart';
import 'package:careconnect_app/services/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment_model.dart';
import '../../../models/caregiver_profile.dart';
import '../../../screens/appointment/widgets/report_dialog.dart';
import '../../../screens/appointment/widgets/review_dialog.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentDetails agendamento;
  final String userType;
  final Function(String newStatus) onUpdateStatus;
  final VoidCallback onReviewSubmitted;

  final PatientService _patientService = PatientService();
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();

  AppointmentCard({
    super.key,
    required this.agendamento,
    required this.userType,
    required this.onUpdateStatus,
    required this.onReviewSubmitted,
  });

  void _showChangePatientDialog(BuildContext context) async {
    List<Map<String, dynamic>> patients = [];
    try {
      patients = await _patientService.getSimplePatients(
        agendamento.familiarId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

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
                        await _appointmentService.updateAppointmentPatient(
                          agendamento.id,
                          localSelectedId!,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Paciente atualizado!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          onReviewSubmitted();
                        }
                      } catch (e) {
                        debugPrint('Erro ao trocar paciente: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
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
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

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
              currentUserId: currentUser.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
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
                        backgroundColor: AppColors.error,
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
        content: const Text('Deseja recusar? O familiar será notificado.'),
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
              backgroundColor: AppColors.error,
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
        content: const Text(
          'Deseja cancelar? Se o pagamento foi efetuado, o valor será estornado.',
        ),
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
              backgroundColor: AppColors.error,
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
        content: const Text(
          'Deseja cancelar? Se o pagamento foi efetuado, você será reembolsado.',
        ),
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
              backgroundColor: AppColors.error,
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
    final UserModel otherUser = (userType == 'cuidador')
        ? agendamento.familiar
        : agendamento.cuidador;

    final currencyFormat = AppFormatters.currency;
    final dateFormat = AppFormatters.date;

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

    final bool isServiceActive =
        agendamento.status == AppointmentStatus.pago ||
        agendamento.status == AppointmentStatus.confirmado;

    final bool isCaregiverReadyToFinalize =
        (userType == 'cuidador' && isServiceActive && isServiceDayOrLater);

    final bool isFamiliarPendingPayment =
        (userType == 'familiar' &&
        agendamento.status == AppointmentStatus.aguardandoPagamento);

    final bool isCaregiverPending =
        (userType == 'cuidador' &&
        agendamento.status == AppointmentStatus.pendenteAceite);

    final bool isCaregiverCanCancelAcceptance =
        (userType == 'cuidador' && isServiceActive && !isServiceDayOrLater);

    final bool isFamiliarShowCode = (userType == 'familiar' && isServiceActive);

    final bool isFamiliarCanCancel =
        (userType == 'familiar' &&
        (isServiceActive ||
            agendamento.status == AppointmentStatus.aguardandoPagamento ||
            agendamento.status == AppointmentStatus.pendenteAceite) &&
        canCancelTimeLimit);

    final bool isFinished =
        (agendamento.status == AppointmentStatus.concluido ||
        agendamento.status == AppointmentStatus.recusado ||
        agendamento.status == AppointmentStatus.cancelado);

    final bool isFamiliarCanReview =
        (userType == 'familiar' &&
        agendamento.status == AppointmentStatus.concluido &&
        !agendamento.avaliado);

    final bool isFamiliarCanChangePatient =
        (userType == 'familiar' &&
        (agendamento.status == AppointmentStatus.aguardandoPagamento ||
            agendamento.status == AppointmentStatus.pendenteAceite));

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

            if (isCaregiverReadyToFinalize)
              _buildFinalizeServiceButton(context),

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
    PatientModel paciente, {
    bool canEdit = false,
    bool canViewDetails = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary.shade100,
            child: const Icon(
              Icons.person_outline,
              color: AppColors.secondary,
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
                    color: AppColors.secondary,
                  ),
                ),
                if (paciente.idade != null)
                  Text(
                    '${paciente.idade} anos',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary.shade900,
                    ),
                  ),
                if (paciente.condicoes != null &&
                    paciente.condicoes!.isNotEmpty)
                  Text(
                    paciente.condicoes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppColors.secondary,
                size: 20,
              ),
              tooltip: 'Trocar Paciente',
              onPressed: () => _showChangePatientDialog(context),
            ),
          if (canViewDetails)
            IconButton(
              icon: const Icon(
                Icons.info_outline,
                color: AppColors.secondary,
                size: 20,
              ),
              tooltip: 'Ver Detalhes e Rotina',
              onPressed: () => _showPatientDetailsDialog(context),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel otherUser) {
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
            (agendamento.status == AppointmentStatus.confirmado ||
                agendamento.status == AppointmentStatus.concluido ||
                agendamento.status == AppointmentStatus.cancelado ||
                agendamento.status == AppointmentStatus.pago))
          _buildReportButton(context),
        if (agendamento.status == AppointmentStatus.pago ||
            agendamento.status == AppointmentStatus.confirmado ||
            agendamento.status == AppointmentStatus.concluido)
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
            backgroundColor: AppColors.success.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            if (agendamento.rawCaregiverData == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro: Dados do cuidador não encontrados.'),
                  backgroundColor: AppColors.error,
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
              agendamento.status.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: agendamento.status.color,
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
                color: AppColors.success,
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
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Recusar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  onUpdateStatus(AppointmentStatus.aguardandoPagamento.dbValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success.shade700,
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
            backgroundColor: AppColors.primary,
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
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
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
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.shade100),
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
                color: AppColors.primary,
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
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
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
      icon: Icon(Icons.warning_amber_rounded, color: AppColors.error.shade700),
      tooltip: 'Reportar Cuidador',
      onPressed: () {
        _showReportDialog(context);
      },
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: AppColors.primary,
      ),
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
            backgroundColor: AppColors.warning.shade700,
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
