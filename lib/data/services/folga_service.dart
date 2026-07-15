import 'comunicacao_service.dart';
import '../models/comunicacao.dart';

/// Serviço de folgas — agora delega criação ao ComunicacaoService unificado.
/// Mantém a interface pública para compatibilidade com telas existentes.
class FolgaService {
  final ComunicacaoService _comunicacaoService = ComunicacaoService();

  /// Criar solicitação de folga e notificar gestores (via comunicação unificada)
  Future<void> criarSolicitacao({
    required String usuarioId,
    required String usuarioNome,
    required String usuarioEmail,
    required String dataSolicitada,
    required String motivo,
    required String fazendaId,
  }) async {
    await _comunicacaoService.criarSolicitacaoFolga(
      usuarioId: usuarioId,
      usuarioNome: usuarioNome,
      usuarioEmail: usuarioEmail,
      dataSolicitada: dataSolicitada,
      motivo: motivo,
      fazendaId: fazendaId,
    );
  }

  /// Buscar solicitações do usuário
  Future<List<Comunicacao>> obterSolicitacoesDoUsuario(String userId, String fazendaId) async {
    return _comunicacaoService.obterSolicitacoesDoUsuario(userId, fazendaId);
  }

  /// Buscar solicitações pendentes (para gestor)
  /// Requer gestorId para filtrar na coleção unificada
  Future<List<Comunicacao>> obterSolicitacoesPendentes(String gestorId, String fazendaId) async {
    return _comunicacaoService.obterSolicitacoesPendentes(gestorId, fazendaId);
  }

  /// Buscar histórico global (aceitas + recusadas)
  Future<List<Comunicacao>> obterHistoricoGlobal(String gestorId, String fazendaId) async {
    return _comunicacaoService.obterHistoricoGlobal(gestorId, fazendaId);
  }

  /// Aprovar solicitação
  Future<void> aprovarSolicitacao(String id) async {
    await _comunicacaoService.aprovarSolicitacao(id);
  }

  /// Reprovar solicitação
  Future<void> reprovarSolicitacao(String id, String motivo) async {
    await _comunicacaoService.reprovarSolicitacao(id, motivo);
  }
}
