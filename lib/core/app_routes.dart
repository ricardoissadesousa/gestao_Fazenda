import 'package:flutter/material.dart';
import '../screens/role_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/gestor_dashboard_screen.dart';
import '../screens/funcionario_dashboard_screen.dart';
import '../screens/registrar_producao_screen.dart';
import '../screens/relatorio_mensal_screen.dart';
import '../screens/lista_animais_screen.dart';
import '../screens/registrar_nascimento_screen.dart';
import '../screens/controle_diesel_screen.dart';
import '../screens/historico_abastecimentos_screen.dart';
import '../screens/controle_folgas_screen.dart';
import '../screens/solicitacoes_pendentes_screen.dart';
import '../screens/historico_solicitacoes_screen.dart';
import '../screens/gerenciar_fazendas_screen.dart';
// aqui
import '../screens/vincular_fazenda_screen.dart';

class AppRoutes {
  static const String roleSelection = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String gestorDashboard = '/gestor';
  static const String funcionarioDashboard = '/funcionario';
  static const String registrarProducao = '/registrar-producao';
  static const String relatorioMensal = '/relatorio-mensal';
  static const String listaAnimais = '/lista-animais';
  static const String registrarNascimento = '/registrar-nascimento';
  static const String controleDiesel = '/controle-diesel';
  static const String historicoAbastecimentos = '/historico-abastecimentos';
  static const String controleFolgas = '/controle-folgas';
  static const String solicitacoesPendentes = '/solicitacoes-pendentes';
  static const String historicoSolicitacoes = '/historico-solicitacoes';
  // Novas rotas
  static const String gerenciarFazendas = '/gerenciar-fazendas';

  static const String vincularFazenda = '/vincular-fazenda';

  static Map<String, WidgetBuilder> get routes {
    return {
      roleSelection: (_) => const RoleSelectionScreen(),
      login: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
        return LoginScreen(funcao: args['funcao']!);
      },
      register: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
        return RegisterScreen(funcao: args['funcao']!);
      },
      gestorDashboard: (_) => const GestorDashboardScreen(),
      funcionarioDashboard: (_) => const FuncionarioDashboardScreen(),
      registrarProducao: (_) => const RegistrarProducaoScreen(),
      relatorioMensal: (_) => const RelatorioMensalScreen(),
      listaAnimais: (_) => const ListaAnimaisScreen(),
      registrarNascimento: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return RegistrarNascimentoScreen(animalParaEditar: args?['animal']);
      },
      controleDiesel: (_) => const ControleDieselScreen(),
      historicoAbastecimentos: (_) => const HistoricoAbastecimentosScreen(),
      controleFolgas: (_) => const ControleFolgasScreen(),
      solicitacoesPendentes: (_) => const SolicitacoesPendentesScreen(),
      historicoSolicitacoes: (_) => const HistoricoSolicitacoesScreen(),
      // Novas rotas
      gerenciarFazendas: (_) => const GerenciarFazendasScreen(),
      vincularFazenda: (_) => const VincularFazendaScreen(),
    };
  }
}
