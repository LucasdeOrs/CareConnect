import 'package:flutter/material.dart';

enum UserType {
  familiar,
  cuidador;

  static UserType fromString(String value) =>
      value == 'cuidador' ? UserType.cuidador : UserType.familiar;

  String get toDb => this == UserType.cuidador ? 'cuidador' : 'familiar';
}

enum AppointmentStatus {
  aguardandoPagamento(
    'aguardando_pagamento',
    'Aguardando Pagamento',
    Colors.orange,
  ),
  pago('pago', 'Aguardando Aceite', Colors.orange),
  confirmado('confirmado', 'Confirmado', Colors.blue),
  concluido('concluido', 'Concluído', Colors.green),
  recusado('recusado', 'Recusado', Colors.red),
  cancelado('cancelado', 'Cancelado', Colors.red);

  final String dbValue;
  final String label;
  final Color color;

  const AppointmentStatus(this.dbValue, this.label, this.color);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AppointmentStatus.aguardandoPagamento,
    );
  }
}

enum PaymentStatus {
  sucedido('sucedido', 'Pago', Colors.green, Icons.check_circle_outline),
  pago('pago', 'Pago', Colors.green, Icons.check_circle_outline),
  processando('processando', 'Processando', Colors.orange, Icons.hourglass_top),
  falha('falha', 'Falhou', Colors.red, Icons.error_outline),
  reembolsado('reembolsado', 'Reembolsado', Colors.purple, Icons.undo),
  cancelado('cancelado', 'Cancelado', Colors.red, Icons.cancel_outlined);

  final String dbValue;
  final String label;
  final Color color;
  final IconData icon;

  const PaymentStatus(this.dbValue, this.label, this.color, this.icon);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PaymentStatus.processando,
    );
  }
}

enum PaymentMethod {
  pix('pix', 'PIX', Icons.pix),
  creditCard('cartao_credito', 'Cartão de Crédito', Icons.credit_card);

  final String dbValue;
  final String label;
  final IconData icon;

  const PaymentMethod(this.dbValue, this.label, this.icon);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PaymentMethod.pix,
    );
  }
}
