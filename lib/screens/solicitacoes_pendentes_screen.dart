import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/solicitacao.dart';
import '../data/services/folga_service.dart';
import '../widgets/solicitacao_card.dart';

class SolicitacoesPendentesScreen extends StatefulWidget {
  const SolicitacoesPendentesScreen({super.key});

  @override
  State<SolicitacoesPendentesScreen> createState() => _SolicitacoesPendentesScreenState();
}

class _SolicitacoesPendentesScreenState extends State<SolicitacoesPendentesScreen> {
  final _folgaService = FolgaService();
  List<Solicitacao> _solicitacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
  }

  Future<void> _carregarSolicitacoes() async {
    setState(() => _loading = true);
    final result = await _folgaService.obterSolicitacoesPendentes();
    final lista = result.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Solicitacao(
        id: doc.id,
        nome: data['usuario_nome'] ?? 'Sem nome',
        email: data['usuario_email'] ?? '',
        data: data['data_solicitada'] ?? '',
        motivo: data['motivo'] ?? '',
      );
    }).toList();

    setState(() {
      _solicitacoes = lista;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações Pendentes'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/historico-solicitacoes'),
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _solicitacoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: AppTheme.primaryLight),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma solicitação pendente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Todas as solicitações foram resolvidas!',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarSolicitacoes,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _solicitacoes.length,
                    itemBuilder: (context, index) {
                      final sol = _solicitacoes[index];
                      return SolicitacaoCard(
                        solicitacao: sol,
                        onAprovar: () async {
                          await _folgaService.aprovarSolicitacao(sol.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aprovada!'),
                              backgroundColor: AppTheme.aprovada,
                            ),
                          );
                          _carregarSolicitacoes();
                        },
                        onReprovar: () => _mostrarDialogReprovar(sol),
                      );
                    },
                  ),
                ),
    );
  }

  void _mostrarDialogReprovar(Solicitacao sol) {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reprovar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reprovando solicitação de ${sol.nome} para o dia ${sol.data}.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo da recusa *',
                hintText: 'Informe o motivo...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe o motivo')),
                );
                return;
              }
              await _folgaService.reprovarSolicitacao(sol.id, motivoController.text.trim());
              if (context.mounted) Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solicitação reprovada.')),
                );
              }
              _carregarSolicitacoes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reprovada),
            child: const Text('Confirmar Recusa'),
          ),
        ],
      ),
    );
  }
}
