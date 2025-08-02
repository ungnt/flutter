class GastoModel {
  final int? id;
  final DateTime data;
  final String categoria;
  final double valor;
  final String descricao;
  final DateTime dataRegistro;

  GastoModel({
    this.id,
    required this.data,
    required this.categoria,
    required this.valor,
    this.descricao = '',
    required this.dataRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'categoria': categoria,
      'valor': valor,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
  }

  factory GastoModel.fromMap(Map<String, dynamic> map) {
    return GastoModel(
      id: map['id']?.toInt(),
      data: DateTime.parse(map['data']),
      categoria: map['categoria'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      dataRegistro: DateTime.parse(map['data_registro']),
    );
  }

  // Método fromJson necessário para sincronização
  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: json['id']?.toInt(),
      data: DateTime.parse(json['data']),
      categoria: json['categoria'] ?? '',
      valor: json['valor']?.toDouble() ?? 0.0,
      descricao: json['descricao'] ?? '',
      dataRegistro: DateTime.parse(json['data_registro']),
    );
  }

  // Método toJson para sincronização
  Map<String, dynamic> toJson() {
    return toMap();
  }

  GastoModel copyWith({
    int? id,
    DateTime? data,
    String? categoria,
    double? valor,
    String? descricao,
    DateTime? dataRegistro,
  }) {
    return GastoModel(
      id: id ?? this.id,
      data: data ?? this.data,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      descricao: descricao ?? this.descricao,
      dataRegistro: dataRegistro ?? this.dataRegistro,
    );
  }
}