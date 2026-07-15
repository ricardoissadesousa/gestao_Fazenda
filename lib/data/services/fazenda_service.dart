import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fazenda.dart';

class FazendaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _collection => _firestore.collection('fazendas');

  /// Gera um código alfanumérico de 6 caracteres (maiúsculas + dígitos)
  String _gerarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sem I/O/0/1 para evitar confusão
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Gera um código que não existe em nenhuma fazenda ativa
  Future<String> gerarCodigoUnico() async {
    String codigo;
    bool existe;
    do {
      codigo = _gerarCodigo();
      final query = await _collection
          .where('codigo_vinculo', isEqualTo: codigo)
          .where('ativa', isEqualTo: true)
          .limit(1)
          .get();
      existe = query.docs.isNotEmpty;
    } while (existe);
    return codigo;
  }

  /// Stream em tempo real das fazendas do proprietário
  Stream<List<Fazenda>> obterFazendas(String proprietarioId) {
    return _collection
        .where('proprietario_id', isEqualTo: proprietarioId)
        .where('ativa', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Fazenda.fromFirestore(doc)).toList();
    });
  }

  /// Buscar fazendas do proprietário (Future)
  Future<List<Fazenda>> buscarFazendas(String proprietarioId) async {
    final result = await _collection
        .where('proprietario_id', isEqualTo: proprietarioId)
        .where('ativa', isEqualTo: true)
        .get();
    return result.docs.map((doc) => Fazenda.fromFirestore(doc)).toList();
  }

  /// Buscar fazenda pelo código de vínculo
  Future<Fazenda?> buscarPorCodigo(String codigo) async {
    final codigoUpper = codigo.toUpperCase().trim();
    final query = await _collection
        .where('codigo_vinculo', isEqualTo: codigoUpper)
        .where('ativa', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Fazenda.fromFirestore(query.docs.first);
  }

  /// Adicionar nova fazenda (gera código de vínculo automaticamente)
  Future<String> adicionarFazenda(Fazenda fazenda) async {
    final codigo = await gerarCodigoUnico();
    final novaFazenda = fazenda.copyWith(codigoVinculo: codigo);
    final docRef = await _collection.add(novaFazenda.toFirestore());
    return docRef.id;
  }

  /// Atualizar fazenda
  Future<void> atualizarFazenda(Fazenda fazenda) async {
    if (fazenda.id.isNotEmpty) {
      await _collection.doc(fazenda.id).update({
        'nome': fazenda.nome,
        'endereco': fazenda.endereco,
      });
    }
  }

  /// Desativar fazenda (soft delete)
  Future<void> desativarFazenda(String fazendaId) async {
    await _collection.doc(fazendaId).update({'ativa': false});
  }

  /// Regenerar código de vínculo de uma fazenda
  Future<String> regenerarCodigo(String fazendaId) async {
    final novoCodigo = await gerarCodigoUnico();
    await _collection.doc(fazendaId).update({'codigo_vinculo': novoCodigo});
    return novoCodigo;
  }

  /// Verificar se o nome da fazenda já existe para este proprietário
  Future<bool> nomeExiste(String nome, String proprietarioId, {String? excluirId}) async {
    final query = await _collection
        .where('proprietario_id', isEqualTo: proprietarioId)
        .where('nome', isEqualTo: nome)
        .where('ativa', isEqualTo: true)
        .get();
    if (excluirId != null) {
      return query.docs.any((doc) => doc.id != excluirId);
    }
    return query.docs.isNotEmpty;
  }

  /// Gera código de vínculo para fazendas existentes que não possuem código
  Future<void> gerarCodigosParaFazendasExistentes() async {
    final snapshot = await _collection.where('ativa', isEqualTo: true).get();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final codigoAtual = data['codigo_vinculo'] ?? '';
      if (codigoAtual.toString().isEmpty) {
        final novoCodigo = await gerarCodigoUnico();
        await _collection.doc(doc.id).update({'codigo_vinculo': novoCodigo});
      }
    }
  }
}
