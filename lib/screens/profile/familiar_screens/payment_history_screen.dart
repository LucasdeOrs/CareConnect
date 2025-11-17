import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late final Future<List<Map<String, dynamic>>> _paymentsFuture;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchPayments();
  }

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('pagamentos')
          .select(
            'id, valor_bruto, status_pagamento, created_at, metodo_pagamento, agendamento:agendamento_id( cuidador:cuidador_id( usuario:usuario_id(nome) ) )',
          )
          .eq('pagador_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Erro ao buscar pagamentos: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pagamentos'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum pagamento realizado ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];

              String caregiverName = 'Cuidador';
              try {
                final agendamento = payment['agendamento'] as Map?;
                final cuidador = agendamento?['cuidador'] as Map?;
                final usuario = cuidador?['usuario'] as Map?;
                if (usuario != null) {
                  caregiverName = usuario['nome'] ?? 'Cuidador';
                }
              } catch (e) {
                // Fallback silencioso
              }

              final status = payment['status_pagamento'] ?? 'desconhecido';
              final valor = (payment['valor_bruto'] as num).toDouble();
              final data = DateTime.parse(payment['created_at']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    // ignore: deprecated_member_use
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                    ),
                  ),
                  title: Text(
                    _currencyFormat.format(valor),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Para: $caregiverName'),
                      Text(
                        _dateFormat.format(data),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'sucedido':
      case 'pago':
        return 'Pago';
      case 'processando':
        return 'Processando';
      case 'falha':
        return 'Falhou';
      case 'reembolsado':
      case 'cancelado':
        return 'Reembolsado';
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'sucedido':
      case 'pago':
        return Icons.check;
      case 'processando':
        return Icons.access_time;
      case 'falha':
        return Icons.error_outline;
      case 'reembolsado':
      case 'cancelado':
        return Icons.undo;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sucedido':
      case 'pago':
        return Colors.green;
      case 'processando':
        return Colors.orange;
      case 'falha':
        return Colors.red;
      case 'reembolsado':
      case 'cancelado':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
