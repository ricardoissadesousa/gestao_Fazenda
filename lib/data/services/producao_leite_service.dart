import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/historico_preco.dart';
import '../models/producao_leite.dart';
import 'dados_legados_service.dart';

class ProducaoLeiteService {
  ProducaoLeiteService({
    FirebaseFirestore? firestore,
    DadosLegadosService? dadosLegadosService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _dadosLegados =
           dadosLegadosService ?? DadosLegadosService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final DadosLegadosService _dadosLegados;

  CollectionReference<Map<String, dynamic>> get _collectionProducao =>
      _firestore.collection('producao_leite');

  CollectionReference<Map<String, dynamic>> _precosDoLeite(String fazendaId) =>
      _collectionProducao.doc(fazendaId).collection('preco_do_leite');

  /// Stream de todas as producoes ordenadas por data (filtrado por fazenda).
  Stream<List<ProducaoLeite>> obterProducoes(String fazendaId) {
    return _collectionProducao
        .where('fazenda_id', isEqualTo: fazendaId)
        .orderBy('data_registro', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProducaoLeite.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<ProducaoLeite>> obterProducoesPorMes(
    int mes,
    int ano,
    String fazendaId,
  ) async {
    // O filtro de mes/ano fica no cliente para nao exigir outro indice
    // composto no Firestore.
    final result = await _collectionProducao
        .where('fazenda_id', isEqualTo: fazendaId)
        .get();

    return result.docs.map((doc) => ProducaoLeite.fromFirestore(doc)).where((
      producao,
    ) {
      final data = producao.data;
      return data != null && data.year == ano && data.month == mes;
    }).toList();
  }

  /// Adiciona uma producao com mapa dinamico de tanques.
  Future<void> adicionarProducao(Map<String, dynamic> dados) async {
    await _collectionProducao.add(dados);
  }

  /// Obtem exclusivamente o preco da competencia atual.
  Future<double> obterPrecoLeite(String fazendaId) async {
    final agora = DateTime.now();
    return obterPrecoLeitePorPeriodo(fazendaId, agora.month, agora.year);
  }

  /// Obtem o preco de uma competencia especifica.
  Future<double> obterPrecoLeitePorPeriodo(
    String fazendaId,
    int mes,
    int ano,
  ) async {
    await _tentarMigrarDadosLegados(fazendaId);

    final id = HistoricoPreco.gerarId(mes, ano);
    final periodo = await _precosDoLeite(fazendaId).doc(id).get();
    if (periodo.exists) {
      return HistoricoPreco.fromFirestore(periodo).preco;
    }

    final legado = await _dadosLegados.obterPrecoLegadoPorPeriodo(
      fazendaId,
      mes,
      ano,
    );
    if (legado != null) return legado;

    // Cada competencia e independente. Nao reutiliza o ultimo preco salvo,
    // pois isso faria a alteracao de um mes aparecer nos demais.
    return 2.85;
  }

  /// Cria ou atualiza o preco em
  /// `producao_leite/{fazendaId}/preco_do_leite/{AAAA-MM}`.
  Future<void> atualizarPrecoLeite(
    String fazendaId,
    double novoPreco, {
    int? mes,
    int? ano,
  }) async {
    await _tentarMigrarDadosLegados(fazendaId);

    final agora = DateTime.now();
    final mesFinal = mes ?? agora.month;
    final anoFinal = ano ?? agora.year;
    final historico = HistoricoPreco(
      id: HistoricoPreco.gerarId(mesFinal, anoFinal),
      preco: novoPreco,
      mes: mesFinal,
      ano: anoFinal,
    );

    await _precosDoLeite(fazendaId).doc(historico.id).set({
      ...historico.toFirestore(),
      'fazenda_id': fazendaId,
    });
  }

  Future<List<HistoricoPreco>> obterHistoricoPrecos(String fazendaId) async {
    await _tentarMigrarDadosLegados(fazendaId);

    final snapshot = await _precosDoLeite(
      fazendaId,
    ).orderBy(FieldPath.documentId, descending: true).get();
    final porId = <String, HistoricoPreco>{
      for (final documento in snapshot.docs)
        documento.id: HistoricoPreco.fromFirestore(documento),
    };

    // Em caso de regra antiga ou migracao interrompida, o legado funciona como
    // fallback sem sobrescrever o que ja existe na estrutura nova.
    try {
      final legados = await _dadosLegados.carregarHistoricoLegado(fazendaId);
      for (final item in legados) {
        porId.putIfAbsent(item.id, () => item);
      }
    } catch (erro) {
      debugPrint('Nao foi possivel ler o historico legado: $erro');
    }

    final historico = porId.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return historico;
  }

  Stream<List<HistoricoPreco>> streamHistoricoPrecos(String fazendaId) async* {
    await _tentarMigrarDadosLegados(fazendaId);
    yield* _precosDoLeite(fazendaId)
        .orderBy(FieldPath.documentId, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HistoricoPreco.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> _tentarMigrarDadosLegados(String fazendaId) async {
    try {
      await _dadosLegados.migrarConfiguracoesDaFazenda(fazendaId);
    } catch (erro, stackTrace) {
      debugPrint('Falha ao migrar configuracoes da fazenda: $erro');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
