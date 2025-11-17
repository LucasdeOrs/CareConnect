enum AppointmentStatus {
  aguardandoPagamento,
  pago,
  confirmado,
  emAndamento,
  concluido,
  recusado,
  cancelado;

  static AppointmentStatus fromString(String status) {
    switch (status) {
      case 'aguardando_pagamento':
        return AppointmentStatus.aguardandoPagamento;
      case 'pago':
        return AppointmentStatus.pago;
      case 'confirmado':
        return AppointmentStatus.confirmado;
      case 'em_andamento':
        return AppointmentStatus.emAndamento;
      case 'concluido':
        return AppointmentStatus.concluido;
      case 'recusado':
        return AppointmentStatus.recusado;
      case 'cancelado':
        return AppointmentStatus.cancelado;
      default:
        return AppointmentStatus.aguardandoPagamento;
    }
  }

  String toDatabaseString() {
    switch (this) {
      case AppointmentStatus.aguardandoPagamento:
        return 'aguardando_pagamento';
      case AppointmentStatus.pago:
        return 'pago';
      case AppointmentStatus.confirmado:
        return 'confirmado';
      case AppointmentStatus.emAndamento:
        return 'em_andamento';
      case AppointmentStatus.concluido:
        return 'concluido';
      case AppointmentStatus.recusado:
        return 'recusado';
      case AppointmentStatus.cancelado:
        return 'cancelado';
    }
  }
}
