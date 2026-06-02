import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../data/models/folga_status.dart';
import '../data/models/historico_folga.dart';
import '../data/services/auth_service.dart';
import '../data/services/folga_service.dart';
import '../widgets/calendar_grid.dart';
import 'package:intl/intl.dart';

class ControleFolgasScreen extends StatefulWidget {
  const ControleFolgasScreen({super.key});

  @override
  State<ControleFolgasScreen> createState() => _ControleFolgasScreenState();
}

class _ControleFolgasScreenState extends State<ControleFolgasScreen> {
  final _folgaService = FolgaService();
  final _authService = AuthService();

  DateTime _currentMonth = DateTime.now();
  List<CalendarDay> _days = [];
  List<HistoricoFolga> _historico = [];
  String _nomeUsuario = 'Funcionário';

  @override
  void initState() {
    super.initState();
    _carregarNome();
    _carregarDados();
  }

  Future<void> _carregarNome() async {
    final nome = await _authService.buscarNomeUsuario();
    setState(() => _nomeUsuario = nome);
  }

  Future<void> _carregarDados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await _folgaService.obterSolicitacoesDoUsuario(user.uid);

    final folgasMap = <String, FolgaStatus>{};
    final listaHist = <HistoricoFolga>[];

    for (var doc in result.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dataSol = data['data_solicitada'] ?? '';
      final statusStr = data['status'] ?? '';

      final folgaStatus = switch (statusStr) {
        'APROVADA' => FolgaStatus.APROVADA,
        'REPROVADA' => FolgaStatus.REPROVADA,
        'PENDENTE' => FolgaStatus.PENDENTE,
        _ => FolgaStatus.DISPONIVEL,
      };
      folgasMap[dataSol] = folgaStatus;

      final historicoStatus = switch (statusStr) {
        'APROVADA' => StatusFolga.APROVADA,
        'REPROVADA' => StatusFolga.REPROVADA,
        _ => StatusFolga.PENDENTE,
      };
      listaHist.add(HistoricoFolga(
        nome: 'Solicitação de Folga',
        data: dataSol,
        status: historicoStatus,
      ));
    }

    // Ordenar por data (mais recente primeiro)
    final sdf = DateFormat('dd/MM/yyyy');
    listaHist.sort((a, b) {
      try {
        return sdf.parse(b.data).compareTo(sdf.parse(a.data));
      } catch (_) {
        return 0;
      }
    });

    setState(() {
      _historico = listaHist;
      _days = _gerarDiasCalendario(folgasMap);
    });
  }

  List<CalendarDay> _gerarDiasCalendario(Map<String, FolgaStatus> folgasMap) {
    final days = <CalendarDay>[];
    final tempCal = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstDayOfWeek = tempCal.weekday % 7; // 0=Dom
    final maxDays = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final dayFormat = DateFormat('dd/MM/yyyy');

    // Espaços em branco antes do dia 1
    for (int i = 0; i < firstDayOfWeek; i++) {
      days.add(CalendarDay(day: 0, status: FolgaStatus.VAZIO));
    }

    for (int day = 1; day <= maxDays; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final fullDate = dayFormat.format(date);
      final status = folgasMap[fullDate] ?? FolgaStatus.DISPONIVEL;
      days.add(CalendarDay(day: day, status: status, fullDate: fullDate));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Folgas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação
            Text(
              'Olá, $_nomeUsuario',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
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
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.year,
                                _currentMonth.month - 1,
                              );
                            });
                            _carregarDados();
                          },
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
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.year,
                                _currentMonth.month + 1,
                              );
                            });
                            _carregarDados();
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CalendarGrid(
                      days: _days,
                      onDayTap: _onDayTap,
                    ),
                  ],
                ),
              ),
            ),
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
            if (_historico.isEmpty)
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
                      backgroundColor: _statusColor(item.status).withValues(alpha: 0.15),
                      child: Icon(
                        _statusIcon(item.status),
                        color: _statusColor(item.status),
                        size: 20,
                      ),
                    ),
                    title: Text(item.nome),
                    subtitle: Text('Solicitado para o dia: ${item.data}'),
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
              }),
          ],
        ),
      ),
    );
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

  Color _statusColor(StatusFolga status) {
    return switch (status) {
      StatusFolga.APROVADA => AppTheme.aprovada,
      StatusFolga.PENDENTE => AppTheme.pendente,
      StatusFolga.REPROVADA => AppTheme.reprovada,
    };
  }

  IconData _statusIcon(StatusFolga status) {
    return switch (status) {
      StatusFolga.APROVADA => Icons.check_circle,
      StatusFolga.PENDENTE => Icons.schedule,
      StatusFolga.REPROVADA => Icons.cancel,
    };
  }

  String _statusText(StatusFolga status) {
    return switch (status) {
      StatusFolga.APROVADA => 'Aprovada',
      StatusFolga.PENDENTE => 'Pendente',
      StatusFolga.REPROVADA => 'Recusada',
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

  void _mostrarDialogSolicitar(String data) {
    final motivoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Descreva o motivo...',
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
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final nome = await _authService.buscarNomeUsuario();
                await _folgaService.criarSolicitacao(
                  usuarioId: user.uid,
                  usuarioNome: nome,
                  usuarioEmail: user.email ?? '',
                  dataSolicitada: data,
                  motivo: motivoController.text,
                );
                if (context.mounted) Navigator.pop(context);
                _carregarDados();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitação enviada!'),
                      backgroundColor: AppTheme.aprovada,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
