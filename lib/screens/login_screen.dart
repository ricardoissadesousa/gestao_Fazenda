import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/utils/app_error_messages.dart';
import '../providers/auth_provider.dart';
import '../providers/fazenda_provider.dart';
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
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

      if (authProvider.estado == EstadoLogin.sucesso &&
          authProvider.usuario != null) {
        final tipoEsperado = isGestor
            ? TipoUsuario.GESTOR
            : TipoUsuario.FUNCIONARIO;
        if (authProvider.usuario!.tipo == tipoEsperado) {
          if (tipoEsperado == TipoUsuario.FUNCIONARIO &&
              authProvider.usuario!.fazendasIds.isEmpty) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/vincular-fazenda',
              (r) => false,
            );
          } else {
            if (isGestor) {
              // Recarregar fazendas com UID correto do gestor logado
              context.read<FazendaProvider>().carregarFazendas();
            }
            final route = isGestor ? '/gestor' : '/funcionario';
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Acesso negado. Você não tem permissão de ${widget.funcao}.',
              ),
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
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
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
                                _senhaVisivel
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _senhaVisivel = !_senhaVisivel);
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _abrirRecuperacaoSenha,
                            child: const Text('Esqueceu a senha?'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LoadingButton(
                          text: 'Entrar',
                          isLoading:
                              authProvider.estado == EstadoLogin.carregando,
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

  Future<void> _abrirRecuperacaoSenha() async {
    var emailDigitado = _emailController.text.trim();
    var enviando = false;
    String? mensagemErro;

    final emailEnviado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Recuperar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informe o e-mail cadastrado. Enviaremos um link para você criar uma nova senha.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: emailDigitado,
                onChanged: (valor) => emailDigitado = valor,
                enabled: !enviando,
                autofocus: emailDigitado.isEmpty,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'seu@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: mensagemErro,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: enviando
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      final email = emailDigitado.trim();
                      if (!_emailValido(email)) {
                        setDialogState(
                          () => mensagemErro = 'Informe um e-mail válido.',
                        );
                        return;
                      }

                      setDialogState(() {
                        enviando = true;
                        mensagemErro = null;
                      });

                      try {
                        await this.context
                            .read<AuthProvider>()
                            .enviarEmailRedefinicaoSenha(email);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext, true);
                      } on FirebaseAuthException catch (erro) {
                        if (!dialogContext.mounted) return;

                        // Com protecao contra enumeracao de e-mails, o Firebase
                        // normalmente retorna sucesso mesmo para conta ausente.
                        if (erro.code == 'user-not-found') {
                          Navigator.pop(dialogContext, true);
                          return;
                        }

                        setDialogState(() {
                          enviando = false;
                          mensagemErro = AppErrorMessages.auth(
                            erro,
                            AuthOperation.recuperacaoSenha,
                          );
                        });
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          enviando = false;
                          mensagemErro =
                              'Não foi possível enviar o e-mail. Tente novamente.';
                        });
                      }
                    },
              child: enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar link'),
            ),
          ],
        ),
      ),
    );

    if (emailEnviado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se existir uma conta com esse e-mail, o link para redefinir a senha foi enviado. Verifique também a caixa de spam.',
          ),
          backgroundColor: AppTheme.aprovada,
        ),
      );
    }
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

}
