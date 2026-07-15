import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fazenda_provider.dart';

class FazendaHelper {
  /// Retorna o ID da fazenda atual baseando-se no tipo de usuário logado
  static String? obterFazendaIdAtual(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final usuario = authProvider.usuario;
    if (usuario?.tipo == TipoUsuario.GESTOR) {
      return context.read<FazendaProvider>().fazendaSelecionada?.id;
    } else {
      // Para funcionários, usar a fazenda ativa selecionada
      return authProvider.fazendaAtivaId;
    }
  }

  /// Exibe um snackbar se a fazenda não estiver selecionada/vinculada
  static bool validarFazendaAtiva(BuildContext context, String? fazendaId) {
    if (fazendaId == null || fazendaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma fazenda selecionada ou vinculada!'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }
}
