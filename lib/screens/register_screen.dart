import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_button.dart';

class RegisterScreen extends StatefulWidget {
  final String funcao;
  const RegisterScreen({super.key, required this.funcao});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.estado == EstadoLogin.sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado com sucesso!'),
            backgroundColor: AppTheme.aprovada,
          ),
        );
        authProvider.resetar();
        Navigator.pop(context);
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
                    const SizedBox(height: 8),
                    const Icon(Icons.person_add, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Cadastro como ${widget.funcao}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
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
                        _buildLabel('Nome Completo'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            hintText: 'Seu nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Email'),
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
                        _buildLabel('Senha'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _senhaController,
                          obscureText: !_senhaVisivel,
                          decoration: InputDecoration(
                            hintText: 'Mínimo 6 caracteres',
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
                        const SizedBox(height: 20),
                        _buildLabel('Função'),
                        const SizedBox(height: 8),
                        TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: widget.funcao.toUpperCase(),
                            prefixIcon: const Icon(Icons.badge_outlined),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          text: 'Criar Conta',
                          isLoading: authProvider.estado == EstadoLogin.carregando,
                          onPressed: () {
                            authProvider.registrar(
                              _emailController.text,
                              _senhaController.text,
                              _nomeController.text,
                              widget.funcao.toUpperCase(),
                            );
                          },
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
