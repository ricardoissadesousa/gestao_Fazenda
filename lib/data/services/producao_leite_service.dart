import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producao_leite.dart';

class ProducaoLeiteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _collectionProducao => _firestore.collection('producao_leite');
  CollectionReference get _collectionConfig => _firestore.collection('configuracoes');

  /// Stream de todas as produções ordenadas por data
  Stream<List<ProducaoLeite>> obterProducoes() {
    return _collectionProducao
        .orderBy('data_registro', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProducaoLeite.fromFirestore(doc)).toList();
    });
  }

  /// Buscar produções por mês/ano
  Future<List<ProducaoLeite>> obterProducoesPorMes(int mes, int ano) async {
    final dataInicio = DateTime(ano, mes, 1);
    final dataFim = DateTime(ano, mes + 1, 1);

    final result = await _collectionProducao
        .where('data_registro', isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicio))
        .where('data_registro', isLessThan: Timestamp.fromDate(dataFim))
        .get();

    return result.docs.map((doc) => ProducaoLeite.fromFirestore(doc)).toList();
  }

  /// Adicionar produção com mapa dinâmico de tanques
  Future<void> adicionarProducao(Map<String, dynamic> dados) async {
    await _collectionProducao.add(dados);
  }

  /// Obter preço do leite
  Future<double> obterPrecoLeite() async {
    final doc = await _collectionConfig.doc('fazenda').get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('preco_leite')) {
        return (data['preco_leite'] ?? 2.85).toDouble();
      }
    }
    return 2.85;
  }

  /// Atualizar preço do leite
  Future<void> atualizarPrecoLeite(double novoPreco) async {
    await _collectionConfig.doc('fazenda').set(
      {'preco_leite': novoPreco},
      SetOptions(merge: true),
    );
  }
}
