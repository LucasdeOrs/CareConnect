class PatientModel {
  final String id;
  final String familiarId;
  final String nome;
  final int? idade;
  final String? condicoes;
  final String? observacoes;

  PatientModel({
    required this.id,
    required this.familiarId,
    required this.nome,
    this.idade,
    this.condicoes,
    this.observacoes,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      familiarId: json['familiar_id'] ?? '',
      nome: json['nome'] ?? 'Não informado',
      idade: json['idade'],
      condicoes: json['condicoes'],
      observacoes: json['observacoes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'familiar_id': familiarId,
      'nome': nome,
      'idade': idade,
      'condicoes': condicoes,
      'observacoes': observacoes,
    };
  }
}
