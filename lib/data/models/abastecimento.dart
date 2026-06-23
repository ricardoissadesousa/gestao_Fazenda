import 'package:cloud_firestore/cloud_firestore.dart';

class Abastecimento {
  final String id;
  final DateTime? data;
  final String motorista;
  final double litros;
  final String equipamento;
  final double horimetro;
  final String aplicacao;
  final String? usuarioUid;
  final String? fotoComprovante; // Base64 da foto do comprovante

  Abastecimento({
    this.id = '',
    this.data,
    this.motorista = '',
    this.litros = 0.0,
    this.equipamento = '',
    this.horimetro = 0.0,
    this.aplicacao = '',
    this.usuarioUid,
    this.fotoComprovante,
  });

  factory Abastecimento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Abastecimento(
      id: doc.id,
      data: (data['data'] as Timestamp?)?.toDate(),
      motorista: data['motorista'] ?? '',
      litros: (data['litros'] ?? 0.0).toDouble(),
      equipamento: data['equipamento'] ?? '',
      horimetro: (data['horimetro'] ?? 0.0).toDouble(),
      aplicacao: data['aplicacao'] ?? '',
      usuarioUid: data['usuario_uid'],
      fotoComprovante: data['foto_comprovante'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'data': data != null ? Timestamp.fromDate(data!) : FieldValue.serverTimestamp(),
      'motorista': motorista,
      'litros': litros,
      'equipamento': equipamento,
      'horimetro': horimetro,
      'aplicacao': aplicacao,
      'usuario_uid': usuarioUid,
      'foto_comprovante': fotoComprovante,
    };
  }
}
