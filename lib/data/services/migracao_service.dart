import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dados_legados_service.dart';
import 'fazenda_service.dart';

/// Serviço de migração one-time para converter dados das coleções antigas
/// (notificacoes + solicitacoes_folga) para a coleção unificada (comunicacoes).
///
/// Deve ser executado uma única vez após a atualização do app.
/// É idempotente — pode ser executado múltiplas vezes com segurança.
class MigracaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _migracaoDoc =>
      _firestore.collection('migracoes').doc('app');

  DocumentReference<Map<String, dynamic>> get _migracaoDocLegado =>
      _firestore.collection('configuracoes').doc('migracao');

  Future<Map<String, dynamic>> _dadosDaMigracao() async {
    final atual = await _migracaoDoc.get();
    if (atual.exists) return atual.data() ?? {};

    final legado = await _migracaoDocLegado.get();
    final dadosLegados = legado.data();
    if (dadosLegados == null) return {};

    await _migracaoDoc.set(dadosLegados, SetOptions(merge: true));
    await _migracaoDocLegado.delete();
    return dadosLegados;
  }

  /// Verifica se a migração para comunicações já foi executada
  Future<bool> migracaoComunicacoesExecutada() async {
    final dados = await _dadosDaMigracao();
    return dados['comunicacoes_migradas'] == true;
  }

  /// Executa a migração completa de notificacoes + solicitacoes_folga → comunicacoes.
  /// Retorna o número total de documentos migrados.
  Future<int> migrarParaComunicacoes() async {
    // Verificar se já foi executada
    if (await migracaoComunicacoesExecutada()) {
      debugPrint('[Migração] Comunicações já foram migradas anteriormente.');
      return 0;
    }

    int totalMigrados = 0;

    // 1. Migrar solicitacoes_folga → comunicacoes
    totalMigrados += await _migrarSolicitacoesFolga();

    // 2. Marcar migração como concluída (não migrar notificacoes antigas pois
    //    eram apenas espelhos das solicitações e serão recriadas automaticamente)
    await _migracaoDoc.set({
      'comunicacoes_migradas': true,
      'data_migracao': FieldValue.serverTimestamp(),
      'total_documentos_migrados': totalMigrados,
    }, SetOptions(merge: true));

    debugPrint('[Migração] Concluída. Total migrados: $totalMigrados');
    return totalMigrados;
  }

  /// Migra documentos de solicitacoes_folga para comunicacoes
  Future<int> _migrarSolicitacoesFolga() async {
    final snapshot = await _firestore.collection('solicitacoes_folga').get();
    if (snapshot.docs.isEmpty) return 0;

    // Buscar gestores para criar comunicações por destinatário
    final gestoresSnapshot = await _firestore
        .collection('usuarios')
        .where('tipo', isEqualTo: 'GESTOR')
        .get();

    final gestorIds = gestoresSnapshot.docs.map((d) => d.id).toList();
    if (gestorIds.isEmpty) {
      debugPrint('[Migração] Nenhum gestor encontrado. Pulando migração.');
      return 0;
    }

    int count = 0;
    final comunicacoesCollection = _firestore.collection('comunicacoes');

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final statusOriginal = data['status'] ?? 'PENDENTE';

      // Mapear status antigo para novo
      final statusNovo = switch (statusOriginal) {
        'APROVADA' => 'ACEITO',
        'REPROVADA' => 'RECUSADO',
        'PENDENTE' => 'PENDENTE',
        _ => 'PENDENTE',
      };

      final dadosAdicionais = <String, dynamic>{
        'data_solicitada': data['data_solicitada'] ?? '',
        'motivo': data['motivo'] ?? '',
      };
      if (data['motivo_recusa'] != null) {
        dadosAdicionais['motivo_recusa'] = data['motivo_recusa'];
      }

      // Criar uma comunicação para cada gestor
      final batch = _firestore.batch();
      for (var gestorId in gestorIds) {
        final novoDoc = comunicacoesCollection.doc();
        batch.set(novoDoc, {
          'tipo': 'SOLICITACAO_FOLGA',
          'titulo': 'Solicitação de Folga',
          'mensagem':
              '${data['usuario_nome'] ?? ''} solicitou folga para ${data['data_solicitada'] ?? ''}',
          'status': statusNovo,
          'remetente_id': data['usuario_id'] ?? '',
          'remetente_nome': data['usuario_nome'] ?? '',
          'remetente_email': data['usuario_email'] ?? '',
          'destinatario_id': gestorId,
          'lida': statusOriginal != 'PENDENTE', // Já resolvidas = lidas
          'data_criacao': data['data_criacao'] ?? FieldValue.serverTimestamp(),
          'data_atualizacao': FieldValue.serverTimestamp(),
          'dados_adicionais': dadosAdicionais,
        });
        count++;
      }
      await batch.commit();
    }

    debugPrint('[Migração] Solicitações de folga migradas: $count');
    return count;
  }

  /// Migra as configuracoes antigas de todas as fazendas para os respectivos
  /// modulos. Mantido com o nome anterior para compatibilidade.
  Future<void> migrarPrecoAtualParaHistorico() async {
    final configuracoes = await _firestore.collection('configuracoes').get();
    final migrador = DadosLegadosService(firestore: _firestore);

    for (final documento in configuracoes.docs) {
      if (documento.id == 'migracao') continue;
      await migrador.migrarConfiguracoesDaFazenda(documento.id);
    }

    await _dadosDaMigracao();
    debugPrint('[Migração] Configurações antigas reorganizadas por fazenda.');
  }

  /// Vincula todos os registros sem fazenda (orfãos) à primeira fazenda do Gestor
  Future<void> migrarOrfaosParaFazenda() async {
    // Verificar se já rodou
    final dadosMigracao = await _dadosDaMigracao();
    if (dadosMigracao['fazendas_vinculadas'] == true) return;

    // Achar o primeiro Gestor
    final gestores = await _firestore
        .collection('usuarios')
        .where('tipo', isEqualTo: 'GESTOR')
        .limit(1)
        .get();
    if (gestores.docs.isEmpty) return; // Ninguem pra ser dono
    final gestorId = gestores.docs.first.id;

    // Achar primeira fazenda desse gestor, senão criar
    final fazendas = await _firestore
        .collection('fazendas')
        .where('proprietario_id', isEqualTo: gestorId)
        .limit(1)
        .get();
    String fazendaId;
    if (fazendas.docs.isNotEmpty) {
      fazendaId = fazendas.docs.first.id;
    } else {
      final novaFazenda = await _firestore.collection('fazendas').add({
        'nome': 'Fazenda Principal',
        'proprietario_id': gestorId,
        'ativa': true,
      });
      fazendaId = novaFazenda.id;
    }

    // Listar collections e atualizar
    final collections = [
      'animais',
      'producao_leite',
      'abastecimentos',
      'comunicacoes',
    ];

    for (var col in collections) {
      final snapshot = await _firestore.collection(col).get();
      final orfaos = snapshot.docs.where((documento) {
        final docData = documento.data();
        return docData['fazenda_id'] == null ||
            docData['fazenda_id'].toString().isEmpty;
      }).toList();

      for (var inicio = 0; inicio < orfaos.length; inicio += 490) {
        final fim = (inicio + 490 < orfaos.length)
            ? inicio + 490
            : orfaos.length;
        final batch = _firestore.batch();
        for (final documento in orfaos.sublist(inicio, fim)) {
          batch.update(documento.reference, {'fazenda_id': fazendaId});
        }
        await batch.commit();
      }
    }

    await _migracaoDoc.set({
      'fazendas_vinculadas': true,
    }, SetOptions(merge: true));
    debugPrint(
      '[Migração] Vinculação de fazendas orfãs concluída para fazenda: $fazendaId',
    );
  }

  /// Gera códigos de vínculo para fazendas existentes que não possuem código
  Future<void> migrarCodigosVinculo() async {
    final dadosMigracao = await _dadosDaMigracao();
    if (dadosMigracao['codigos_vinculo_gerados'] == true) return;

    final fazendaService = FazendaService();
    await fazendaService.gerarCodigosParaFazendasExistentes();

    await _migracaoDoc.set({
      'codigos_vinculo_gerados': true,
    }, SetOptions(merge: true));
    debugPrint(
      '[Migração] Códigos de vínculo gerados para fazendas existentes',
    );
  }
}
