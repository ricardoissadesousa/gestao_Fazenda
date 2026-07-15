import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoComunicacao {
  SOLICITACAO_FOLGA,
  NOTIFICACAO,
}

enum StatusComunicacao {
  PENDENTE,
  VISUALIZADO,
  ACEITO,
  RECUSADO,
}

class Comunicacao {
  final String id;
  final TipoComunicacao tipo;
  final String titulo;
  final String mensagem;
  final StatusComunicacao status;
  final String remetenteId;
  final String remetenteNome;
  final String remetenteEmail;
  final String? destinatarioId; // null = broadcast para todos os gestores
  final bool lida;
  final DateTime? dataCriacao;
  final DateTime? dataAtualizacao;
  final Map<String, dynamic> dadosAdicionais;
  final String? fazendaId;

  Comunicacao({
    this.id = '',
    this.tipo = TipoComunicacao.NOTIFICACAO,
    this.titulo = '',
    this.mensagem = '',
    this.status = StatusComunicacao.PENDENTE,
    this.remetenteId = '',
    this.remetenteNome = '',
    this.remetenteEmail = '',
    this.destinatarioId,
    this.lida = false,
    this.dataCriacao,
    this.dataAtualizacao,
    this.dadosAdicionais = const {},
    this.fazendaId,
  });

  factory Comunicacao.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Comunicacao(
      id: doc.id,
      tipo: _parseTipo(data['tipo']),
      titulo: data['titulo'] ?? '',
      mensagem: data['mensagem'] ?? '',
      status: _parseStatus(data['status']),
      remetenteId: data['remetente_id'] ?? '',
      remetenteNome: data['remetente_nome'] ?? '',
      remetenteEmail: data['remetente_email'] ?? '',
      destinatarioId: data['destinatario_id'],
      lida: data['lida'] ?? false,
      dataCriacao: (data['data_criacao'] as Timestamp?)?.toDate(),
      dataAtualizacao: (data['data_atualizacao'] as Timestamp?)?.toDate(),
      dadosAdicionais: Map<String, dynamic>.from(data['dados_adicionais'] ?? {}),
      fazendaId: data['fazenda_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipo': tipo.name,
      'titulo': titulo,
      'mensagem': mensagem,
      'status': status.name,
      'remetente_id': remetenteId,
      'remetente_nome': remetenteNome,
      'remetente_email': remetenteEmail,
      'destinatario_id': destinatarioId,
      'lida': lida,
      'data_criacao': dataCriacao != null
          ? Timestamp.fromDate(dataCriacao!)
          : FieldValue.serverTimestamp(),
      'data_atualizacao': FieldValue.serverTimestamp(),
      'dados_adicionais': dadosAdicionais,
      'fazenda_id': fazendaId,
    };
  }

  Comunicacao copyWith({
    String? id,
    TipoComunicacao? tipo,
    String? titulo,
    String? mensagem,
    StatusComunicacao? status,
    String? remetenteId,
    String? remetenteNome,
    String? remetenteEmail,
    String? destinatarioId,
    bool? lida,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    Map<String, dynamic>? dadosAdicionais,
    String? fazendaId,
  }) {
    return Comunicacao(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      status: status ?? this.status,
      remetenteId: remetenteId ?? this.remetenteId,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      remetenteEmail: remetenteEmail ?? this.remetenteEmail,
      destinatarioId: destinatarioId ?? this.destinatarioId,
      lida: lida ?? this.lida,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      dadosAdicionais: dadosAdicionais ?? this.dadosAdicionais,
      fazendaId: fazendaId ?? this.fazendaId,
    );
  }

  // --- Helpers para dados adicionais de solicitação de folga ---

  String get dataSolicitada => dadosAdicionais['data_solicitada'] ?? '';
  String get motivo => dadosAdicionais['motivo'] ?? '';
  String get motivoRecusa => dadosAdicionais['motivo_recusa'] ?? '';

  // --- Parsers ---

  static TipoComunicacao _parseTipo(String? valor) {
    return switch (valor) {
      'SOLICITACAO_FOLGA' => TipoComunicacao.SOLICITACAO_FOLGA,
      'NOTIFICACAO' => TipoComunicacao.NOTIFICACAO,
      _ => TipoComunicacao.NOTIFICACAO,
    };
  }

  static StatusComunicacao _parseStatus(String? valor) {
    return switch (valor) {
      'PENDENTE' => StatusComunicacao.PENDENTE,
      'VISUALIZADO' => StatusComunicacao.VISUALIZADO,
      'ACEITO' => StatusComunicacao.ACEITO,
      'RECUSADO' => StatusComunicacao.RECUSADO,
      // Compatibilidade com valores antigos
      'APROVADA' => StatusComunicacao.ACEITO,
      'REPROVADA' => StatusComunicacao.RECUSADO,
      _ => StatusComunicacao.PENDENTE,
    };
  }
}
