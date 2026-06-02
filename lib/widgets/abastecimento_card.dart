import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/abastecimento.dart';
import 'package:intl/intl.dart';

class AbastecimentoCard extends StatelessWidget {
  final Abastecimento abastecimento;

  const AbastecimentoCard({
    super.key,
    required this.abastecimento,
  });

  @override
  Widget build(BuildContext context) {
    final sdfDia = DateFormat('dd/MM/yyyy');
    final dataFormatada = abastecimento.data != null
        ? sdfDia.format(abastecimento.data!)
        : '--/--';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _mostrarDetalhes(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.local_gas_station, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      abastecimento.equipamento,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${abastecimento.motorista} • $dataFormatada',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${abastecimento.litros.toStringAsFixed(1)} L',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    'Hor: ${abastecimento.horimetro}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context) {
    final sdfDetalhes = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Abastecimento'),
        content: Text(
          '📅 Data: ${abastecimento.data != null ? sdfDetalhes.format(abastecimento.data!) : "--"}\n\n'
          '🚜 Veículo: ${abastecimento.equipamento}\n'
          '⛽ Litros: ${abastecimento.litros}\n'
          '👤 Motorista: ${abastecimento.motorista}\n'
          '⏱ Horímetro: ${abastecimento.horimetro}\n\n'
          '📝 Aplicação (Motivo):\n${abastecimento.aplicacao}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
