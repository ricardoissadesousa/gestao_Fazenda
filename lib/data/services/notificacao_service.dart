import 'package:cloud_firestore/cloud_firestore.dart';
import 'comunicacao_service.dart';

/// Serviço de notificações — agora delega ao ComunicacaoService unificado.
/// Mantém a interface pública para compatibilidade com telas existentes.
class NotificacaoService {
  final ComunicacaoService _comunicacaoService = ComunicacaoService();

  /// Cria uma notificação para todos os gestores quando uma solicitação de folga é enviada.
  /// Agora cria uma comunicação unificada na coleção 'comunicacoes'.
  Future<void> criarNotificacaoParaGestores({
    required String funcionarioNome,
    required String dataSolicitada,
    required String solicitacaoId,
  }) async {
    // Delegado ao ComunicacaoService — este método é chamado pelo FolgaService
    // A criação já é feita dentro de criarSolicitacaoFolga do ComunicacaoService,
    // então este método só precisa ser mantido para compatibilidade de assinatura.
    // Nenhuma ação necessária aqui pois o FolgaService agora delega diretamente.
  }

  /// Stream em tempo real de notificações não lidas do gestor
  Stream<List<Map<String, dynamic>>> obterNotificacoesNaoLidas(String gestorId, String fazendaId) {
    return _comunicacaoService.obterNotificacoesNaoLidas(gestorId, fazendaId).map(
      (comunicacoes) {
        return comunicacoes.map((c) {
          final map = <String, dynamic>{
            'id': c.id,
            'tipo': c.tipo.name,
            'titulo': c.titulo,
            'mensagem': c.mensagem,
            'lida': c.lida,
            'data_criacao': c.dataCriacao != null
                ? Timestamp.fromDate(c.dataCriacao!)
                : null,
            'gestor_id': c.destinatarioId,
          };
          return map;
        }).toList();
      },
    );
  }

  /// Stream com contagem de notificações não lidas
  Stream<int> contarNaoLidas(String gestorId, String fazendaId) {
    return _comunicacaoService.contarNaoLidas(gestorId, fazendaId);
  }

  /// Marcar uma notificação como lida
  Future<void> marcarComoLida(String notificacaoId) async {
    await _comunicacaoService.marcarComoLida(notificacaoId);
  }

  /// Marcar todas as notificações do gestor como lidas
  Future<void> marcarTodasComoLidas(String gestorId, String fazendaId) async {
    await _comunicacaoService.marcarTodasComoLidas(gestorId, fazendaId);
  }
}
