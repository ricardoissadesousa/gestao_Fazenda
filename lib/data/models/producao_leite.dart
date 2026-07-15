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
      data: (data['data'] as Timestamp?)?.toDate() ??
          (data['data_registro'] as Timestamp?)?.toDate(),
      dataFormatada: data['dataFormatada'] ?? '',
      litrosManha: (data['litrosManha'] ?? 0.0).toDouble(),
      litrosTarde: (data['litrosTarde'] ?? 0.0).toDouble(),
      totalLitros: (data['total_litros'] ?? data['totalLitros'] ?? 0.0).toDouble(),
      observacoes: data['observacoes'] ?? '',
      fazendaId: data['fazenda_id'],
    );
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

  ConfiguracaoPreco({
    this.id = 'preco_atual',
    this.precoLeite = 2.85,
  });
}
