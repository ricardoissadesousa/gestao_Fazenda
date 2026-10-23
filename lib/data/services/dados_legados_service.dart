import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/historico_preco.dart';

/// Migra os dados que, nas versoes anteriores, ficavam agrupados em
/// `configuracoes/{fazendaId}`.
///
/// A copia usa IDs deterministicos e pode ser repetida sem duplicar dados. Os
/// documentos antigos so sao apagados depois que todos os destinos forem
/// conferidos.
class DadosLegadosService {
  DadosLegadosService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _configuracaoLegada(
    String fazendaId,
  ) => _firestore.collection('configuracoes').doc(fazendaId);

  CollectionReference<Map<String, dynamic>> _veiculos(String fazendaId) =>
      _firestore
          .collection('abastecimentos')
          .doc(fazendaId)
          .collection('veiculos');

  CollectionReference<Map<String, dynamic>> _precosDoLeite(String fazendaId) =>
      _firestore
          .collection('producao_leite')
          .doc(fazendaId)
          .collection('preco_do_leite');

  /// Caminho usado temporariamente durante a reorganizacao anterior.
  CollectionReference<Map<String, dynamic>> _historicoIntermediario(
    String fazendaId,
  ) => _firestore
      .collection('producao_leite')
      .doc(fazendaId)
      .collection('historico_precos');

  /// Move veiculos e historico de precos para os respectivos modulos.
  Future<void> migrarConfiguracoesDaFazenda(String fazendaId) async {
    if (fazendaId.trim().isEmpty) return;

    final configuracaoRef = _configuracaoLegada(fazendaId);
    final configuracao = await configuracaoRef.get();
    final historicoLegado = await configuracaoRef
        .collection('historico_precos')
        .get();
    final historicoIntermediario = await _historicoIntermediario(
      fazendaId,
    ).get();
    final dados = configuracao.data();

    if (dados == null &&
        historicoLegado.docs.isEmpty &&
        historicoIntermediario.docs.isEmpty) {
      return;
    }

    final nomesVeiculos = _extrairVeiculos(dados?['veiculos']);
    final veiculosJaExistentes = await _veiculos(fazendaId).get();
    final idsVeiculosJaExistentes = veiculosJaExistentes.docs
        .map((documento) => documento.id)
        .toSet();
    final historicoJaExistente = await _precosDoLeite(fazendaId).get();
    final idsHistoricoJaExistentes = historicoJaExistente.docs
        .map((documento) => documento.id)
        .toSet();
    final documentosVeiculos = <_DocumentoParaSalvar>[];
    final documentosHistorico = <_DocumentoParaSalvar>[];

    for (final nome in nomesVeiculos) {
      final normalizado = normalizarNomeVeiculo(nome);
      final id = idVeiculo(nome);
      if (idsVeiculosJaExistentes.contains(id)) continue;
      documentosVeiculos.add(
        _DocumentoParaSalvar(
          referencia: _veiculos(fazendaId).doc(id),
          dados: {
            'nome': nome,
            'nome_normalizado': normalizado,
            'fazenda_id': fazendaId,
            'ativo': true,
            'data_cadastro': FieldValue.serverTimestamp(),
          },
        ),
      );
    }

    final fontesPorPeriodo = <String, Map<String, dynamic>>{};
    for (final documento in historicoLegado.docs) {
      fontesPorPeriodo[documento.id] = documento.data();
    }
    // O caminho intermediario e mais recente e prevalece em caso de conflito.
    for (final documento in historicoIntermediario.docs) {
      fontesPorPeriodo[documento.id] = documento.data();
    }

    final idsHistoricoEsperados = <String>{};
    for (final entrada in fontesPorPeriodo.entries) {
      final dadosHistorico = _normalizarDadosPreco(
        id: entrada.key,
        dados: entrada.value,
        fazendaId: fazendaId,
      );
      if (dadosHistorico == null) continue;
      idsHistoricoEsperados.add(entrada.key);
      if (idsHistoricoJaExistentes.contains(entrada.key)) continue;
      documentosHistorico.add(
        _DocumentoParaSalvar(
          referencia: _precosDoLeite(fazendaId).doc(entrada.key),
          dados: dadosHistorico,
        ),
      );
    }

    final precoAtual = _numeroComoDouble(dados?['preco_leite']);
    if (precoAtual != null && precoAtual > 0) {
      final agora = DateTime.now();
      final idAtual = HistoricoPreco.gerarId(agora.month, agora.year);
      final destinoAtual = _precosDoLeite(fazendaId).doc(idAtual);
      final jaEstaNaCopia = idsHistoricoEsperados.contains(idAtual);
      final jaExisteNoDestino = idsHistoricoJaExistentes.contains(idAtual);

      if (!jaEstaNaCopia && !jaExisteNoDestino) {
        idsHistoricoEsperados.add(idAtual);
        documentosHistorico.add(
          _DocumentoParaSalvar(
            referencia: destinoAtual,
            dados: {
              'preco': precoAtual,
              'mes': agora.month,
              'ano': agora.year,
              'fazenda_id': fazendaId,
              'data_atualizacao': FieldValue.serverTimestamp(),
            },
          ),
        );
      }
    }

    // Os lotes sao separados para que um funcionario ainda consiga migrar os
    // veiculos mesmo sem permissao gerencial para alterar precos do leite.
    await _salvarEmLotes(documentosVeiculos);
    await _salvarEmLotes(documentosHistorico);
    await _validarCopia(
      fazendaId: fazendaId,
      nomesVeiculos: nomesVeiculos,
      idsHistorico: idsHistoricoEsperados,
    );

    await _excluirEmLotes([
      ...historicoLegado.docs.map((documento) => documento.reference),
      ...historicoIntermediario.docs.map((documento) => documento.reference),
    ]);
    if (configuracao.exists) {
      await configuracaoRef.delete();
    }
  }

