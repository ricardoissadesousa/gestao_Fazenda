import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../data/models/abastecimento.dart';
import '../providers/abastecimento_provider.dart';
import '../providers/fazenda_provider.dart';
import '../widgets/abastecimento_card.dart';

class HistoricoAbastecimentosScreen extends StatefulWidget {
  const HistoricoAbastecimentosScreen({super.key});

  @override
  State<HistoricoAbastecimentosScreen> createState() => _HistoricoAbastecimentosScreenState();
}

class _HistoricoAbastecimentosScreenState extends State<HistoricoAbastecimentosScreen> {
  final _meses = [
    'Todos', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  int _mesFiltro = 0; // 0 = Todos, 1 = Janeiro, ...
  int _anoFiltro = 0; // 0 = Todos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  void _carregarDados() {
    final fazenda = Provider.of<FazendaProvider>(context, listen: false).fazendaSelecionada;
    if (fazenda != null) {
      Provider.of<AbastecimentoProvider>(context, listen: false).carregarAbastecimentosFazenda(fazenda.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AbastecimentoProvider>(context);
    final listaFiltrada = _filtrar(provider.listaCompleta);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Abastecimentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/controle-diesel'),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: Column(
        children: [
          // Filtros
          // Filtros
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
          // Lista
          Expanded(
            child: listaFiltrada.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_gas_station, size: 64, color: AppTheme.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum abastecimento encontrado',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      return AbastecimentoCard(abastecimento: listaFiltrada[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Abastecimento> _filtrar(List<Abastecimento> lista) {
    return lista.where((item) {
      if (item.data == null) return _mesFiltro == 0 && _anoFiltro == 0;

      final matchMes = _mesFiltro == 0 || item.data!.month == _mesFiltro;
      final matchAno = _anoFiltro == 0 || item.data!.year == _anoFiltro;

      return matchMes && matchAno;
    }).toList();
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
}
