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

  /// URL de download da foto salva no Firebase Storage.
  final String? fotoComprovanteUrl;

  /// Caminho do arquivo no Firebase Storage, usado para manutenção/exclusão.
  final String? fotoComprovantePath;

  /// Formato usado pelas versões antigas do app. Mantido para que os
  /// comprovantes já cadastrados continuem aparecendo no histórico.
  final String? fotoComprovanteBase64;
  final String? fazendaId;

  Abastecimento({
    this.id = '',
    this.data,
    this.motorista = '',
    this.litros = 0.0,
    this.equipamento = '',
    this.horimetro = 0.0,
    this.aplicacao = '',
    this.usuarioUid,
    this.fotoComprovanteUrl,
    this.fotoComprovantePath,
    this.fotoComprovanteBase64,
    this.fazendaId,
  });

  bool get temFotoComprovante =>
      (fotoComprovanteUrl?.isNotEmpty ?? false) ||
      (fotoComprovantePath?.isNotEmpty ?? false) ||
      (fotoComprovanteBase64?.isNotEmpty ?? false);

  factory Abastecimento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final fotoLegada = data['foto_comprovante'] as String?;
    final fotoLegadaEhUrl =
        fotoLegada != null &&
        (fotoLegada.startsWith('https://') || fotoLegada.startsWith('http://'));

    return Abastecimento(
      id: doc.id,
      data: (data['data'] as Timestamp?)?.toDate(),
      motorista: data['motorista'] ?? '',
      litros: (data['litros'] ?? 0.0).toDouble(),
      equipamento: data['equipamento'] ?? '',
      horimetro: (data['horimetro'] ?? 0.0).toDouble(),
      aplicacao: data['aplicacao'] ?? '',
      usuarioUid: data['usuario_uid'],
      fotoComprovanteUrl:
          data['foto_comprovante_url'] as String? ??
          (fotoLegadaEhUrl ? fotoLegada : null),
      fotoComprovantePath: data['foto_comprovante_path'] as String?,
      fotoComprovanteBase64: fotoLegadaEhUrl ? null : fotoLegada,
      fazendaId: data['fazenda_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'data': data != null
          ? Timestamp.fromDate(data!)
          : FieldValue.serverTimestamp(),
      'motorista': motorista,
      'litros': litros,
      'equipamento': equipamento,
      'horimetro': horimetro,
      'aplicacao': aplicacao,
      'usuario_uid': usuarioUid,
      'foto_comprovante_url': fotoComprovanteUrl,
      'foto_comprovante_path': fotoComprovantePath,
      'fazenda_id': fazendaId,
    };
  }
}
