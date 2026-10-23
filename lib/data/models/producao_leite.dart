import 'package:cloud_firestore/cloud_firestore.dart';

class ProducaoLeite {
  String id;
  final DateTime? data;
  final String dataFormatada;
  final double litrosManha;
  final double litrosTarde;
  final double totalLitros;
  final String observacoes;
  final String? fazendaId;

  ProducaoLeite({
    this.id = '',
    this.data,
    this.dataFormatada = '',
    this.litrosManha = 0.0,
    this.litrosTarde = 0.0,
    this.totalLitros = 0.0,
    this.observacoes = '',
    this.fazendaId,
  });

  factory ProducaoLeite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProducaoLeite(
      id: doc.id,
      data: _comoData(data['data']) ?? _comoData(data['data_registro']),
      dataFormatada: data['dataFormatada']?.toString() ?? '',
      litrosManha: _comoDouble(data['litrosManha']),
      litrosTarde: _comoDouble(data['litrosTarde']),
      totalLitros: _comoDouble(data['total_litros'] ?? data['totalLitros']),
      observacoes: data['observacoes']?.toString() ?? '',
      fazendaId: data['fazenda_id']?.toString(),
    );
  }

  static double _comoDouble(Object? valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static DateTime? _comoData(Object? valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    if (valor is num) {
      return DateTime.fromMillisecondsSinceEpoch(valor.toInt());
    }
    return DateTime.tryParse(valor?.toString() ?? '');
  }

  Map<String, dynamic> toFirestore() {
    return {
      'data': data != null ? Timestamp.fromDate(data!) : null,
      'dataFormatada': dataFormatada,
      'litrosManha': litrosManha,
      'litrosTarde': litrosTarde,
      'totalLitros': totalLitros,
      'observacoes': observacoes,
      'fazenda_id': fazendaId,
    };
  }
}

class RelatorioMensal {
  final String mes;
  final int ano;
  final double totalLitros;
  final double precoLeite;
  final double faturamento;
  final double mediaLitrosDia;

  RelatorioMensal({
    this.mes = '',
    this.ano = 0,
    this.totalLitros = 0.0,
    this.precoLeite = 0.0,
    this.faturamento = 0.0,
    this.mediaLitrosDia = 0.0,
  });
}

class ConfiguracaoPreco {
  final String id;
  final double precoLeite;

  ConfiguracaoPreco({this.id = 'preco_atual', this.precoLeite = 2.85});
}
