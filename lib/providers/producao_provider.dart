import 'package:flutter/material.dart';
import '../data/services/producao_leite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProducaoProvider extends ChangeNotifier {
  final ProducaoLeiteService _service = ProducaoLeiteService();

  bool _loading = false;
  bool get loading => _loading;

  /// Salvar produção com mapa dinâmico de tanques
  Future<bool> salvarProducao(List<double> valoresTanques, String fazendaId) async {
    double total = 0.0;
    final mapTanques = <String, dynamic>{};

    for (int i = 0; i < valoresTanques.length; i++) {
      total += valoresTanques[i];
      mapTanques['tanque${i + 1}'] = valoresTanques[i];
    }

    if (total == 0.0) return false;

    mapTanques['data_registro'] = Timestamp.now();
    mapTanques['total_litros'] = total;
    mapTanques['usuario_id'] = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
    mapTanques['fazenda_id'] = fazendaId;

    _loading = true;
    notifyListeners();

    try {
      await _service.adicionarProducao(mapTanques);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
