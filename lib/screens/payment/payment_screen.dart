import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/caregiver_profile.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String agendamentoId;
  final CaregiverProfile caregiver;

  const PaymentScreen({
    super.key,
    required this.agendamentoId,
    required this.caregiver,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();

  late TabController _tabController;
  Map<String, dynamic>? _agendamento;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAgendamento();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgendamento() async {
    try {
      final response = await _paymentService.fetchAppointmentDetails(
        widget.agendamentoId,
      );
      setState(() {
        _agendamento = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _processPayment() async {
    if (_agendamento == null) return;
    setState(() => _isProcessing = true);

    try {
      final valorBruto = (_agendamento!['valor_total'] as num).toDouble();

      final String metodoPagamento = _tabController.index == 0
          ? PaymentMethod.pix.dbValue
          : PaymentMethod.creditCard.dbValue;

      final updatedAgendamento = await _paymentService.processPayment(
        agendamentoId: widget.agendamentoId,
        recebedorId: widget.caregiver.id,
        valorBruto: valorBruto,
        metodo: metodoPagamento,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PaymentSuccessScreen(agendamento: updatedAgendamento),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = AppFormatters.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOrderSummary(currencyFormat),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: const [
                    Tab(icon: Icon(Icons.pix), text: 'PIX'),
                    Tab(
                      icon: Icon(Icons.credit_card),
                      text: 'Cartão de Crédito',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildPixTab(currencyFormat), _buildCardTab()],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading
          ? const SizedBox.shrink()
          : _buildPaymentButton(currencyFormat),
    );
  }

  Widget _buildOrderSummary(NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Pedido',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: widget.caregiver.avatarUrl != null
                    ? NetworkImage(widget.caregiver.avatarUrl!)
                    : null,
                child: widget.caregiver.avatarUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(widget.caregiver.nome),
              subtitle: Text(_agendamento!['tipo_servico']),
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Data',
              AppFormatters.date.format(
                DateTime.parse(_agendamento!['data_agendamento']),
              ),
            ),
            _buildInfoRow(
              Icons.access_time,
              'Horário',
              '${_agendamento!['hora_inicio']} às ${_agendamento!['hora_fim']}',
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Endereço',
              _agendamento!['endereco_local'],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(_agendamento!['valor_total']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPixTab(NumberFormat currencyFormat) {
    final pixCode =
        '00020126330014br.gov.bcb.pix0111${widget.caregiver.id}520400005303986540${(_agendamento!['valor_total'] as num).toStringAsFixed(2)}5802BR5913${widget.caregiver.nome}6009SAO PAULO62070503***6304C137';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Pague com PIX para confirmar seu agendamento. O pagamento é processado imediatamente.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: QrImageView(
              data: pixCode,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Código PIX'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código PIX (simulado) copiado!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Número do Cartão',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nome no Cartão',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Validade (MM/AA)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onPressed: _isProcessing ? null : _processPayment,
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Text(
                'Pagar ${currencyFormat.format(_agendamento!['valor_total'])}',
              ),
      ),
    );
  }
}
