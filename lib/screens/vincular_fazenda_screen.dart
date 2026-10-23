import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/utils/app_error_messages.dart';
import '../data/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_button.dart';

class VincularFazendaScreen extends StatefulWidget {
  const VincularFazendaScreen({super.key});

  @override
  State<VincularFazendaScreen> createState() => _VincularFazendaScreenState();
}

class _VincularFazendaScreenState extends State<VincularFazendaScreen> {
  final _codigoController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _vincular() async {
    final codigo = _codigoController.text.trim().toUpperCase();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe o código da fazenda.'),
          backgroundColor: AppTheme.reprovada,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.usuario;
      if (user != null) {
        // vincularFazenda agora retorna o ID da fazenda
        final fazendaId = await _authService.vincularFazenda(user.id, codigo);
        if (!mounted) return;

        // Atualizar estado local do provider para refletir a nova fazenda
        authProvider.adicionarFazendaVinculada(fazendaId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fazenda vinculada com sucesso!'),
            backgroundColor: AppTheme.aprovada,
          ),
        );
        // Navegar direto para o dashboard do funcionário
        Navigator.pushNamedAndRemoveUntil(context, '/funcionario', (r) => false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMessages.from(
              e,
              fallback: 'Não foi possível vincular a fazenda. Tente novamente.',
            ),
          ),
          backgroundColor: AppTheme.reprovada,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jaTemFazenda = authProvider.usuario?.fazendasIds.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(jaTemFazenda ? 'Vincular Nova Fazenda' : 'Vincular Fazenda'),
        automaticallyImplyLeading: jaTemFazenda,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.agriculture, size: 64, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              jaTemFazenda ? 'Adicionar Fazenda' : 'Bem-vindo!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              jaTemFazenda
                  ? 'Insira o código de 6 caracteres da nova fazenda para vincular à sua conta.'
                  : 'Para começar a registrar dados, você precisa se vincular a uma fazenda.\n\n'
                    'Peça o código de 6 caracteres ao seu gestor.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Código da Fazenda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codigoController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'EX: FA3K9M',
                prefixIcon: Icon(Icons.qr_code),
                counterText: '',
              ),
              onChanged: (val) {
                if (val.trim().length == 6 && !_loading) {
                  _vincular();
                }
              },
            ),
            const SizedBox(height: 32),
            LoadingButton(
              text: 'Vincular',
              isLoading: _loading,
              onPressed: _vincular,
            ),
            const SizedBox(height: 16),
            if (jaTemFazenda)
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar ao painel'),
                ),
              )
            else
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair e tentar outra conta'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
