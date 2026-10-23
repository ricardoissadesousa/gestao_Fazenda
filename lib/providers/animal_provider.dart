import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/app_error_messages.dart';
import '../data/models/animal.dart';
import '../data/services/animal_service.dart';

class AnimalProvider extends ChangeNotifier {
  final AnimalService _service = AnimalService();

  List<Animal> _listaCompleta = [];
  List<Animal> _animaisFiltrados = [];
  List<Animal> get animais => _animaisFiltrados;

  String _termoBusca = '';
  int _mesFiltro = 0; // 0 = Todos
  int _anoFiltro = 0; // 0 = Todos

  bool _loading = false;
  bool get loading => _loading;

  String? _erro;
  String? get erro => _erro;

  AnimalProvider();

  StreamSubscription? _subscription;

  void carregarAnimaisFazenda(String fazendaId) {
    _subscription?.cancel();
    _loading = true;
    _erro = null;
    notifyListeners();

    _subscription = _service.obterAnimais(fazendaId).listen((lista) {
      _listaCompleta = lista;
      _aplicarFiltros();
      _loading = false;
      _erro = null;
      notifyListeners();
    }, onError: (e) {
      _erro = AppErrorMessages.from(
        e,
        fallback: 'Não foi possível carregar os animais. Tente novamente.',
      );
      _loading = false;
      notifyListeners();
    });
  }

  void filtrar(String query) {
    _termoBusca = query;
    _aplicarFiltros();
    notifyListeners();
  }

  void filtrarPorMes(int mesIndex) {
    _mesFiltro = mesIndex;
    _aplicarFiltros();
    notifyListeners();
  }

  void filtrarPorAno(int ano) {
    _anoFiltro = ano;
    _aplicarFiltros();
    notifyListeners();
  }

  void _aplicarFiltros() {
    var lista = _listaCompleta;

    if (_termoBusca.isNotEmpty) {
      lista = lista.where((animal) {
        return animal.nome.toLowerCase().contains(_termoBusca.toLowerCase()) ||
            animal.numero.toLowerCase().contains(_termoBusca.toLowerCase());
      }).toList();
    }

    if (_mesFiltro > 0) {
      lista = lista.where((animal) {
        final partes = animal.nascimento.split('/');
        if (partes.length >= 2) {
          final mes = int.tryParse(partes[1]);
          return mes == _mesFiltro;
        }
        return false;
      }).toList();
    }

    if (_anoFiltro > 0) {
      lista = lista.where((animal) {
        final partes = animal.nascimento.split('/');
        if (partes.length >= 3) {
          final ano = int.tryParse(partes[2]);
          return ano == _anoFiltro;
        }
        return false;
      }).toList();
    }

    _animaisFiltrados = lista;
  }

  Future<bool> excluirAnimal(Animal animal) async {
    try {
      await _service.excluirAnimal(animal);
      _erro = null;
      return true;
    } catch (e) {
      _erro = AppErrorMessages.from(
        e,
        fallback: 'Não foi possível excluir o animal. Tente novamente.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> atualizarAnimal(Animal animal) async {
    try {
      await _service.atualizarAnimal(animal);
    } catch (e) {
      _erro = AppErrorMessages.from(
        e,
        fallback: 'Não foi possível atualizar o animal. Tente novamente.',
      );
      notifyListeners();
    }
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}
