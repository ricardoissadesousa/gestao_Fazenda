import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/farm_card.dart';

class FuncionarioDashboardScreen extends StatefulWidget {
  const FuncionarioDashboardScreen({super.key});

  @override
  State<FuncionarioDashboardScreen> createState() => _FuncionarioDashboardScreenState();
}

class _FuncionarioDashboardScreenState extends State<FuncionarioDashboardScreen> {
  /// Mapa de fazendaId → nome da fazenda
  Map<String, String> _fazendaNomes = {};
  bool _carregandoFazendas = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarVinculo();
      _carregarNomesFazendas();
    });
  }

  void _verificarVinculo() {
    final user = context.read<AuthProvider>().usuario;
    if (user != null && user.fazendasIds.isEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, '/vincular-fazenda', (r) => false);
    }
  }

  /// Carrega os nomes das fazendas vinculadas para exibir no dropdown
  Future<void> _carregarNomesFazendas() async {
    final user = context.read<AuthProvider>().usuario;
    if (user == null || user.fazendasIds.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final nomes = <String, String>{};

    for (var fazendaId in user.fazendasIds) {
      try {
        final doc = await firestore.collection('fazendas').doc(fazendaId).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          nomes[fazendaId] = data['nome'] ?? 'Fazenda';
        } else {
          nomes[fazendaId] = 'Fazenda removida';
        }
      } catch (_) {
        nomes[fazendaId] = 'Fazenda';
      }
    }

    if (mounted) {
      setState(() {
        _fazendaNomes = nomes;
        _carregandoFazendas = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.engineering, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Painel do Funcionário',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          // Dropdown de seleção de fazenda
                          _buildFazendaSelector(authProvider),
                        ],
                      ),
                    ),
                    // Botão para vincular nova fazenda
                    IconButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/vincular-fazenda');
                        // Recarregar nomes após voltar
                        _carregarNomesFazendas();
                      },
                      icon: const Icon(Icons.add_business, color: Colors.white),
                      tooltip: 'Vincular nova fazenda',
                    ),
                    IconButton(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Sair',
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
                              icon: Icons.calendar_month,
                              title: 'Minhas\nFolgas',
                              onTap: () => Navigator.pushNamed(context, '/controle-folgas'),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                              ),
                            ),
                            FarmCard(
                              icon: Icons.local_gas_station,
                              title: 'Controle\nde Diesel',
                              onTap: () => Navigator.pushNamed(context, '/controle-diesel'),
                              gradient: AppTheme.accentGradient,
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
                              icon: Icons.water_drop,
                              title: 'Registrar\nProdução',
                              onTap: () => Navigator.pushNamed(context, '/registrar-producao'),
                              gradient: AppTheme.cardGradient,
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

  /// Widget de seleção de fazenda ativa
  Widget _buildFazendaSelector(AuthProvider authProvider) {
    final fazendasIds = authProvider.usuario?.fazendasIds ?? [];

    if (_carregandoFazendas) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    if (fazendasIds.isEmpty) {
      return Text(
        'Nenhuma fazenda vinculada',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
      );
    }

    // Se tem apenas uma fazenda, mostra só o nome
    if (fazendasIds.length == 1) {
      return Text(
        _fazendaNomes[fazendasIds.first] ?? 'Fazenda',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 13,
        ),
      );
    }

    // Se tem múltiplas fazendas, mostra dropdown
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        hint: const Text(
          'Selecione...',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        value: fazendasIds.contains(authProvider.fazendaAtivaId)
            ? authProvider.fazendaAtivaId
            : null,
        dropdownColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (String? novaFazendaId) {
          if (novaFazendaId != null) {
            authProvider.selecionarFazendaAtiva(novaFazendaId);
          }
        },
        items: fazendasIds.map((id) {
          return DropdownMenuItem<String>(
            value: id,
            child: Text(_fazendaNomes[id] ?? 'Fazenda'),
          );
        }).toList(),
      ),
    );
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
