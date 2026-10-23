import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../data/models/fazenda.dart';
import '../providers/fazenda_provider.dart';

class GerenciarFazendasScreen extends StatefulWidget {
  const GerenciarFazendasScreen({super.key});

  @override
  State<GerenciarFazendasScreen> createState() => _GerenciarFazendasScreenState();
}

class _GerenciarFazendasScreenState extends State<GerenciarFazendasScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FazendaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Fazendas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogFazenda(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Fazenda'),
      ),
      body: provider.fazendas.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.agriculture, size: 56, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nenhuma fazenda cadastrada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione sua primeira propriedade',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.fazendas.length,
              itemBuilder: (context, index) {
                final fazenda = provider.fazendas[index];
                return _buildFazendaCard(context, fazenda, provider);
              },
            ),
    );
  }

  Widget _buildFazendaCard(
    BuildContext context,
    Fazenda fazenda,
    FazendaProvider provider,
  ) {
    final isSelected = provider.fazendaSelecionada?.id == fazenda.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected
            ? BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          provider.selecionarFazenda(fazenda);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fazenda "${fazenda.nome}" selecionada'),
              backgroundColor: AppTheme.aprovada,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fazenda.nome,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (fazenda.endereco.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            fazenda.endereco,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _mostrarDialogFazenda(context, fazenda: fazenda);
                      } else if (value == 'excluir') {
                        _confirmarExclusao(context, fazenda, provider);
                      } else if (value == 'regenerar') {
                        _regenerarCodigo(context, fazenda, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(value: 'regenerar', child: Text('Regenerar Código')),
                      const PopupMenuItem(
                        value: 'excluir',
                        child: Text('Excluir', style: TextStyle(color: AppTheme.reprovada)),
                      ),
                    ],
                  ),
                ],
              ),
              // Código de vínculo
              if (fazenda.codigoVinculo.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, size: 20, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código para funcionários',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fazenda.codigoVinculo,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Material(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: fazenda.codigoVinculo));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Código copiado!'),
                                backgroundColor: AppTheme.aprovada,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.copy, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogFazenda(BuildContext context, {Fazenda? fazenda}) {
    final nomeController = TextEditingController(text: fazenda?.nome ?? '');
    final enderecoController = TextEditingController(text: fazenda?.endereco ?? '');
    final isEditing = fazenda != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Fazenda' : 'Nova Fazenda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Fazenda *',
                hintText: 'Ex: Fazenda Boa Vista',
                prefixIcon: Icon(Icons.agriculture),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: enderecoController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Endereço (opcional)',
                hintText: 'Localização da propriedade',
                prefixIcon: Icon(Icons.location_on),
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
              final nome = nomeController.text.trim();
              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe o nome da fazenda')),
                );
                return;
              }

              final provider = context.read<FazendaProvider>();
              bool ok;

              if (isEditing) {
                ok = await provider.atualizarFazenda(
                  fazenda.copyWith(
                    nome: nome,
                    endereco: enderecoController.text.trim(),
                  ),
                );
              } else {
                ok = await provider.adicionarFazenda(
                  Fazenda(
                    nome: nome,
                    endereco: enderecoController.text.trim(),
                  ),
                );
              }

              if (context.mounted) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                if (ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Fazenda atualizada!'
                          : 'Fazenda criada! Compartilhe o código com seus funcionários.'),
                      backgroundColor: AppTheme.aprovada,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.erro ??
                            'Não foi possível salvar a fazenda. Tente novamente.',
                      ),
                      backgroundColor: AppTheme.reprovada,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(
    BuildContext context,
    Fazenda fazenda,
    FazendaProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Fazenda'),
        content: Text('Deseja realmente excluir "${fazenda.nome}"?\n\n'
            'Os dados associados serão mantidos no histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await provider.desativarFazenda(fazenda.id);
              if (context.mounted) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Fazenda removida.'
                          : provider.erro ??
                                'Não foi possível remover a fazenda.',
                    ),
                    backgroundColor: ok
                        ? AppTheme.aprovada
                        : AppTheme.reprovada,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reprovada),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _regenerarCodigo(
    BuildContext context,
    Fazenda fazenda,
    FazendaProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerar Código'),
        content: const Text(
          'Deseja gerar um novo código de vínculo?\n\n'
          'O código anterior será invalidado e funcionários que ainda não '
          'se vincularam precisarão usar o novo código.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoCodigo = await provider.regenerarCodigo(fazenda.id);
              if (context.mounted) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                if (novoCodigo != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Novo código gerado: $novoCodigo'),
                      backgroundColor: AppTheme.aprovada,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.erro ??
                            'Não foi possível gerar um novo código.',
                      ),
                      backgroundColor: AppTheme.reprovada,
                    ),
                  );
                }
              }
            },
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );
  }
}
