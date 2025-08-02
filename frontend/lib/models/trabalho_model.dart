class TrabalhoModel {
  final int? id;
  final DateTime data;
  final double ganhos;
  final double km;
  final double horas;
  final String observacoes;
  final DateTime dataRegistro;

  TrabalhoModel({
    this.id,
    required this.data,
    required this.ganhos,
    required this.km,
    required this.horas,
    this.observacoes = '',
    required this.dataRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String().split('T')[0], // Salvar apenas a data YYYY-MM-DD
      'ganhos': ganhos,
      'km': km,
      'horas': horas,
      'observacoes': observacoes,
      'data_registro': dataRegistro.toIso8601String(),
    };
  }

  factory TrabalhoModel.fromMap(Map<String, dynamic> map) {
    return TrabalhoModel(
      id: map['id']?.toInt(),
      data: DateTime.parse(map['data']),
      ganhos: map['ganhos']?.toDouble() ?? 0.0,
      km: map['km']?.toDouble() ?? 0.0,
      horas: map['horas']?.toDouble() ?? 0.0,
      observacoes: map['observacoes'] ?? '',
      dataRegistro: DateTime.parse(map['data_registro']),
    );
  }

  // Método fromJson necessário para sincronização
  factory TrabalhoModel.fromJson(Map<String, dynamic> json) {
    return TrabalhoModel(
      id: json['id']?.toInt(),
      data: DateTime.parse(json['data']),
      ganhos: json['ganhos']?.toDouble() ?? 0.0,
      km: json['km']?.toDouble() ?? 0.0,
      horas: json['horas']?.toDouble() ?? 0.0,
      observacoes: json['observacoes'] ?? '',
      dataRegistro: DateTime.parse(json['data_registro']),
    );
  }

  // Método toJson para sincronização
  Map<String, dynamic> toJson() {
    return toMap();
  }

  TrabalhoModel copyWith({
    int? id,
    DateTime? data,
    double? ganhos,
    double? km,
    double? horas,
    String? observacoes,
    DateTime? dataRegistro,
  }) {
    return TrabalhoModel(
      id: id ?? this.id,
      data: data ?? this.data,
      ganhos: ganhos ?? this.ganhos,
      km: km ?? this.km,
      horas: horas ?? this.horas,
      observacoes: observacoes ?? this.observacoes,
      dataRegistro: dataRegistro ?? this.dataRegistro,
    );
  }
}