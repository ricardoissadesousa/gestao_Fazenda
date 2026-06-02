import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../widgets/farm_card.dart';

class GestorDashboardScreen extends StatelessWidget {
  const GestorDashboardScreen({super.key});

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
                              onTap: () => Navigator.pushNamed(context, '/solicitacoes-pendentes'),
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

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
