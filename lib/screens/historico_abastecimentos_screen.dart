import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../data/models/abastecimento.dart';
import '../providers/abastecimento_provider.dart';
import '../widgets/abastecimento_card.dart';
import 'package:intl/intl.dart';

class HistoricoAbastecimentosScreen extends StatefulWidget {
  const HistoricoAbastecimentosScreen({super.key});

  @override
  State<HistoricoAbastecimentosScreen> createState() => _HistoricoAbastecimentosScreenState();
}

class _HistoricoAbastecimentosScreenState extends State<HistoricoAbastecimentosScreen> {
  String _mesFiltro = 'Todos';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AbastecimentoProvider>(context);
    final meses = _extrairMeses(provider.listaCompleta);
    final listaFiltrada = _filtrarPorMes(provider.listaCompleta, _mesFiltro);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Abastecimentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/controle-diesel'),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: Column(
        children: [
          // Filtro por mês
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: meses.contains(_mesFiltro) ? _mesFiltro : 'Todos',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.filter_list),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: meses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _mesFiltro = val);
              },
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

  List<String> _extrairMeses(List<Abastecimento> lista) {
    final sdf = DateFormat('MMMM yyyy', 'pt_BR');
    final meses = <String>{'Todos'};
    for (var item in lista) {
      if (item.data != null) {
        final mesAno = sdf.format(item.data!);
        meses.add(mesAno[0].toUpperCase() + mesAno.substring(1));
      }
    }
    return meses.toList();
  }

  List<Abastecimento> _filtrarPorMes(List<Abastecimento> lista, String mesFiltro) {
    if (mesFiltro == 'Todos') return lista;
    final sdf = DateFormat('MMMM yyyy', 'pt_BR');
    return lista.where((item) {
      if (item.data == null) return false;
      final mesItem = sdf.format(item.data!);
      return (mesItem[0].toUpperCase() + mesItem.substring(1)) == mesFiltro;
    }).toList();
  }
}
