import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_error_messages.dart';
import '../models/comunicacao.dart';

class ComunicacaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _comunicacoes =>
      _firestore.collection('comunicacoes');

  /// Criar solicitação de folga e notificar todos os gestores
  Future<void> criarSolicitacaoFolga({
    required String usuarioId,
    required String usuarioNome,
    required String usuarioEmail,
    required String dataSolicitada,
    required String motivo,
    required String fazendaId,
  }) async {
    // Buscar o proprietário específico da fazenda
    final fazendaDoc = await _firestore
        .collection('fazendas')
        .doc(fazendaId)
        .get();
    if (!fazendaDoc.exists) {
      throw const UserMessageException(
        'A fazenda selecionada não foi encontrada. Selecione outra fazenda.',
      );
    }

    final dataFazenda = fazendaDoc.data();
    final proprietarioId = dataFazenda?['proprietario_id'];

    if (proprietarioId == null) {
      throw const UserMessageException(
        'Não foi possível identificar o responsável pela fazenda.',
      );
    }

    final comunicacao = Comunicacao(
      tipo: TipoComunicacao.SOLICITACAO_FOLGA,
      titulo: 'Solicitação de Folga',
      mensagem: '$usuarioNome solicitou folga para $dataSolicitada',
      status: StatusComunicacao.PENDENTE,
      remetenteId: usuarioId,
      remetenteNome: usuarioNome,
      remetenteEmail: usuarioEmail,
      destinatarioId: proprietarioId,
      lida: false,
      dadosAdicionais: {'data_solicitada': dataSolicitada, 'motivo': motivo},
      fazendaId: fazendaId,
    );

    await _comunicacoes.add(comunicacao.toFirestore());
  }

  //  Consultas — Notificações do Gestor

  /// Stream de notificações não lidas de um gestor
  Stream<List<Comunicacao>> obterNotificacoesNaoLidas(
    String gestorId,
    String fazendaId,
  ) {
    return _comunicacoes
        .where('destinatario_id', isEqualTo: gestorId)
        .where('fazenda_id', isEqualTo: fazendaId)
        .where('lida', isEqualTo: false)
        .orderBy('data_criacao', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comunicacao.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream com contagem de não lidas do gestor
  Stream<int> contarNaoLidas(String gestorId, String fazendaId) {
    return _comunicacoes
        .where('destinatario_id', isEqualTo: gestorId)
        .where('fazenda_id', isEqualTo: fazendaId)
        .where('lida', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marcar comunicação como lida
  Future<void> marcarComoLida(String comunicacaoId) async {
    await _comunicacoes.doc(comunicacaoId).update({
      'lida': true,
      'data_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  /// Marcar todas as comunicações do gestor como lidas (para uma fazenda)
  Future<void> marcarTodasComoLidas(String gestorId, String fazendaId) async {
    final snapshot = await _comunicacoes
        .where('destinatario_id', isEqualTo: gestorId)
        .where('fazenda_id', isEqualTo: fazendaId)
        .where('lida', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'lida': true,
        'data_atualizacao': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  //  Consultas — Solicitações de Folga

  /// Buscar solicitações pendentes (para gestor)
  Future<List<Comunicacao>> obterSolicitacoesPendentes(
    String gestorId,
    String fazendaId,
  ) async {
    final result = await _comunicacoes
        .where('destinatario_id', isEqualTo: gestorId)
        .where('tipo', isEqualTo: TipoComunicacao.SOLICITACAO_FOLGA.name)
        .where('status', isEqualTo: StatusComunicacao.PENDENTE.name)
        .where('fazenda_id', isEqualTo: fazendaId)
        .get();

    return result.docs.map((doc) => Comunicacao.fromFirestore(doc)).toList();
  }

  /// Buscar solicitações do funcionário (todas daquela fazenda)
  Future<List<Comunicacao>> obterSolicitacoesDoUsuario(
    String userId,
    String fazendaId,
  ) async {
    final result = await _comunicacoes
        .where('remetente_id', isEqualTo: userId)
        .where('fazenda_id', isEqualTo: fazendaId)
        .where('tipo', isEqualTo: TipoComunicacao.SOLICITACAO_FOLGA.name)
        .get();

    return result.docs.map((doc) => Comunicacao.fromFirestore(doc)).toList();
  }

  /// Buscar histórico global (aceitas + recusadas)
  Future<List<Comunicacao>> obterHistoricoGlobal(
    String gestorId,
    String fazendaId,
  ) async {
    final result = await _comunicacoes
        .where('destinatario_id', isEqualTo: gestorId)
        .where('tipo', isEqualTo: TipoComunicacao.SOLICITACAO_FOLGA.name)
        .where(
          'status',
          whereIn: [
            StatusComunicacao.ACEITO.name,
            StatusComunicacao.RECUSADO.name,
          ],
        )
        .where('fazenda_id', isEqualTo: fazendaId)
        .get();

    return result.docs.map((doc) => Comunicacao.fromFirestore(doc)).toList();
  }

  //  Ações sobre Solicitações

  /// Aprovar solicitação de folga
  Future<void> aprovarSolicitacao(String comunicacaoId) async {
    await _comunicacoes.doc(comunicacaoId).update({
      'status': StatusComunicacao.ACEITO.name,
      'data_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  /// Reprovar solicitação de folga
  Future<void> reprovarSolicitacao(String comunicacaoId, String motivo) async {
    await _comunicacoes.doc(comunicacaoId).update({
      'status': StatusComunicacao.RECUSADO.name,
      'dados_adicionais.motivo_recusa': motivo,
      'data_atualizacao': FieldValue.serverTimestamp(),
    });
  }
}