  Future<List<String>> carregarVeiculosLegados(String fazendaId) async {
    final documento = await _configuracaoLegada(fazendaId).get();
    return _extrairVeiculos(documento.data()?['veiculos']);
  }

  Future<double?> obterPrecoLegadoPorPeriodo(
    String fazendaId,
    int mes,
    int ano,
  ) async {
    final id = HistoricoPreco.gerarId(mes, ano);
    final periodoIntermediario = await _historicoIntermediario(
      fazendaId,
    ).doc(id).get();
    if (periodoIntermediario.exists) {
      return _numeroComoDouble(periodoIntermediario.data()?['preco']);
    }

    final configuracaoRef = _configuracaoLegada(fazendaId);
    final periodo = await configuracaoRef
        .collection('historico_precos')
        .doc(id)
        .get();

    if (periodo.exists) {
      return _numeroComoDouble(periodo.data()?['preco']);
    }

    // O antigo preco global so representa a competencia corrente. Usa-lo em
    // qualquer mes faria todos os meses aparentarem ter o mesmo valor.
    final agora = DateTime.now();
    if (mes != agora.month || ano != agora.year) return null;

    final configuracao = await configuracaoRef.get();
    return _numeroComoDouble(configuracao.data()?['preco_leite']);
  }

  Future<List<HistoricoPreco>> carregarHistoricoLegado(String fazendaId) async {
    final legado = await _configuracaoLegada(
      fazendaId,
    ).collection('historico_precos').get();
    final intermediario = await _historicoIntermediario(fazendaId).get();
    final porId = <String, HistoricoPreco>{
      for (final documento in legado.docs)
        documento.id: HistoricoPreco.fromFirestore(documento),
      for (final documento in intermediario.docs)
        documento.id: HistoricoPreco.fromFirestore(documento),
    };
    return porId.values.toList();
  }

