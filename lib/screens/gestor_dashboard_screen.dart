import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../data/services/notificacao_service.dart';
import '../data/services/folga_service.dart';
import '../widgets/farm_card.dart';

class GestorDashboardScreen extends StatefulWidget {
  const GestorDashboardScreen({super.key});

  @override
  State<GestorDashboardScreen> createState() => _GestorDashboardScreenState();
}

class _GestorDashboardScreenState extends State<GestorDashboardScreen> {
  final _notificacaoService = NotificacaoService();
  final _folgaService = FolgaService();

  int _notificacoesNaoLidas = 0;
  int _solicitacoesPendentes = 0;
  StreamSubscription<int>? _notificacaoSubscription;

  @override
  void initState() {
    super.initState();
    _iniciarListenerNotificacoes();
    _carregarPendentes();
  }

  void _iniciarListenerNotificacoes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notificacaoSubscription = _notificacaoService.contarNaoLidas(uid).listen(
      (count) {
        if (mounted) {
          setState(() => _notificacoesNaoLidas = count);
        }
      },
    );
  }

  Future<void> _carregarPendentes() async {
    try {
      final result = await _folgaService.obterSolicitacoesPendentes();
      if (mounted) {
        setState(() => _solicitacoesPendentes = result.docs.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notificacaoSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Painel do Gestor',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Gestão completa da fazenda',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ícone de Notificações (Sino)
                    _buildNotificacaoBadge(),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Sair',
                    ),
                  ],
                ),
              ),
              // Cards Grid
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu Principal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                          children: [
                            FarmCard(
                              icon: Icons.water_drop,
                              title: 'Produção\nde Leite',
                              onTap: () => Navigator.pushNamed(context, '/registrar-producao'),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                              ),
                            ),
                            FarmCard(
                              icon: Icons.bar_chart,
                              title: 'Relatórios\nMensais',
                              onTap: () => Navigator.pushNamed(context, '/relatorio-mensal'),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                              ),
                            ),
                            FarmCard(
                              icon: Icons.pets,
                              title: 'Lista de\nAnimais',
                              onTap: () => Navigator.pushNamed(context, '/lista-animais'),
                              gradient: AppTheme.cardGradient,
                            ),
                            FarmCard(
                              icon: Icons.child_care,
                              title: 'Registrar\nNascimento',
                              onTap: () => Navigator.pushNamed(context, '/registrar-nascimento'),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE65100), Color(0xFFFB8C00)],
                              ),
                            ),
                            FarmCard(
                              icon: Icons.pending_actions,
                              title: 'Solicitações\nde Folga',
                              badgeCount: _solicitacoesPendentes,
                              onTap: () async {
                                await Navigator.pushNamed(context, '/solicitacoes-pendentes');
                                _carregarPendentes();
                              },
                              gradient: const LinearGradient(
                                colors: [Color(0xFFC62828), Color(0xFFEF5350)],
                              ),
                            ),
                            FarmCard(
                              icon: Icons.local_gas_station,
                              title: 'Controle\nde Diesel',
                              onTap: () => Navigator.pushNamed(context, '/historico-abastecimentos'),
                              gradient: AppTheme.accentGradient,
                            ),
                          ],
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

  /// Ícone de sino com badge de notificações não lidas
  Widget _buildNotificacaoBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _abrirNotificacoes,
          icon: Icon(
            _notificacoesNaoLidas > 0
                ? Icons.notifications_active
                : Icons.notifications_none,
            color: Colors.white,
          ),
          tooltip: 'Notificações',
        ),
        if (_notificacoesNaoLidas > 0)
          Positioned(
            top: 4,
            right: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _notificacoesNaoLidas > 9 ? '9+' : '$_notificacoesNaoLidas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }


  /// Abre a tela de notificações / solicitações pendentes e marca como lidas
  void _abrirNotificacoes(  ) async {
    // Marcar todas como lidas ao abrir
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _notificacaoService.marcarTodasComoLidas(uid);
    }
    if (!mounted) return;
    await Navigator.pushNamed(context, '/solicitacoes-pendentes');
    // Recarregar ao voltar
    _carregarPendentes();
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
