import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/fazenda.dart';
import '../data/services/fazenda_service.dart';

class FazendaProvider extends ChangeNotifier {
  final FazendaService _fazendaService = FazendaService();

  List<Fazenda> _fazendas = [];
  List<Fazenda> get fazendas => _fazendas;

  Fazenda? _fazendaSelecionada;
  Fazenda? get fazendaSelecionada => _fazendaSelecionada;

  bool _loading = false;
  bool get loading => _loading;

  String? _erro;
  String? get erro => _erro;

  StreamSubscription? _fazendaSubscription;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  FazendaProvider();

  @override
  void dispose() {
    _fazendaSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  //  Fazendas
  // ============================================================

  void carregarFazendas() {
    final uid = _currentUserId;
    if (uid == null) return;

    _fazendaSubscription?.cancel();
    _fazendaSubscription = _fazendaService.obterFazendas(uid).listen(
      (lista) {
        _fazendas = lista;
        if (_fazendaSelecionada != null) {
          try {
            // Atualiza para a instância mais recente da lista
            _fazendaSelecionada = lista.firstWhere((f) => f.id == _fazendaSelecionada!.id);
          } catch (_) {
            _fazendaSelecionada = lista.isNotEmpty ? lista.first : null;
          }
        } else {
          _fazendaSelecionada = lista.isNotEmpty ? lista.first : null;
        }
        notifyListeners();
      },
      onError: (e) {
        _erro = e.toString();
        notifyListeners();
      },
    );
  }

  void selecionarFazenda(Fazenda fazenda) {
    _fazendaSelecionada = fazenda;
    notifyListeners();
  }

  Future<bool> adicionarFazenda(Fazenda fazenda) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    _loading = true;
    notifyListeners();

    try {
      final nova = fazenda.copyWith(proprietarioId: uid);
      await _fazendaService.adicionarFazenda(nova);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarFazenda(Fazenda fazenda) async {
    _loading = true;
    notifyListeners();

    try {
      await _fazendaService.atualizarFazenda(fazenda);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> desativarFazenda(String fazendaId) async {
    try {
      await _fazendaService.desativarFazenda(fazendaId);
      return true;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Regenerar código de vínculo de uma fazenda
  Future<String?> regenerarCodigo(String fazendaId) async {
    try {
      final novoCodigo = await _fazendaService.regenerarCodigo(fazendaId);
      return novoCodigo;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    }
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}
