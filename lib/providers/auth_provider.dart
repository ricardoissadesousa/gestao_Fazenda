import 'package:flutter/material.dart';
import '../core/utils/app_error_messages.dart';
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

  /// ID da fazenda ativa selecionada pelo funcionário
  String? _fazendaAtivaId;
  String? get fazendaAtivaId => _fazendaAtivaId ?? _usuario?.fazendaId;

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
      // Inicializar fazenda ativa como a primeira da lista
      if (_usuario != null && _usuario!.fazendasIds.isNotEmpty) {
        _fazendaAtivaId = _usuario!.fazendasIds.first;
      }
    } catch (e) {
      _estado = EstadoLogin.erro;
      _mensagemErro = AppErrorMessages.auth(e, AuthOperation.login);
    }
    notifyListeners();
  }

  Future<void> enviarEmailRedefinicaoSenha(String email) {
    return _authService.enviarEmailRedefinicaoSenha(email);
  }

  /// Registrar
  Future<void> registrar(
    String email,
    String senha,
    String nome,
    String tipo,
  ) async {
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
      _mensagemErro = AppErrorMessages.auth(e, AuthOperation.cadastro);
    }
    notifyListeners();
  }

  /// Logout
  void logout() {
    _authService.logout();
    _estado = EstadoLogin.inicial;
    _usuario = null;
    _fazendaAtivaId = null;
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
    _fazendaAtivaId = null;
    _mensagemErro = '';
    notifyListeners();
  }

  /// Atualizar fazendaId no objeto local do usuário (após vincular nova fazenda)
  void adicionarFazendaVinculada(String fazendaId) {
    if (_usuario != null) {
      final novaLista = List<String>.from(_usuario!.fazendasIds);
      if (!novaLista.contains(fazendaId)) {
        novaLista.add(fazendaId);
      }
      _usuario = _usuario!.copyWith(fazendasIds: novaLista);
      _fazendaAtivaId = fazendaId;
      notifyListeners();
    }
  }

  /// Selecionar fazenda ativa (para funcionários com múltiplas fazendas)
  void selecionarFazendaAtiva(String fazendaId) {
    _fazendaAtivaId = fazendaId;
    notifyListeners();
  }

  /// Buscar nome do funcionário
  Future<String> buscarNome() async {
    return _authService.buscarNomeUsuario();
  }

  String? get currentUserId => _authService.currentUserId;
  String? get currentUserEmail => _authService.currentUserEmail;
}
