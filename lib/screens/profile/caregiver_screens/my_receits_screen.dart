// lib/screens/profile/meus_recebimentos_screen.dart

import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/screens/profile/widgets/edit_pix_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeusRecebimentosScreen extends StatefulWidget {
  final CaregiverProfile caregiverProfile;
  const MeusRecebimentosScreen({super.key, required this.caregiverProfile});

  @override
  State<MeusRecebimentosScreen> createState() => _MeusRecebimentosScreenState();
}

class _MeusRecebimentosScreenState extends State<MeusRecebimentosScreen> {
  late Future<Map<String, dynamic>> _financialDataFuture;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _financialDataFuture = _fetchFinancialData();
  }

  Future<Map<String, dynamic>> _fetchFinancialData() async {
    // ... (busca no Supabase não muda) ...
    final pixData = await supabase
        .from('cuidadores')
        .select('pix_key_type, pix_key')
        .eq('id', widget.caregiverProfile.id)
        .single();
    final payments = await supabase
        .from('pagamentos')
        .select(
          'valor_liquido_recebedor, status_pagamento, created_at, agendamento:agendamento_id(familiar:familiar_id(nome))',
        )
        .eq('recebedor_id', widget.caregiverProfile.id)
        .order('created_at', ascending: false);

    // 3. Calcula os saldos (COM A CORREÇÃO)
    double saldoDisponivel = 0.0;
    double saldoPendente = 0.0;

    for (var p in payments) {
      final status = p['status_pagamento'];
      final valor = (p['valor_liquido_recebedor'] as num).toDouble();

      // ### CORREÇÃO AQUI ###
      // Trocamos 'disponivel' por 'sucedido'
      if (status == 'sucedido') {
        saldoDisponivel += valor;
      } else if (status == 'processando') {
        saldoPendente += valor;
      }
      // 'pago' ou 'cancelado' não entram em nenhum saldo
    }

    return {
      'pix_key_type': pixData['pix_key_type'],
      'pix_key': pixData['pix_key'],
      'payments': payments,
      'saldo_disponivel': saldoDisponivel,
      'saldo_pendente': saldoPendente,
    };
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
      // Recarrega os dados quando a tela de edição for fechada
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
              Colors.green.shade700,
            ),
            const Divider(height: 24),
            _buildBalanceRow(
              'Saldo Pendente',
              pendente,
              Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.downloading),
                label: const Text('Solicitar Saque'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: disponivel > 0
                    ? () {
                        // TODO: Implementar lógica de solicitação de saque
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
                  color: pixConfigurado ? Colors.green : Colors.orange,
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
        final status = payment['status_pagamento'] ?? 'desconhecido';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: _getStatusIcon(status),
            title: Text(
              _currencyFormat.format(payment['valor_liquido_recebedor'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'De: $nomeFamiliar\nData: ${_dateFormat.format(DateTime.parse(payment['created_at']))}',
            ),
            trailing: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  // lib/screens/profile/meus_recebimentos_screen.dart

  Icon _getStatusIcon(String status) {
    switch (status) {
      // ### CORREÇÃO AQUI ###
      case 'sucedido':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'pago':
        return const Icon(Icons.download_done, color: Colors.blue);
      case 'processando':
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case 'cancelado':
      case 'reembolsado':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      // ### CORREÇÃO AQUI ###
      case 'sucedido':
        return 'Disponível'; // Ou "Sucedido", como preferir
      case 'pago':
        return 'Pago';
      case 'processando':
        return 'Pendente';
      case 'cancelado':
        return 'Cancelado';
      case 'reembolsado':
        return 'Reembolsado';
      default:
        return 'Outro';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      // ### CORREÇÃO AQUI ###
      case 'sucedido':
        return Colors.green.shade700;
      case 'pago':
        return Colors.blue.shade700;
      case 'processando':
        return Colors.orange.shade700;
      case 'cancelado':
      case 'reembolsado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
