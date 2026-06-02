import 'package:flutter/material.dart';
import '../data/models/abastecimento.dart';
import '../data/services/abastecimento_service.dart';

class AbastecimentoProvider extends ChangeNotifier {
  final AbastecimentoService _service = AbastecimentoService();

  List<Abastecimento> _listaCompleta = [];
  List<Abastecimento> get listaCompleta => _listaCompleta;

  bool _loading = false;
  bool get loading => _loading;

  AbastecimentoProvider() {
    carregarAbastecimentos();
  }

  void carregarAbastecimentos() {
    _service.obterAbastecimentos().listen((lista) {
      _listaCompleta = lista;
      notifyListeners();
    });
  }
}
