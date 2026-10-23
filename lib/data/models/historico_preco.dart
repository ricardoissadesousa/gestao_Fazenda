import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoPreco {
  final String id; // Formato: "YYYY-MM" (ex: "2026-01")
  final double preco;
  final int mes;
  final int ano;
  final DateTime? dataAtualizacao;

  HistoricoPreco({
    this.id = '',
    this.preco = 0.0,
    this.mes = 1,
    this.ano = 2026,
    this.dataAtualizacao,
  });

  /// Gera o ID no formato YYYY-MM
  static String gerarId(int mes, int ano) {
    return '$ano-${mes.toString().padLeft(2, '0')}';
  }

  factory HistoricoPreco.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HistoricoPreco(
      id: doc.id,
      preco: _comoDouble(data['preco']),
      mes: _comoInt(data['mes'], padrao: 1),
      ano: _comoInt(data['ano'], padrao: 2026),
      dataAtualizacao: _comoData(data['data_atualizacao']),
    );
  }

  static double _comoDouble(Object? valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static int _comoInt(Object? valor, {required int padrao}) {
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? padrao;
  }

  static DateTime? _comoData(Object? valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.tryParse(valor?.toString() ?? '');
  }

  Map<String, dynamic> toFirestore() {
    return {
      'preco': preco,
      'mes': mes,
      'ano': ano,
      'data_atualizacao': FieldValue.serverTimestamp(),
    };
  }

  HistoricoPreco copyWith({
    double? preco,
    int? mes,
    int? ano,
    DateTime? dataAtualizacao,
  }) {
    return HistoricoPreco(
      id: id,
      preco: preco ?? this.preco,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
