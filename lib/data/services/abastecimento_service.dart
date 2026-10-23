import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/abastecimento.dart';
import 'dados_legados_service.dart';

class AbastecimentoService {
  AbastecimentoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    DadosLegadosService? dadosLegadosService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _dadosLegados =
           dadosLegadosService ?? DadosLegadosService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final DadosLegadosService _dadosLegados;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('abastecimentos');

  CollectionReference<Map<String, dynamic>> _veiculos(String fazendaId) =>
      _collection.doc(fazendaId).collection('veiculos');

  /// Stream em tempo real de todos os abastecimentos de uma fazenda
  Stream<List<Abastecimento>> obterAbastecimentos(String fazendaId) {
    return _collection
        .where('fazenda_id', isEqualTo: fazendaId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Abastecimento.fromFirestore(doc))
              .toList();
        });
  }

  /// Lista os veiculos cadastrados para a fazenda.
  ///
  /// O caminho e `abastecimentos/{fazendaId}/veiculos`. Antes da leitura, os
  /// dados da estrutura antiga sao migrados de forma idempotente.
  Future<List<String>> carregarVeiculos(String fazendaId) async {
    try {
      await _dadosLegados.migrarConfiguracoesDaFazenda(fazendaId);
    } catch (erro, stackTrace) {
      // A leitura legada abaixo mantem o aplicativo utilizavel caso as regras
      // do Firestore ainda nao tenham sido atualizadas para o caminho novo.
      debugPrint('Falha ao migrar veículos: $erro');
      debugPrintStack(stackTrace: stackTrace);
    }

    final snapshot = await _veiculos(fazendaId).get();
    final porNomeNormalizado = <String, String>{};

    for (final documento in snapshot.docs) {
      final dados = documento.data();
      if (dados['ativo'] == false) continue;
      final nome = (dados['nome'] ?? '').toString().trim();
      if (nome.isEmpty) continue;
      porNomeNormalizado.putIfAbsent(
        DadosLegadosService.normalizarNomeVeiculo(nome),
        () => nome,
      );
    }

    try {
      final legados = await _dadosLegados.carregarVeiculosLegados(fazendaId);
      for (final nome in legados) {
        porNomeNormalizado.putIfAbsent(
          DadosLegadosService.normalizarNomeVeiculo(nome),
          () => nome,
        );
      }
    } catch (erro) {
      debugPrint('Não foi possível ler os veículos legados: $erro');
    }

    final veiculos = porNomeNormalizado.values.toList();
    veiculos.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return veiculos;
  }

  /// Cadastra um veiculo como documento individual, evitando duplicacoes.
  Future<void> adicionarVeiculo(String fazendaId, String nome) async {
    final nomeLimpo = nome.trim();
    if (fazendaId.trim().isEmpty || nomeLimpo.isEmpty) return;

    try {
      await _dadosLegados.migrarConfiguracoesDaFazenda(fazendaId);
    } catch (erro, stackTrace) {
      // Mesmo que a conta atual nao possa remover o legado, ainda tentamos
      // cadastrar no caminho novo (por exemplo, no acesso de funcionario).
      debugPrint('Falha ao migrar antes de adicionar veículo: $erro');
      debugPrintStack(stackTrace: stackTrace);
    }
    final normalizado = DadosLegadosService.normalizarNomeVeiculo(nomeLimpo);
    await _veiculos(
      fazendaId,
    ).doc(DadosLegadosService.idVeiculo(nomeLimpo)).set({
      'nome': nomeLimpo,
      'nome_normalizado': normalizado,
      'fazenda_id': fazendaId,
      'ativo': true,
      'data_cadastro': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Adiciona o abastecimento e, quando informada, envia a foto para o
  /// Firebase Storage antes de salvar sua URL no Firestore.
  Future<String> adicionarAbastecimento(
    Map<String, dynamic> dados, {
    File? fotoComprovante,
  }) async {
    final docRef = _collection.doc();
    Reference? fotoRef;

    try {
      final dadosParaSalvar = Map<String, dynamic>.from(dados)
        ..remove('foto_comprovante');

      if (fotoComprovante != null) {
        final fazendaId = dados['fazenda_id'] as String?;
        if (fazendaId == null || fazendaId.isEmpty) {
          throw ArgumentError(
            'A fazenda é obrigatória para salvar o comprovante.',
          );
        }

        final extensao = _extensaoDaImagem(fotoComprovante.path);
        final caminho =
            'fazendas/$fazendaId/abastecimentos/${docRef.id}/comprovante.$extensao';
        fotoRef = _storage.ref(caminho);

        await fotoRef.putFile(
          fotoComprovante,
          SettableMetadata(
            contentType: _contentTypeDaImagem(extensao),
            cacheControl: 'public,max-age=3600',
          ),
        );

        dadosParaSalvar['foto_comprovante_url'] = await fotoRef
            .getDownloadURL();
        dadosParaSalvar['foto_comprovante_path'] = caminho;
      }

      await docRef.set(dadosParaSalvar);
      return docRef.id;
    } catch (_) {
      // Se o upload terminou, mas o Firestore falhou, evita deixar um arquivo
      // sem registro ocupando espaço no Storage.
      if (fotoRef != null) {
        try {
          await fotoRef.delete();
        } catch (_) {
          // O upload pode ter falhado antes de o arquivo ser criado.
        }
      }
      rethrow;
    }
  }

  /// Excluir abastecimento
  Future<void> excluirAbastecimento(String id) async {
    if (id.isNotEmpty) {
      final docRef = _collection.doc(id);
      final snapshot = await docRef.get();
      final dados = snapshot.data();
      final caminhoFoto = dados?['foto_comprovante_path'] as String?;

      await docRef.delete();

      if (caminhoFoto != null && caminhoFoto.isNotEmpty) {
        try {
          await _storage.ref(caminhoFoto).delete();
        } on FirebaseException catch (erro) {
          if (erro.code != 'object-not-found') rethrow;
        }
      }
    }
  }

  String _extensaoDaImagem(String caminho) {
    final nome = caminho.toLowerCase();
    if (nome.endsWith('.png')) return 'png';
    if (nome.endsWith('.webp')) return 'webp';
    if (nome.endsWith('.heic') || nome.endsWith('.heif')) return 'heic';
    return 'jpg';
  }

  String _contentTypeDaImagem(String extensao) {
    switch (extensao) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
