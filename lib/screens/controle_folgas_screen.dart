import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../core/app_theme.dart';
import '../core/utils/app_error_messages.dart';
import '../data/models/comunicacao.dart';
import '../data/models/folga_status.dart';
import '../data/services/auth_service.dart';
import '../data/services/comunicacao_service.dart';
import 'package:provider/provider.dart';
import '../providers/fazenda_provider.dart';
import '../providers/auth_provider.dart';
import '../core/utils/fazenda_helper.dart';
import '../widgets/calendar_grid.dart';
import 'package:intl/intl.dart';

class ControleFolgasScreen extends StatefulWidget {
  const ControleFolgasScreen({super.key});

  @override
  State<ControleFolgasScreen> createState() => _ControleFolgasScreenState();
}

class _ControleFolgasScreenState extends State<ControleFolgasScreen> {
  final _comunicacaoService = ComunicacaoService();
  final _authService = AuthService();

  DateTime _currentMonth = DateTime.now();
  List<CalendarDay> _days = [];
  List<Comunicacao> _historico = [];
  Map<String, FolgaStatus> _folgasPorData = {};
  String _nomeUsuario = 'Funcionário';
  bool _carregando = false;
  String? _erroCarregamento;
  String? _contextoCarregado;
  int _requisicaoAtual = 0;

