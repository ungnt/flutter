/// Model para registros de trabalho diário
/// Alinhado 100% com backend e Supabase
class TrabalhoModel {
  final String? id; // UUID String para compatibilidade total com Supabase
  final String? userId; // user_id String para sincronização
  final DateTime data;
  final double ganhos;
  final double km;
  final double horas;
  final String observacoes;
  final DateTime dataRegistro;
  final DateTime? updatedAt; // updated_at do Supabase

  TrabalhoModel({
    this.id,
    this.userId,
    required this.data,
    required this.ganhos,
    required this.km,
    required this.horas,
    this.observacoes = '',
    required this.dataRegistro,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'ganhos': ganhos,
      'km': km,
      'horas': horas,
      'observacoes': observacoes,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (id != null) map['id'] = id!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory TrabalhoModel.fromMap(Map<String, dynamic> map) {
    return TrabalhoModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      data: DateTime.parse(map['data']),
      ganhos: map['ganhos']?.toDouble() ?? 0.0,
      km: map['km']?.toDouble() ?? 0.0,
      horas: map['horas']?.toDouble() ?? 0.0,
      observacoes: map['observacoes'] ?? '',
      dataRegistro: DateTime.parse(map['data_registro']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Método fromJson necessário para sincronização
  factory TrabalhoModel.fromJson(Map<String, dynamic> json) {
    return TrabalhoModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      data: DateTime.parse(json['data']),
      ganhos: json['ganhos']?.toDouble() ?? 0.0,
      km: json['km']?.toDouble() ?? 0.0,
      horas: json['horas']?.toDouble() ?? 0.0,
      observacoes: json['observacoes'] ?? '',
      dataRegistro: DateTime.parse(json['data_registro']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Método toJson para sincronização
  Map<String, dynamic> toJson() {
    return toMap();
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
}