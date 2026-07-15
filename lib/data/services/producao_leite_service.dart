import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producao_leite.dart';
import 'configuracao_service.dart';

class ProducaoLeiteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfiguracaoService _configService = ConfiguracaoService();
  CollectionReference get _collectionProducao => _firestore.collection('producao_leite');

  /// Stream de todas as produções ordenadas por data (filtrado por fazenda)
  Stream<List<ProducaoLeite>> obterProducoes(String fazendaId) {
    return _collectionProducao
        .where('fazenda_id', isEqualTo: fazendaId)
        .orderBy('data_registro', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProducaoLeite.fromFirestore(doc)).toList();
    });
  }

  Future<List<ProducaoLeite>> obterProducoesPorMes(int mes, int ano, String fazendaId) async {
    // Buscar todas as produções da fazenda e filtrar por mês/ano no client
    // Isso evita a necessidade de um índice composto no Firestore
    final result = await _collectionProducao
        .where('fazenda_id', isEqualTo: fazendaId)
        .get();

    return result.docs
        .map((doc) => ProducaoLeite.fromFirestore(doc))
        .where((p) {
          if (p.data == null) return false;
          return p.data!.year == ano && p.data!.month == mes;
        })
        .toList();
  }

  /// Adicionar produção com mapa dinâmico de tanques
  Future<void> adicionarProducao(Map<String, dynamic> dados) async {
    await _collectionProducao.add(dados);
  }

  /// Obter preço do leite atual (delega para ConfiguracaoService)
  Future<double> obterPrecoLeite(String fazendaId) async {
    return _configService.obterPrecoLeite(fazendaId);
  }

  /// Obter preço do leite por período (delega para ConfiguracaoService)
  Future<double> obterPrecoLeitePorPeriodo(String fazendaId, int mes, int ano) async {
    return _configService.obterPrecoLeitePorPeriodo(fazendaId, mes, ano);
  }

  /// Atualizar preço do leite (delega para ConfiguracaoService)
  Future<void> atualizarPrecoLeite(String fazendaId, double novoPreco, {int? mes, int? ano}) async {
    await _configService.salvarPrecoLeite(fazendaId, novoPreco, mes: mes, ano: ano);
  }
}