  static String normalizarNomeVeiculo(String nome) =>
      nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String idVeiculo(String nome) =>
      'veiculo_${Uri.encodeComponent(normalizarNomeVeiculo(nome))}';

  List<String> _extrairVeiculos(Object? valor) {
    if (valor is! Iterable) return [];

    final porNomeNormalizado = <String, String>{};
    for (final item in valor) {
      final nome = item.toString().trim();
      if (nome.isEmpty) continue;
      porNomeNormalizado.putIfAbsent(normalizarNomeVeiculo(nome), () => nome);
    }

    final nomes = porNomeNormalizado.values.toList();
    nomes.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return nomes;
  }

  double? _numeroComoDouble(Object? valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString().replaceAll(',', '.') ?? '');
  }

  int? _numeroComoInt(Object? valor) {
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }

  Map<String, dynamic>? _normalizarDadosPreco({
    required String id,
    required Map<String, dynamic> dados,
    required String fazendaId,
  }) {
    final partesId = id.split('-');
    final anoId = partesId.length == 2 ? int.tryParse(partesId[0]) : null;
    final mesId = partesId.length == 2 ? int.tryParse(partesId[1]) : null;
    final preco = _numeroComoDouble(dados['preco']);
    final mes = _numeroComoInt(dados['mes']) ?? mesId;
    final ano = _numeroComoInt(dados['ano']) ?? anoId;

    if (preco == null || preco <= 0 || mes == null || ano == null) {
      return null;
    }

    return {
      'preco': preco,
      'mes': mes,
      'ano': ano,
      'fazenda_id': fazendaId,
      'data_atualizacao':
          dados['data_atualizacao'] ?? FieldValue.serverTimestamp(),
    };
  }

  Future<void> _salvarEmLotes(List<_DocumentoParaSalvar> documentos) async {
    const tamanhoMaximo = 400;
    for (var inicio = 0; inicio < documentos.length; inicio += tamanhoMaximo) {
      final fim = (inicio + tamanhoMaximo < documentos.length)
          ? inicio + tamanhoMaximo
          : documentos.length;
      final batch = _firestore.batch();
      for (final documento in documentos.sublist(inicio, fim)) {
        batch.set(
          documento.referencia,
          documento.dados,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<void> _validarCopia({
    required String fazendaId,
    required List<String> nomesVeiculos,
    required Set<String> idsHistorico,
  }) async {
    final veiculosCopiados = await _veiculos(fazendaId).get();
    final idsVeiculosCopiados = veiculosCopiados.docs
        .map((documento) => documento.id)
        .toSet();
    final idsVeiculosEsperados = nomesVeiculos.map(idVeiculo).toSet();

    if (!idsVeiculosCopiados.containsAll(idsVeiculosEsperados)) {
      throw StateError('A migracao dos veiculos nao foi validada.');
    }

    final historicoCopiado = await _precosDoLeite(fazendaId).get();
    final idsHistoricoCopiados = historicoCopiado.docs
        .map((documento) => documento.id)
        .toSet();
    if (!idsHistoricoCopiados.containsAll(idsHistorico)) {
      throw StateError('A migracao do historico de precos nao foi validada.');
    }
  }

  Future<void> _excluirEmLotes(
    List<DocumentReference<Map<String, dynamic>>> referencias,
  ) async {
    const tamanhoMaximo = 400;
    for (var inicio = 0; inicio < referencias.length; inicio += tamanhoMaximo) {
      final fim = (inicio + tamanhoMaximo < referencias.length)
          ? inicio + tamanhoMaximo
          : referencias.length;
      final batch = _firestore.batch();
      for (final referencia in referencias.sublist(inicio, fim)) {
        batch.delete(referencia);
      }
      await batch.commit();
    }
  }
}

class _DocumentoParaSalvar {
  const _DocumentoParaSalvar({required this.referencia, required this.dados});

  final DocumentReference<Map<String, dynamic>> referencia;
  final Map<String, dynamic> dados;
}
