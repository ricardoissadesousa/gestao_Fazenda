import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../data/models/comunicacao.dart';
import '../data/services/comunicacao_service.dart';
import 'package:provider/provider.dart';
import '../providers/fazenda_provider.dart';
import 'package:intl/intl.dart';

class HistoricoSolicitacoesScreen extends StatefulWidget {
  const HistoricoSolicitacoesScreen({super.key});

  @override
  State<HistoricoSolicitacoesScreen> createState() => _HistoricoSolicitacoesScreenState();
}

class _HistoricoSolicitacoesScreenState extends State<HistoricoSolicitacoesScreen> {
  final _comunicacaoService = ComunicacaoService();

  final _meses = [
    'Todos', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  List<Comunicacao> _listaCompleta = [];
  int _mesFiltro = 0; // 0 = Todos
  int _anoFiltro = 0; // 0 = Todos
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fazenda = context.read<FazendaProvider>().fazendaSelecionada;

    if (uid == null || fazenda == null) {
      setState(() => _loading = false);
      return;
    }

    final resultado = await _comunicacaoService.obterHistoricoGlobal(uid, fazenda.id);

    setState(() {
      _listaCompleta = resultado;
      _loading = false;
    });
  }

  List<Comunicacao> get _listaFiltrada {
    return _listaCompleta.where((item) {
      try {
        final sdf = DateFormat('dd/MM/yyyy');
        final dateObj = sdf.parse(item.dataSolicitada);

        final matchMes = _mesFiltro == 0 || dateObj.month == _mesFiltro;
        final matchAno = _anoFiltro == 0 || dateObj.year == _anoFiltro;

        return matchMes && matchAno;
      } catch (_) {
        return _mesFiltro == 0 && _anoFiltro == 0;
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
                // Filtros mês + ano
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Seletor de mês
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _selecionarMes,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _meses[_mesFiltro],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Seletor de ano
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _selecionarAno,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _anoFiltro == 0 ? 'Todos' : '$_anoFiltro',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                                  item.remetenteNome.isNotEmpty
                                      ? item.remetenteNome
                                      : item.remetenteEmail,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text('Dia: ${item.dataSolicitada}'),
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

  void _selecionarMes() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecione o Mês'),
        children: List.generate(_meses.length, (index) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _mesFiltro = index);
            },
            child: Text(
              _meses[index],
              style: TextStyle(
                fontWeight: index == _mesFiltro ? FontWeight.w700 : FontWeight.w400,
                color: index == _mesFiltro ? AppTheme.primary : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _selecionarAno() {
    final anoAtual = DateTime.now().year;
    final anosDisponiveis = List.generate(7, (i) => anoAtual - 5 + i);

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecione o Ano'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _anoFiltro = 0);
            },
            child: Text(
              'Todos',
              style: TextStyle(
                fontWeight: 0 == _anoFiltro ? FontWeight.w700 : FontWeight.w400,
                color: 0 == _anoFiltro ? AppTheme.primary : null,
              ),
            ),
          ),
          ...anosDisponiveis.map((ano) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _anoFiltro = ano);
              },
              child: Text(
                '$ano',
                style: TextStyle(
                  fontWeight: ano == _anoFiltro ? FontWeight.w700 : FontWeight.w400,
                  color: ano == _anoFiltro ? AppTheme.primary : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _statusColor(StatusComunicacao s) => switch (s) {
        StatusComunicacao.ACEITO => AppTheme.aprovada,
        StatusComunicacao.RECUSADO => AppTheme.reprovada,
        StatusComunicacao.PENDENTE => AppTheme.pendente,
        StatusComunicacao.VISUALIZADO => AppTheme.pendente,
      };

  IconData _statusIcon(StatusComunicacao s) => switch (s) {
        StatusComunicacao.ACEITO => Icons.check_circle,
        StatusComunicacao.RECUSADO => Icons.cancel,
        StatusComunicacao.PENDENTE => Icons.schedule,
        StatusComunicacao.VISUALIZADO => Icons.visibility,
      };

  String _statusText(StatusComunicacao s) => switch (s) {
        StatusComunicacao.ACEITO => 'Aprovada',
        StatusComunicacao.RECUSADO => 'Recusada',
        StatusComunicacao.PENDENTE => 'Pendente',
        StatusComunicacao.VISUALIZADO => 'Visualizada',
      };
}
