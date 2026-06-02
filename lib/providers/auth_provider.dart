import 'package:flutter/material.dart';
import '../data/models/usuario.dart';
import '../data/services/auth_service.dart';

enum EstadoLogin { inicial, carregando, sucesso, erro }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  EstadoLogin _estado = EstadoLogin.inicial;
  EstadoLogin get estado => _estado;

  Usuario? _usuario;
  Usuario? get usuario => _usuario;

  String _mensagemErro = '';
  String get mensagemErro => _mensagemErro;

  /// Login
  Future<void> login(String email, String senha) async {
    if (email.trim().isEmpty || senha.trim().isEmpty) {
      _estado = EstadoLogin.erro;
      _mensagemErro = 'Preencha todos os campos';
      notifyListeners();
      return;
    }

    _estado = EstadoLogin.carregando;
    notifyListeners();

    try {
      _usuario = await _authService.login(email.trim(), senha.trim());
      _estado = EstadoLogin.sucesso;
    } catch (e) {
      _estado = EstadoLogin.erro;
      _mensagemErro = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  /// Registrar
  Future<void> registrar(String email, String senha, String nome, String tipo) async {
    if (email.trim().isEmpty || senha.trim().isEmpty || nome.trim().isEmpty) {
      _estado = EstadoLogin.erro;
      _mensagemErro = 'Preencha todos os campos';
      notifyListeners();
      return;
    }

    _estado = EstadoLogin.carregando;
    notifyListeners();

    try {
      _usuario = await _authService.registrar(
        email.trim(),
        senha.trim(),
        nome.trim(),
        tipo,
      );
      _estado = EstadoLogin.sucesso;
    } catch (e) {
      _estado = EstadoLogin.erro;
      _mensagemErro = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  /// Logout
  void logout() {
    _authService.logout();
    _estado = EstadoLogin.inicial;
    _usuario = null;
    notifyListeners();
  }

  /// Limpar erro
  void limparErro() {
    if (_estado == EstadoLogin.erro) {
      _estado = EstadoLogin.inicial;
      notifyListeners();
    }
  }

  /// Resetar estado
  void resetar() {
    _estado = EstadoLogin.inicial;
    _usuario = null;
    _mensagemErro = '';
    notifyListeners();
  }

  /// Buscar nome do funcionário
  Future<String> buscarNome() async {
    return _authService.buscarNomeUsuario();
  }

  String? get currentUserId => _authService.currentUserId;
  String? get currentUserEmail => _authService.currentUserEmail;
}
