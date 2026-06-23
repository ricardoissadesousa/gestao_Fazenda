import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _notificacoes => _firestore.collection('notificacoes');
  CollectionReference get _usuarios => _firestore.collection('usuarios');

  /// Cria uma notificação para todos os gestores quando uma solicitação de folga é enviada
  Future<void> criarNotificacaoParaGestores({
    required String funcionarioNome,
    required String dataSolicitada,
    required String solicitacaoId,
  }) async {
    // Buscar todos os gestores
    final gestoresSnapshot = await _usuarios
        .where('tipo', isEqualTo: 'GESTOR')
        .get();

    // Criar notificação para cada gestor
    final batch = _firestore.batch();
    for (var gestorDoc in gestoresSnapshot.docs) {
      final notificacaoRef = _notificacoes.doc();
      batch.set(notificacaoRef, {
        'gestor_id': gestorDoc.id,
        'tipo': 'SOLICITACAO_FOLGA',
        'titulo': 'Nova Solicitação de Folga',
        'mensagem': '$funcionarioNome solicitou folga para $dataSolicitada',
        'lida': false,
        'data_criacao': FieldValue.serverTimestamp(),
        'referencia_id': solicitacaoId,
      });
    }
    await batch.commit();
  }

  /// Stream em tempo real de notificações não lidas do gestor
  Stream<List<Map<String, dynamic>>> obterNotificacoesNaoLidas(String gestorId) {
    return _notificacoes
        .where('gestor_id', isEqualTo: gestorId)
        .where('lida', isEqualTo: false)
        .orderBy('data_criacao', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream com contagem de notificações não lidas
  Stream<int> contarNaoLidas(String gestorId) {
    return _notificacoes
        .where('gestor_id', isEqualTo: gestorId)
        .where('lida', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marcar uma notificação como lida
  Future<void> marcarComoLida(String notificacaoId) async {
    await _notificacoes.doc(notificacaoId).update({'lida': true});
  }

  /// Marcar todas as notificações do gestor como lidas
  Future<void> marcarTodasComoLidas(String gestorId) async {
    final snapshot = await _notificacoes
        .where('gestor_id', isEqualTo: gestorId)
        .where('lida', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'lida': true});
    }
    await batch.commit();
  }
}
