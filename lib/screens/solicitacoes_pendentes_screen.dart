import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../data/models/comunicacao.dart';
import '../data/services/comunicacao_service.dart';
import '../data/services/notificacao_service.dart';
import 'package:provider/provider.dart';
import '../providers/fazenda_provider.dart';

class SolicitacoesPendentesScreen extends StatefulWidget {
  const SolicitacoesPendentesScreen({super.key});

  @override
  State<SolicitacoesPendentesScreen> createState() => _SolicitacoesPendentesScreenState();
}

class _SolicitacoesPendentesScreenState extends State<SolicitacoesPendentesScreen> {
  final _comunicacaoService = ComunicacaoService();
  final _notificacaoService = NotificacaoService();
  List<Comunicacao> _solicitacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
    _marcarNotificacoesComoLidas();
  }

  /// Marca todas as notificações do gestor como lidas ao abrir a tela
  Future<void> _marcarNotificacoesComoLidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fazenda = context.read<FazendaProvider>().fazendaSelecionada;
    if (uid != null && fazenda != null) {
      await _notificacaoService.marcarTodasComoLidas(uid, fazenda.id);
    }
  }

  Future<void> _carregarSolicitacoes() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fazenda = context.read<FazendaProvider>().fazendaSelecionada;
    
    if (uid == null || fazenda == null) {
      setState(() => _loading = false);
      return;
    }

    final lista = await _comunicacaoService.obterSolicitacoesPendentes(uid, fazenda.id);

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
                      return _buildSolicitacaoCard(sol);
                    },
                  ),
                ),
    );
  }

  Widget _buildSolicitacaoCard(Comunicacao sol) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primarySurface,
                  child: Icon(Icons.person, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sol.remetenteNome.isNotEmpty ? sol.remetenteNome : sol.remetenteEmail,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        sol.remetenteEmail,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Data solicitada: ${sol.dataSolicitada}',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            if (sol.motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.message, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Motivo: ${sol.motivo}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _mostrarDialogReprovar(sol),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Recusar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.reprovada,
                    side: const BorderSide(color: AppTheme.reprovada),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _comunicacaoService.aprovarSolicitacao(sol.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aprovada!'),
                        backgroundColor: AppTheme.aprovada,
                      ),
                    );
                    _carregarSolicitacoes();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprovar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogReprovar(Comunicacao sol) {
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
              'Reprovando solicitação de ${sol.remetenteNome} para o dia ${sol.dataSolicitada}.',
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
              await _comunicacaoService.reprovarSolicitacao(
                sol.id,
                motivoController.text.trim(),
              );
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
