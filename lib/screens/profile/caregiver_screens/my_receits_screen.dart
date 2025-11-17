import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/core/utils/app_formatters.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/profile/widgets/edit_pix_screen.dart';
import 'package:careconnect_app/services/financial_service.dart';
import 'package:flutter/material.dart';

class MeusRecebimentosScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;
  const MeusRecebimentosScreen({super.key, required this.caregiverProfile});

  @override
  State<MeusRecebimentosScreen> createState() => _MeusRecebimentosScreenState();
}

class _MeusRecebimentosScreenState extends State<MeusRecebimentosScreen> {
  final FinancialService _financialService = FinancialService();

  late Future<Map<String, dynamic>> _financialDataFuture;

  final _currencyFormat = AppFormatters.currency;
  final _dateFormat = AppFormatters.date;

  @override
  void initState() {
    super.initState();
    _financialDataFuture = _fetchFinancialData();
  }

  Future<Map<String, dynamic>> _fetchFinancialData() async {
    try {
      return await _financialService.fetchCaregiverFinancialData(
        widget.caregiverProfile.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      throw Exception('Falha ao carregar dados financeiros.');
    }
  }

  void _navigateToEditPix(String? currentType, String? currentKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPixScreen(
          caregiverProfile: widget.caregiverProfile,
          currentPixType: currentType,
          currentPixKey: currentKey,
        ),
      ),
    ).then((_) {
      setState(() {
        _financialDataFuture = _fetchFinancialData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Recebimentos'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _financialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final String? pixType = data['pix_key_type'];
          final String? pixKey = data['pix_key'];
          final double saldoDisponivel = data['saldo_disponivel'];
          final double saldoPendente = data['saldo_pendente'];
          final List<dynamic> payments = data['payments'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _financialDataFuture = _fetchFinancialData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSummaryCard(saldoDisponivel, saldoPendente),
                const SizedBox(height: 20),
                _buildPixCard(pixType, pixKey),
                const SizedBox(height: 20),
                Text(
                  'Histórico de Transações',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),
                _buildTransactionList(payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double disponivel, double pendente) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildBalanceRow(
              'Saldo Disponível para Saque',
              disponivel,
              AppColors.success.shade700,
            ),
            const Divider(height: 24),
            _buildBalanceRow(
              'Saldo Pendente',
              pendente,
              AppColors.warning.shade700,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.downloading),
                label: const Text('Solicitar Saque'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: disponivel > 0
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Função em desenvolvimento!'),
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(
    String title,
    double value,
    Color color, {
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: isLarge ? 16 : 14)),
        Text(
          _currencyFormat.format(value),
          style: TextStyle(
            fontSize: isLarge ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPixCard(String? pixType, String? pixKey) {
    final bool pixConfigurado = pixType != null && pixKey != null;

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pixConfigurado ? Icons.pix : Icons.warning_amber_rounded,
                  color: pixConfigurado ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Text(
                  'Conta de Recebimento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            if (pixConfigurado)
              Text(
                'Chave: $pixKey ($pixType)',
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                'Nenhum dado PIX cadastrado.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _navigateToEditPix(pixType, pixKey),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: Text(
                pixConfigurado ? 'Alterar Dados PIX' : 'Cadastrar PIX',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<dynamic> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            'Nenhuma transação encontrada.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];

        final agendamento = payment['agendamento'] ?? {};
        final familiar = agendamento['familiar'] ?? {};
        final nomeFamiliar = familiar['nome'] ?? 'Familiar';

        final statusString = payment['status_pagamento'] ?? 'desconhecido';
        final status = PaymentStatus.fromString(statusString);

        final valor = (payment['valor_liquido_recebedor'] ?? 0).toDouble();
        final data = DateTime.parse(payment['created_at']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Icon(status.icon, color: status.color),
            title: Text(
              _currencyFormat.format(valor),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'De: $nomeFamiliar\nData: ${_dateFormat.format(data)}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
