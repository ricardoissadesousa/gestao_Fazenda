import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/animal_provider.dart';
import '../providers/fazenda_provider.dart';
import '../widgets/animal_list_tile.dart';

class ListaAnimaisScreen extends StatefulWidget {
  const ListaAnimaisScreen({super.key});

  @override
  State<ListaAnimaisScreen> createState() => _ListaAnimaisScreenState();
}

class _ListaAnimaisScreenState extends State<ListaAnimaisScreen> {
  final _searchController = TextEditingController();
  int _mesSelecionado = 0;
  int _anoSelecionado = 0;

  final _meses = [
    'Todos', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarAnimais();
    });
  }

  void _carregarAnimais() {
    // Busca a fazenda atual de forma segura sem ser nula
    final fazenda = Provider.of<FazendaProvider>(context, listen: false).fazendaSelecionada;
    if (fazenda != null) {
      Provider.of<AnimalProvider>(context, listen: false).carregarAnimaisFazenda(fazenda.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnimalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Animais')),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => provider.filtrar(query),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou nº brinco...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.filtrar('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Seletor de mês
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _selecionarMes(provider),
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
                              _meses[_mesSelecionado],
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
                    onTap: () => _selecionarAno(provider),
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
                              _anoSelecionado == 0 ? 'Todos' : '$_anoSelecionado',
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
          const SizedBox(height: 8),
          // Lista
          Expanded(
            child: provider.erro != null && provider.animais.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 56,
                            color: AppTheme.reprovada,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.erro!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _carregarAnimais,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                : provider.animais.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets, size: 64, color: AppTheme.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum animal encontrado',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.animais.length,
                    itemBuilder: (context, index) {
                      final animal = provider.animais[index];
                      return AnimalListTile(
                        animal: animal,
                        onEdit: () {
                          Navigator.pushNamed(
                            context,
                            '/registrar-nascimento',
                            arguments: {'animal': animal},
                          );
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Excluir Animal'),
                              content: Text(
                                'Tem certeza que deseja excluir o animal nº ${animal.numero} (${animal.nome})?\nEsta ação não pode ser desfeita.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final ok = await provider.excluirAnimal(
                                      animal,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Animal excluído com sucesso.'
                                              : provider.erro ??
                                                    'Não foi possível excluir o animal.',
                                        ),
                                        backgroundColor: ok
                                            ? AppTheme.aprovada
                                            : AppTheme.reprovada,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.reprovada,
                                  ),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selecionarMes(AnimalProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecione o Mês'),
        children: List.generate(_meses.length, (index) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _mesSelecionado = index);
              provider.filtrarPorMes(index);
            },
            child: Text(
              _meses[index],
              style: TextStyle(
                fontWeight: index == _mesSelecionado ? FontWeight.w700 : FontWeight.w400,
                color: index == _mesSelecionado ? AppTheme.primary : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _selecionarAno(AnimalProvider provider) {
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
              setState(() => _anoSelecionado = 0);
              provider.filtrarPorAno(0);
            },
            child: Text(
              'Todos',
              style: TextStyle(
                fontWeight: 0 == _anoSelecionado ? FontWeight.w700 : FontWeight.w400,
                color: 0 == _anoSelecionado ? AppTheme.primary : null,
              ),
            ),
          ),
          ...anosDisponiveis.map((ano) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _anoSelecionado = ano);
                provider.filtrarPorAno(ano);
              },
              child: Text(
                '$ano',
                style: TextStyle(
                  fontWeight: ano == _anoSelecionado ? FontWeight.w700 : FontWeight.w400,
                  color: ano == _anoSelecionado ? AppTheme.primary : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
