import 'package:cloud_firestore/cloud_firestore.dart';
import 'notificacao_service.dart';

class FolgaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificacaoService _notificacaoService = NotificacaoService();
  CollectionReference get _collection => _firestore.collection('solicitacoes_folga');

  /// Criar solicitação de folga e notificar gestores
  Future<void> criarSolicitacao({
    required String usuarioId,
    required String usuarioNome,
    required String usuarioEmail,
    required String dataSolicitada,
    required String motivo,
  }) async {
    final docRef = await _collection.add({
      'usuario_id': usuarioId,
      'usuario_nome': usuarioNome,
      'usuario_email': usuarioEmail,
      'data_solicitada': dataSolicitada,
      'motivo': motivo,
      'status': 'PENDENTE',
      'data_criacao': FieldValue.serverTimestamp(),
    });

    // Notificar todos os gestores sobre a nova solicitação
    await _notificacaoService.criarNotificacaoParaGestores(
      funcionarioNome: usuarioNome,
      dataSolicitada: dataSolicitada,
      solicitacaoId: docRef.id,
    );
  }

  /// Buscar solicitações do usuário
  Future<QuerySnapshot> obterSolicitacoesDoUsuario(String userId) {
    return _collection.where('usuario_id', isEqualTo: userId).get();
  }

  /// Buscar solicitações pendentes (para gestor)
  Future<QuerySnapshot> obterSolicitacoesPendentes() {
    return _collection.where('status', isEqualTo: 'PENDENTE').get();
  }

  /// Buscar histórico global (aprovadas + reprovadas)
  Future<QuerySnapshot> obterHistoricoGlobal() {
    return _collection
        .where('status', whereIn: ['APROVADA', 'REPROVADA']).get();
  }

  /// Aprovar solicitação
  Future<void> aprovarSolicitacao(String id) async {
    await _collection.doc(id).update({'status': 'APROVADA'});
  }

  /// Reprovar solicitação
  Future<void> reprovarSolicitacao(String id, String motivo) async {
    await _collection.doc(id).update({
      'status': 'REPROVADA',
      'motivo_recusa': motivo,
    });
  }
}
