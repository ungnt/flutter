import 'package:flutter/foundation.dart';

class ManutencaoModel {
  final int? id;
  final DateTime data;
  final String tipo;
  final double valor;
  final double kmAtual;
  final String descricao;
  final DateTime dataRegistro;

  ManutencaoModel({
    this.id,
    required this.data,
    required this.tipo,
    required this.valor,
    required this.kmAtual,
    this.descricao = '',
    required this.dataRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'tipo': tipo,
      'valor': valor,
      'km_atual': kmAtual,
      'descricao': descricao,
      'data_registro': dataRegistro.toIso8601String(),
    };
  }

  factory ManutencaoModel.fromMap(Map<String, dynamic> map) {
    return ManutencaoModel(
      id: map['id']?.toInt(),
      data: DateTime.parse(map['data']),
      tipo: map['tipo'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      kmAtual: map['km_atual']?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      dataRegistro: DateTime.parse(map['data_registro']),
    );
  }

  ManutencaoModel copyWith({
    int? id,
    DateTime? data,
    String? tipo,
    double? valor,
    double? kmAtual,
    String? descricao,
    DateTime? dataRegistro,
  }) {
    return ManutencaoModel(
      id: id ?? this.id,
      data: data ?? this.data,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      kmAtual: kmAtual ?? this.kmAtual,
      descricao: descricao ?? this.descricao,
      dataRegistro: dataRegistro ?? this.dataRegistro,
    );
  }
}