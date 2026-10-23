import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/utils/app_error_messages.dart';
import '../data/services/producao_leite_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/fazenda_provider.dart';

class RelatorioMensalScreen extends StatefulWidget {
  const RelatorioMensalScreen({super.key});

  @override
  State<RelatorioMensalScreen> createState() => _RelatorioMensalScreenState();
}

class _RelatorioMensalScreenState extends State<RelatorioMensalScreen> {
  final _producaoService = ProducaoLeiteService();

  final _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  int _mesSelecionado = DateTime.now().month - 1;
  int _anoSelecionado = DateTime.now().year;
  double _precoLeite = 2.85;
  double _totalLitros = 0.0;
  double _mediaDiaria = 0.0;
  bool _loading = true;
  bool _carregamentoEmAndamento = false;
  String? _fazendaCarregadaId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fazenda = context.watch<FazendaProvider>().fazendaSelecionada;
    if (fazenda != null &&
        fazenda.id != _fazendaCarregadaId &&
        !_carregamentoEmAndamento) {
      _fazendaCarregadaId = fazenda.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _carregarDados();
      });
    }
  }

  Future<void> _carregarDados() async {
    if (!mounted || _carregamentoEmAndamento) return;
    _carregamentoEmAndamento = true;
    setState(() => _loading = true);
    try {
      await _carregarRelatorio();
    } on FirebaseException catch (erro) {
      debugPrint('Erro Firebase no relatório: ${erro.code} - ${erro.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_mensagemErroFirebase(erro))));
      }
    } catch (erro, stackTrace) {
      debugPrint('Erro no relatório: $erro');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.from(
                erro,
                fallback:
                    'Não foi possível carregar o relatório. Tente novamente.',
              ),
            ),
          ),
        );
      }
    } finally {
      _carregamentoEmAndamento = false;
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _carregarRelatorio() async {
    final mes = _mesSelecionado + 1;
    final ano = _anoSelecionado;

    // Extrair fazenda antes do await
    final fazenda = context.read<FazendaProvider>().fazendaSelecionada;
    if (fazenda == null) {
      return;
    }

    // O relatório de produção continua carregando mesmo se somente o preço
    // estiver temporariamente inacessível por regra do Firestore.
    try {
      _precoLeite = await _producaoService.obterPrecoLeitePorPeriodo(
        fazenda.id,
        mes,
        ano,
      );
    } on FirebaseException catch (erro) {
      debugPrint('Preço do leite indisponível: ${erro.code} - ${erro.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_mensagemErroPreco(erro))));
      }
    }

    final producoes = await _producaoService.obterProducoesPorMes(
      mes,
      ano,
      fazenda.id,
    );
    double total = 0.0;
    for (var p in producoes) {
      total += p.totalLitros;
    }
    final diasComRegistro = producoes.length;
    if (mounted) {
      setState(() {
        _totalLitros = total;
        _mediaDiaria = diasComRegistro > 0 ? total / diasComRegistro : 0.0;
      });
    }
  }

  String _mensagemErroFirebase(FirebaseException erro) {
    return AppErrorMessages.firebase(
      erro,
      fallback: 'Não foi possível carregar o relatório. Tente novamente.',
    );
  }

  String _mensagemErroPreco(FirebaseException erro) {
    if (erro.code == 'permission-denied') {
      return 'A produção foi carregada, mas você não tem permissão para consultar o preço do leite.';
    }
    return 'A produção foi carregada, mas não foi possível consultar o preço do leite.';
  }

  @override
  Widget build(BuildContext context) {
    final faturamento = _totalLitros * _precoLeite;
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório Mensal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Seletores de mês e ano
                  Row(
                    children: [
                      // Seletor de mês
                      Expanded(
                        child: GestureDetector(
                          onTap: _selecionarMes,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _meses[_mesSelecionado],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                      SizedBox(
                        width: 110,
                        child: GestureDetector(
                          onTap: _selecionarAno,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_anoSelecionado',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 24),
                  // Cards de resumo
                  _buildStatCard(
                    icon: Icons.water_drop,
                    title: 'Total Produzido',
                    value:
                        '${NumberFormat('#,##0', 'pt_BR').format(_totalLitros)} L',
                    color: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.trending_up,
                    title: 'Média Diária',
                    value:
                        '${NumberFormat('#,##0', 'pt_BR').format(_mediaDiaria)} L',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _editarPreco,
                    child: _buildStatCard(
                      icon: Icons.attach_money,
                      title:
                          'Preço do Leite — ${_meses[_mesSelecionado]}/$_anoSelecionado (toque para editar)',
                      value: nf.format(_precoLeite),
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Faturamento Estimado',
                    value: nf.format(faturamento),
                    color: const Color(0xFF6A1B9A),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
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
              setState(() => _mesSelecionado = index);
              _carregarDados();
            },
            child: Text(
              _meses[index],
              style: TextStyle(
                fontWeight: index == _mesSelecionado
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: index == _mesSelecionado ? AppTheme.primary : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _selecionarAno() {
    final anoAtual = DateTime.now().year;
    final anos = List.generate(7, (i) => anoAtual - 5 + i);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecione o Ano'),
        children: anos.map((ano) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _anoSelecionado = ano);
              _carregarDados();
            },
            child: Text(
              '$ano',
              style: TextStyle(
                fontWeight: ano == _anoSelecionado
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: ano == _anoSelecionado ? AppTheme.primary : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _editarPreco() {
    final controller = TextEditingController(
      text: _precoLeite.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Preço do Leite — ${_meses[_mesSelecionado]}/$_anoSelecionado',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'O preço será salvo especificamente para ${_meses[_mesSelecionado]} de $_anoSelecionado.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Ex: 3.10',
                prefixText: 'R\$ ',
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
              final fazenda = context
                  .read<FazendaProvider>()
                  .fazendaSelecionada;
              if (fazenda == null) return;

              final valor = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (valor == null || valor <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe um preço válido.')),
                );
                return;
              }

              try {
                await _producaoService.atualizarPrecoLeite(
                  fazenda.id,
                  valor,
                  mes: _mesSelecionado + 1,
                  ano: _anoSelecionado,
                );
                setState(() => _precoLeite = valor);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Preço de ${_meses[_mesSelecionado]}/$_anoSelecionado salvo!',
                      ),
                    ),
                  );
                }
              } on FirebaseException catch (erro) {
                debugPrint(
                  'Erro ao salvar preço: ${erro.code} - ${erro.message}',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        erro.code == 'permission-denied'
                            ? 'Você não tem permissão para alterar o preço do leite.'
                            : AppErrorMessages.firebase(
                                erro,
                                fallback:
                                    'Não foi possível salvar o preço. Tente novamente.',
                              ),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