  @override
  void initState() {
    super.initState();
    _days = gerarDiasDoMes(_currentMonth, const {});
    _carregarNome();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Mantém a tela sincronizada tanto com a fazenda ativa do funcionário
    // quanto com a fazenda selecionada pelo gestor.
    context.watch<AuthProvider>();
    context.watch<FazendaProvider>();

    final usuarioId = FirebaseAuth.instance.currentUser?.uid;
    final fazendaId = FazendaHelper.obterFazendaIdAtual(context);
    final novoContexto = '$usuarioId::$fazendaId';
    if (novoContexto == _contextoCarregado) return;

    _contextoCarregado = novoContexto;
    final numeroRequisicao = ++_requisicaoAtual;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || numeroRequisicao != _requisicaoAtual) return;
      _carregarDados(usuarioId: usuarioId, fazendaId: fazendaId);
    });
  }

  Future<void> _carregarNome() async {
    try {
      final nome = await _authService.buscarNomeUsuario();
      if (mounted) setState(() => _nomeUsuario = nome);
    } catch (_) {
      // A saudação padrão continua disponível caso o nome não seja carregado.
    }
  }

  Future<void> _carregarDados({String? usuarioId, String? fazendaId}) async {
    final idUsuario = usuarioId ?? FirebaseAuth.instance.currentUser?.uid;
    final idFazenda = fazendaId ?? FazendaHelper.obterFazendaIdAtual(context);
    final numeroRequisicao = ++_requisicaoAtual;

    if (idUsuario == null || idFazenda == null || idFazenda.isEmpty) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _historico = [];
        _folgasPorData = {};
        _days = gerarDiasDoMes(_currentMonth, const {});
        _erroCarregamento = 'Nenhuma fazenda está selecionada.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    try {
      final comunicacoes = await _comunicacaoService.obterSolicitacoesDoUsuario(
        idUsuario,
        idFazenda,
      );
      if (!mounted || numeroRequisicao != _requisicaoAtual) return;

      final folgasMap = <String, FolgaStatus>{};
      for (final comunicacao in comunicacoes) {
        final data = comunicacao.dataSolicitada;
        if (data.isEmpty) continue;
        folgasMap[data] = switch (comunicacao.status) {
          StatusComunicacao.ACEITO => FolgaStatus.APROVADA,
          StatusComunicacao.RECUSADO => FolgaStatus.REPROVADA,
          StatusComunicacao.PENDENTE => FolgaStatus.PENDENTE,
          StatusComunicacao.VISUALIZADO => FolgaStatus.PENDENTE,
        };
      }

      final formatoData = DateFormat('dd/MM/yyyy');
      final listaOrdenada = List<Comunicacao>.from(comunicacoes)
        ..sort((a, b) {
          try {
            return formatoData
                .parse(b.dataSolicitada)
                .compareTo(formatoData.parse(a.dataSolicitada));
          } catch (_) {
            return 0;
          }
        });

      setState(() {
        _carregando = false;
        _erroCarregamento = null;
        _historico = listaOrdenada;
        _folgasPorData = folgasMap;
        _days = gerarDiasDoMes(_currentMonth, folgasMap);
      });
    } catch (erro) {
      if (!mounted || numeroRequisicao != _requisicaoAtual) return;
      setState(() {
        _carregando = false;
        _erroCarregamento = AppErrorMessages.from(
          erro,
          fallback:
              'Não foi possível carregar as solicitações. Tente novamente.',
        );
        _days = gerarDiasDoMes(_currentMonth, _folgasPorData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Folgas')),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saudação
              Text(
                'Olá, $_nomeUsuario',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              // Navegação de mês
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _alterarMes(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            mesAno[0].toUpperCase() + mesAno.substring(1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _alterarMes(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CalendarGrid(days: _days, onDayTap: _onDayTap),
                      if (_carregando) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              if (_erroCarregamento != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.reprovada.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.reprovada),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_erroCarregamento!)),
                      TextButton(
                        onPressed: _carregarDados,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Legenda
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegend(AppTheme.pendente, 'Pendente'),
                  _buildLegend(AppTheme.aprovada, 'Aprovada'),
                  _buildLegend(AppTheme.reprovada, 'Recusada'),
                ],
              ),
              const SizedBox(height: 24),
              // Histórico
              Text(
                'Histórico de Solicitações',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_carregando && _historico.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Carregando solicitações...',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                )
              else if (_historico.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nenhuma solicitação ainda',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                )
              else
                ...List.generate(_historico.length, (index) {
                  final item = _historico[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(
                          item.status,
                        ).withValues(alpha: 0.15),
                        child: Icon(
                          _statusIcon(item.status),
                          color: _statusColor(item.status),
                          size: 20,
                        ),
                      ),
                      title: const Text('Solicitação de Folga'),
                      subtitle: Text(
                        'Solicitado para o dia: ${item.dataSolicitada}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            item.status,
                          ).withValues(alpha: 0.1),
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
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _alterarMes(int quantidade) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + quantidade,
      );
      _days = gerarDiasDoMes(_currentMonth, _folgasPorData);
    });
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _statusColor(StatusComunicacao status) {
    return switch (status) {
      StatusComunicacao.ACEITO => AppTheme.aprovada,
      StatusComunicacao.PENDENTE => AppTheme.pendente,
      StatusComunicacao.RECUSADO => AppTheme.reprovada,
      StatusComunicacao.VISUALIZADO => AppTheme.pendente,
    };
  }

  IconData _statusIcon(StatusComunicacao status) {
    return switch (status) {
      StatusComunicacao.ACEITO => Icons.check_circle,
      StatusComunicacao.PENDENTE => Icons.schedule,
      StatusComunicacao.RECUSADO => Icons.cancel,
      StatusComunicacao.VISUALIZADO => Icons.visibility,
    };
  }

  String _statusText(StatusComunicacao status) {
    return switch (status) {
      StatusComunicacao.ACEITO => 'Aprovada',
      StatusComunicacao.PENDENTE => 'Pendente',
      StatusComunicacao.RECUSADO => 'Recusada',
      StatusComunicacao.VISUALIZADO => 'Visualizada',
    };
  }

  void _onDayTap(CalendarDay day) {
    if (day.status == FolgaStatus.DISPONIVEL) {
      _mostrarDialogSolicitar(day.fullDate);
    } else {
      final statusTexto = switch (day.status) {
        FolgaStatus.PENDENTE => 'Pendente',
        FolgaStatus.APROVADA => 'Aprovada',
        FolgaStatus.REPROVADA => 'Recusada',
        _ => '',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dia ${day.day}: Solicitação $statusTexto')),
      );
    }
  }

  Future<void> _mostrarDialogSolicitar(String data) async {
    var motivo = '';
    var enviando = false;
    String? mensagemErro;

    final enviada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Solicitar Folga'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Você está solicitando folga para o dia $data.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: motivo,
                onChanged: (valor) => motivo = valor,
                enabled: !enviando,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Descreva o motivo...',
                  errorText: mensagemErro,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: enviando
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      final usuario = FirebaseAuth.instance.currentUser;
                      final fazendaId = FazendaHelper.obterFazendaIdAtual(
                        this.context,
                      );

                      if (usuario == null) {
                        setDialogState(() {
                          mensagemErro =
                              'Sua sessão expirou. Entre novamente para continuar.';
                        });
                        return;
                      }
                      if (fazendaId == null || fazendaId.isEmpty) {
                        setDialogState(() {
                          mensagemErro = 'Nenhuma fazenda está selecionada.';
                        });
                        return;
                      }

                      setDialogState(() {
                        enviando = true;
                        mensagemErro = null;
                      });

                      try {
                        final nome = await _authService.buscarNomeUsuario();
                        await _comunicacaoService.criarSolicitacaoFolga(
                          usuarioId: usuario.uid,
                          usuarioNome: nome,
                          usuarioEmail: usuario.email ?? '',
                          dataSolicitada: data,
                          motivo: motivo.trim(),
                          fazendaId: fazendaId,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (erro) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          enviando = false;
                          mensagemErro = AppErrorMessages.from(
                            erro,
                            fallback:
                                'Não foi possível enviar a solicitação. Tente novamente.',
                          );
                        });
                      }
                    },
              child: enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (enviada == true && mounted) {
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada!'),
          backgroundColor: AppTheme.aprovada,
        ),
      );
    }
  }
}
