import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/historico_folga.dart';
import '../data/services/folga_service.dart';
import 'package:intl/intl.dart';

class HistoricoSolicitacoesScreen extends StatefulWidget {
  const HistoricoSolicitacoesScreen({super.key});

  @override
  State<HistoricoSolicitacoesScreen> createState() => _HistoricoSolicitacoesScreenState();
}

class _HistoricoSolicitacoesScreenState extends State<HistoricoSolicitacoesScreen> {
  final _folgaService = FolgaService();
  List<HistoricoFolga> _listaCompleta = [];
  String _mesFiltro = 'Todos';
  List<String> _meses = ['Todos'];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _loading = true);
    final result = await _folgaService.obterHistoricoGlobal();
    final lista = <HistoricoFolga>[];

    for (var doc in result.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statusStr = data['status'] ?? '';
      final nomeFuncionario = (data['usuario_nome'] ?? '').toString().trim();
      final emailFuncionario = (data['usuario_email'] ?? '').toString().trim();
      final dataSolicitada = data['data_solicitada'] ?? '';

      final status = switch (statusStr) {
        'APROVADA' => StatusFolga.APROVADA,
        'REPROVADA' => StatusFolga.REPROVADA,
        _ => StatusFolga.PENDENTE,
      };

      final textoExibicao =
          (nomeFuncionario.toLowerCase() == emailFuncionario.toLowerCase() || nomeFuncionario.isEmpty)
              ? emailFuncionario
              : '$nomeFuncionario\n$emailFuncionario';

      lista.add(HistoricoFolga(
        nome: textoExibicao,
        data: dataSolicitada,
        status: status,
      ));
    }

    // Extrair meses
    final sdfEntrada = DateFormat('dd/MM/yyyy');
    final sdfSaida = DateFormat('MMMM yyyy', 'pt_BR');
    final mesesSet = <String>{'Todos'};
    for (var item in lista) {
      try {
        final dateObj = sdfEntrada.parse(item.data);
        final mesFormatado = sdfSaida.format(dateObj);
        mesesSet.add(mesFormatado[0].toUpperCase() + mesFormatado.substring(1));
      } catch (_) {}
    }

    setState(() {
      _listaCompleta = lista;
      _meses = mesesSet.toList();
      _loading = false;
    });
  }

  List<HistoricoFolga> get _listaFiltrada {
    if (_mesFiltro == 'Todos') return _listaCompleta;
    final sdfEntrada = DateFormat('dd/MM/yyyy');
    final sdfSaida = DateFormat('MMMM yyyy', 'pt_BR');
    return _listaCompleta.where((item) {
      try {
        final dateObj = sdfEntrada.parse(item.data);
        final mesItem = sdfSaida.format(dateObj);
        return (mesItem[0].toUpperCase() + mesItem.substring(1)) == _mesFiltro;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Solicitações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _meses.contains(_mesFiltro) ? _mesFiltro : 'Todos',
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.filter_list),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _meses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _mesFiltro = val);
                    },
                  ),
                ),
                Expanded(
                  child: _listaFiltrada.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma solicitação encontrada',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _listaFiltrada.length,
                          itemBuilder: (context, index) {
                            final item = _listaFiltrada[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(item.status).withValues(alpha: 0.15),
                                  child: Icon(
                                    _statusIcon(item.status),
                                    color: _statusColor(item.status),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item.nome,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text('Dia: ${item.data}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(item.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusText(item.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(item.status),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _statusColor(StatusFolga s) => switch (s) {
        StatusFolga.APROVADA => AppTheme.aprovada,
        StatusFolga.REPROVADA => AppTheme.reprovada,
        StatusFolga.PENDENTE => AppTheme.pendente,
      };

  IconData _statusIcon(StatusFolga s) => switch (s) {
        StatusFolga.APROVADA => Icons.check_circle,
        StatusFolga.REPROVADA => Icons.cancel,
        StatusFolga.PENDENTE => Icons.schedule,
      };

  String _statusText(StatusFolga s) => switch (s) {
        StatusFolga.APROVADA => 'Aprovada',
        StatusFolga.REPROVADA => 'Recusada',
        StatusFolga.PENDENTE => 'Pendente',
      };
}
