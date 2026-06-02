import 'package:cloud_firestore/cloud_firestore.dart';

class ConfiguracaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference get _docFazenda =>
      _firestore.collection('configuracoes').doc('fazenda');

  /// Carregar lista de equipamentos/veículos
  Future<List<String>> carregarEquipamentos() async {
    final doc = await _docFazenda.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('veiculos')) {
        return List<String>.from(data['veiculos'] ?? []);
      }
    }
    // Lista padrão se não existir
    final padroes = [
      'Trator MF 275',
      'Trator MF 283',
      'Caminhão 3/4',
      'Retroescavadeira',
      'Motocicleta',
    ];
    await _docFazenda.set({'veiculos': padroes}, SetOptions(merge: true));
    return padroes;
  }

  /// Adicionar novo veículo
  Future<void> adicionarVeiculo(String nome) async {
    await _docFazenda.update({
      'veiculos': FieldValue.arrayUnion([nome]),
    }).catchError((_) async {
      // Se o doc não existir, cria com set
      final equipamentos = await carregarEquipamentos();
      equipamentos.add(nome);
      await _docFazenda.set(
        {'veiculos': equipamentos},
        SetOptions(merge: true),
      );
    });
  }

  /// Obter preço do leite
  Future<double> obterPrecoLeite() async {
    final doc = await _docFazenda.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('preco_leite')) {
        return (data['preco_leite'] ?? 2.85).toDouble();
      }
    }
    return 2.85;
  }

  /// Salvar preço do leite
  Future<void> salvarPrecoLeite(double preco) async {
    await _docFazenda.set({'preco_leite': preco}, SetOptions(merge: true));
  }
}
