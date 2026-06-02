import 'package:flutter/material.dart';
import '../data/models/animal.dart';
import '../data/services/animal_service.dart';

class AnimalProvider extends ChangeNotifier {
  final AnimalService _service = AnimalService();

  List<Animal> _listaCompleta = [];
  List<Animal> _animaisFiltrados = [];
  List<Animal> get animais => _animaisFiltrados;

  String _termoBusca = '';
  int _mesFiltro = 0; // 0 = Todos

  bool _loading = false;
  bool get loading => _loading;

  String? _erro;
  String? get erro => _erro;

  AnimalProvider() {
    carregarAnimais();
  }

  void carregarAnimais() {
    _service.obterAnimais().listen((lista) {
      _listaCompleta = lista;
      _aplicarFiltros();
      notifyListeners();
    }, onError: (e) {
      _erro = e.toString();
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

    _animaisFiltrados = lista;
  }

  Future<void> excluirAnimal(Animal animal) async {
    try {
      await _service.excluirAnimal(animal);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    }
  }

  Future<void> atualizarAnimal(Animal animal) async {
    try {
      await _service.atualizarAnimal(animal);
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    }
  }
}
