import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../data/models/usuario.dart';
import '../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  final String funcao;
  const LoginScreen({super.key, required this.funcao});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isGestor = widget.funcao == 'gestor';

    // Observar estado do login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.estado == EstadoLogin.sucesso && authProvider.usuario != null) {
        final tipoEsperado = isGestor ? TipoUsuario.GESTOR : TipoUsuario.FUNCIONARIO;
        if (authProvider.usuario!.tipo == tipoEsperado) {
          final route = isGestor ? '/gestor' : '/funcionario';
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Acesso negado. Você não tem permissão de ${widget.funcao}.'),
              backgroundColor: AppTheme.reprovada,
            ),
          );
          authProvider.logout();
        }
      } else if (authProvider.estado == EstadoLogin.erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.mensagemErro),
            backgroundColor: AppTheme.reprovada,
          ),
        );
        authProvider.limparErro();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Parte superior verde
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            authProvider.resetar();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Icon(
                      isGestor ? Icons.admin_panel_settings : Icons.engineering,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isGestor ? 'Acesso do Gestor' : 'Acesso do Funcionário',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entre com suas credenciais',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Formulário com fundo branco
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'seu@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Senha',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _senhaController,
                          obscureText: !_senhaVisivel,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _senhaVisivel = !_senhaVisivel);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          text: 'Entrar',
                          isLoading: authProvider.estado == EstadoLogin.carregando,
                          onPressed: () {
                            authProvider.login(
                              _emailController.text,
                              _senhaController.text,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              authProvider.resetar();
                              Navigator.pushNamed(
                                context,
                                '/register',
                                arguments: {'funcao': widget.funcao},
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Não tem conta? ',
                                style: TextStyle(color: AppTheme.textSecondary),
                                children: [
                                  TextSpan(
                                    text: 'Cadastre-se',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
