import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/historico_preco.dart';

class ConfiguracaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference _docFazenda(String fazendaId) =>
      _firestore.collection('configuracoes').doc(fazendaId);

  /// Referência à subcoleção de histórico de preços
  CollectionReference _historicoPrecos(String fazendaId) =>
      _docFazenda(fazendaId).collection('historico_precos');

  /// Carregar lista de equipamentos/veículos
  Future<List<String>> carregarEquipamentos(String fazendaId) async {
    final doc = await _docFazenda(fazendaId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('veiculos')) {
        return List<String>.from(data['veiculos'] ?? []);
      }
    }
    // Lista vazia se não existir (o próprio usuário cadastra)
    return [];
  }

  /// Adicionar novo veículo
  Future<void> adicionarVeiculo(String fazendaId, String nome) async {
    await _docFazenda(fazendaId).update({
      'veiculos': FieldValue.arrayUnion([nome]),
    }).catchError((_) async {
      // Se o doc não existir, cria com set
      final equipamentos = await carregarEquipamentos(fazendaId);
      equipamentos.add(nome);
      await _docFazenda(fazendaId).set(
        {'veiculos': equipamentos},
        SetOptions(merge: true),
      );
    });
  }

  // ============================================================
  //  PREÇO DO LEITE — Com Histórico por Período
  // ============================================================

  /// Obter preço atual do leite (atalho rápido)
  Future<double> obterPrecoLeite(String fazendaId) async {
    final doc = await _docFazenda(fazendaId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('preco_leite')) {
        return (data['preco_leite'] ?? 2.85).toDouble();
      }
    }
    return 2.85;
  }

  /// Obter preço do leite de um mês/ano específico.
  /// Se não encontrar registro para o período, retorna o preço atual.
  Future<double> obterPrecoLeitePorPeriodo(String fazendaId, int mes, int ano) async {
    final id = HistoricoPreco.gerarId(mes, ano);
    final doc = await _historicoPrecos(fazendaId).doc(id).get();
    if (doc.exists) {
      final historico = HistoricoPreco.fromFirestore(doc);
      return historico.preco;
    }
    // Fallback: retorna preço atual
    return obterPrecoLeite(fazendaId);
  }

  /// Salvar preço do leite — cria/atualiza o registro no histórico para o mês/ano informados.
  Future<void> salvarPrecoLeite(String fazendaId, double preco, {int? mes, int? ano}) async {
    final now = DateTime.now();
    final mesFinal = mes ?? now.month;
    final anoFinal = ano ?? now.year;

    // Foi REMOVIDO a atualização do preço global ('preco_leite' em _docFazenda)
    // para que a edição do preço em um mês específico não altere os demais meses.

    // Salvar no histórico com ID = "YYYY-MM"
    final id = HistoricoPreco.gerarId(mesFinal, anoFinal);
    final historico = HistoricoPreco(
      id: id,
      preco: preco,
      mes: mesFinal,
      ano: anoFinal,
    );
    await _historicoPrecos(fazendaId).doc(id).set(historico.toFirestore());
  }

  /// Obter histórico completo de preços, ordenado por data (mais recente primeiro)
  Future<List<HistoricoPreco>> obterHistoricoPrecos(String fazendaId) async {
    final snapshot = await _historicoPrecos(fazendaId)
        .orderBy('ano', descending: true)
        .orderBy('mes', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => HistoricoPreco.fromFirestore(doc))
        .toList();
  }

  /// Stream em tempo real do histórico de preços
  Stream<List<HistoricoPreco>> streamHistoricoPrecos(String fazendaId) {
    return _historicoPrecos(fazendaId)
        .orderBy('ano', descending: true)
        .orderBy('mes', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HistoricoPreco.fromFirestore(doc))
          .toList();
    });
  }
}
