/// Model para registros de trabalho diário
/// Alinhado 100% com backend e Supabase
class TrabalhoModel {
  final int? localId; // ID local SQLite (INTEGER AUTOINCREMENT)
  final String? remoteId; // UUID String para backend/Supabase
  final String? userId; // user_id String para sincronização
  final DateTime data;
  final double ganhos;
  final double km;
  final double horas;
  final String observacoes;
  final DateTime dataRegistro;
  final DateTime? updatedAt; // updated_at do Supabase

  TrabalhoModel({
    this.localId,
    this.remoteId,
    this.userId,
    required this.data,
    required this.ganhos,
    required this.km,
    required this.horas,
    this.observacoes = '',
    required this.dataRegistro,
    this.updatedAt,
  });

  // Getter para compatibilidade com código legado
  int? get id => localId;

  Map<String, dynamic> toMap() {
    final map = {
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'ganhos': ganhos,
      'km': km,
      'horas': horas,
      'observacoes': observacoes,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (localId != null) map['local_id'] = localId!;
    if (remoteId != null) map['remote_id'] = remoteId!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  factory TrabalhoModel.fromMap(Map<String, dynamic> map) {
    return TrabalhoModel(
      localId: map['local_id'] as int?,
      remoteId: map['remote_id']?.toString(),
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

  // Método fromJson necessário para sincronização (backend retorna 'id' como UUID)
  factory TrabalhoModel.fromJson(Map<String, dynamic> json) {
    return TrabalhoModel(
      localId: null, // Backend não tem localId
      remoteId: json['id']?.toString(),
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

  // Método toJson para sincronização (backend espera 'id' como UUID)
  Map<String, dynamic> toJson() {
    final map = {
      'data': data.toIso8601String().split('T')[0],
      'ganhos': ganhos,
      'km': km,
      'horas': horas,
      'observacoes': observacoes,
      'data_registro': dataRegistro.toIso8601String(),
    };
    
    if (remoteId != null) map['id'] = remoteId!;
    if (userId != null) map['user_id'] = userId!;
    if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    
    return map;
  }

  TrabalhoModel copyWith({
    int? localId,
    String? remoteId,
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
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
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