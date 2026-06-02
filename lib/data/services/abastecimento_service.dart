import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/abastecimento.dart';

class AbastecimentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _collection => _firestore.collection('abastecimentos');

  /// Stream em tempo real de todos os abastecimentos
  Stream<List<Abastecimento>> obterAbastecimentos() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Abastecimento.fromFirestore(doc)).toList();
    });
  }

  /// Adicionar abastecimento
  Future<void> adicionarAbastecimento(Map<String, dynamic> dados) async {
    await _collection.add(dados);
  }

  /// Excluir abastecimento
  Future<void> excluirAbastecimento(String id) async {
    if (id.isNotEmpty) {
      await _collection.doc(id).delete();
    }
  }
}
