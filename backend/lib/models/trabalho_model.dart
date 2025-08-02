class TrabalhoModel {
  final String? id;
  final String userId;
  final DateTime data;
  final double ganhos;
  final double km;  // Schema real: km, não quilometragem_inicial/final
  final double horas;  // Schema real: horas, não horas_trabalhadas
  final String? observacoes;
  final DateTime dataRegistro;  // Schema real: data_registro, não created_at
  final DateTime? updatedAt;

  TrabalhoModel({
    this.id,
    required this.userId,
    required this.data,
    required this.ganhos,
    required this.km,
    required this.horas,
    this.observacoes,
    required this.dataRegistro,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': userId,
      'data': data.toIso8601String().split('T')[0], // YYYY-MM-DD
      'ganhos': ganhos,
      'km': km,
      'horas': horas,
      'observacoes': observacoes,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    // Só incluir id se não for null (para inserção)
    if (id != null) map['id'] = id;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory TrabalhoModel.fromJson(Map<String, dynamic> json) {
    return TrabalhoModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      data: DateTime.parse(json['data']),
      ganhos: (json['ganhos'] as num?)?.toDouble() ?? 0.0,
      km: (json['km'] as num?)?.toDouble() ?? 0.0,
      horas: (json['horas'] as num?)?.toDouble() ?? 0.0,
      observacoes: json['observacoes']?.toString(),
      dataRegistro: DateTime.parse(json['data_registro']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  TrabalhoModel copyWith({
    String? id,
    String? userId,
    DateTime? data,
    double? ganhos,
    double? km,
    double? horas,
    String? observacoes,
    DateTime? dataRegistro,
    DateTime? updatedAt,
  }) {
    return TrabalhoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      ganhos: ganhos ?? this.ganhos,
      km: km ?? this.km,
      horas: horas ?? this.horas,
      observacoes: observacoes ?? this.observacoes,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TrabalhoModel(id: $id, userId: $userId, data: $data, ganhos: $ganhos, km: $km, horas: $horas)';
  }
}