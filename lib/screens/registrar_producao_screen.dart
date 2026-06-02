import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/producao_provider.dart';
import '../widgets/loading_button.dart';

class RegistrarProducaoScreen extends StatefulWidget {
  const RegistrarProducaoScreen({super.key});

  @override
  State<RegistrarProducaoScreen> createState() => _RegistrarProducaoScreenState();
}

class _RegistrarProducaoScreenState extends State<RegistrarProducaoScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  double _total = 0.0;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _calcularTotal() {
    double total = 0.0;
    for (var c in _controllers) {
      total += double.tryParse(c.text) ?? 0.0;
    }
    setState(() => _total = total);
  }

  void _adicionarTanque() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProducaoProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Produção')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card resumo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.water_drop, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Total do Dia: ${_total.toStringAsFixed(2)} Litros',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tanques',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Campos de tanques
            ...List.generate(_controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[index],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calcularTotal(),
                  decoration: InputDecoration(
                    labelText: 'Tanque ${index + 1} (Litros)',
                    prefixIcon: const Icon(Icons.opacity),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            // Botão adicionar tanque
            Center(
              child: TextButton.icon(
                onPressed: _adicionarTanque,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Adicionar Tanque'),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              text: 'Salvar Produção',
              isLoading: provider.loading,
              onPressed: () async {
                final valores = _controllers
                    .map((c) => double.tryParse(c.text) ?? 0.0)
                    .toList();
                final ok = await provider.salvarProducao(valores);
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produção salva com sucesso!'),
                      backgroundColor: AppTheme.aprovada,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insira valor em pelo menos um tanque'),
                      backgroundColor: AppTheme.reprovada,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
