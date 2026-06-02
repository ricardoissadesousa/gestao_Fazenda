import 'package:flutter/material.dart';
import '../data/services/folga_service.dart';

class FolgaProvider extends ChangeNotifier {
  final FolgaService _service = FolgaService();

  bool _loading = false;
  bool get loading => _loading;

  Future<void> criarSolicitacao({
    required String usuarioId,
    required String usuarioNome,
    required String usuarioEmail,
    required String dataSolicitada,
    required String motivo,
  }) async {
    _loading = true;
    notifyListeners();

    await _service.criarSolicitacao(
      usuarioId: usuarioId,
      usuarioNome: usuarioNome,
      usuarioEmail: usuarioEmail,
      dataSolicitada: dataSolicitada,
      motivo: motivo,
    );

    _loading = false;
    notifyListeners();
  }

  Future<void> aprovarSolicitacao(String id) async {
    await _service.aprovarSolicitacao(id);
    notifyListeners();
  }

  Future<void> reprovarSolicitacao(String id, String motivo) async {
    await _service.reprovarSolicitacao(id, motivo);
    notifyListeners();
  }
}
