import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_list_tile.dart';

class ListaAnimaisScreen extends StatefulWidget {
  const ListaAnimaisScreen({super.key});

  @override
  State<ListaAnimaisScreen> createState() => _ListaAnimaisScreenState();
}

class _ListaAnimaisScreenState extends State<ListaAnimaisScreen> {
  final _searchController = TextEditingController();
  int _mesSelecionado = 0;

  final _meses = [
    'Todos', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

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
          // Filtro por mês
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              initialValue: _mesSelecionado,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              items: List.generate(_meses.length, (i) {
                return DropdownMenuItem(value: i, child: Text(_meses[i]));
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _mesSelecionado = value);
                  provider.filtrarPorMes(value);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          // Lista
          Expanded(
            child: provider.animais.isEmpty
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
                                  onPressed: () {
                                    provider.excluirAnimal(animal);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Animal excluído com sucesso.')),
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
}
