import 'dart:convert';
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

    final temFoto = abastecimento.fotoComprovante != null &&
        abastecimento.fotoComprovante!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _mostrarDetalhes(context),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (temFoto)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.photo_camera,
                              size: 14,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context) {
    final sdfDetalhes = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final temFoto = abastecimento.fotoComprovante != null &&
        abastecimento.fotoComprovante!.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Abastecimento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📅 Data: ${abastecimento.data != null ? sdfDetalhes.format(abastecimento.data!) : "--"}\n\n'
                '🚜 Veículo: ${abastecimento.equipamento}\n'
                '⛽ Litros: ${abastecimento.litros}\n'
                '👤 Motorista: ${abastecimento.motorista}\n'
                '⏱ Horímetro: ${abastecimento.horimetro}\n\n'
                '📝 Aplicação (Motivo):\n${abastecimento.aplicacao}',
              ),
              if (temFoto) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo_camera, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Comprovante',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => _mostrarFotoAmpliada(context),
                    child: Image.memory(
                      base64Decode(abastecimento.fotoComprovante!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: AppTheme.textHint),
                            const SizedBox(width: 8),
                            Text(
                              'Erro ao carregar imagem',
                              style: TextStyle(color: AppTheme.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Toque na imagem para ampliar',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  /// Exibe a foto em tela cheia
  void _mostrarFotoAmpliada(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Comprovante'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                base64Decode(abastecimento.fotoComprovante!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
