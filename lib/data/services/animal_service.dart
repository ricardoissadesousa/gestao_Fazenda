import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal.dart';

class AnimalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _collection => _firestore.collection('animais');

  /// Stream em tempo real de todos os animais
  Stream<List<Animal>> obterAnimais() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Animal.fromFirestore(doc)).toList();
    });
  }

  /// Adicionar animal
  Future<void> adicionarAnimal(Animal animal) async {
    final docRef = _collection.doc();
    final data = animal.toFirestore();
    data['id'] = docRef.id;
    await docRef.set(data);
  }

  /// Atualizar animal
  Future<void> atualizarAnimal(Animal animal) async {
    if (animal.id.isNotEmpty) {
      final data = animal.toFirestore();
      data['id'] = animal.id;
      await _collection.doc(animal.id).set(data);
    }
  }

  /// Excluir animal
  Future<void> excluirAnimal(Animal animal) async {
    if (animal.id.isNotEmpty) {
      await _collection.doc(animal.id).delete();
    }
  }

  /// Verificar se número já existe (exceto o animal sendo editado)
  Future<bool> numeroExiste(String numero, {String? excluirId}) async {
    final query = await _collection.where('numero', isEqualTo: numero).get();
    if (excluirId != null) {
      return query.docs.any((doc) => doc.id != excluirId);
    }
    return query.docs.isNotEmpty;
  }

  /// Verificar se nome já existe (exceto o animal sendo editado)
  Future<bool> nomeExiste(String nome, {String? excluirId}) async {
    final query = await _collection.where('nome', isEqualTo: nome).get();
    if (excluirId != null) {
      return query.docs.any((doc) => doc.id != excluirId);
    }
    return query.docs.isNotEmpty;
  }
}
