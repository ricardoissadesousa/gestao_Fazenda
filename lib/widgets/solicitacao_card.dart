import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/solicitacao.dart';

class SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final VoidCallback onAprovar;
  final VoidCallback onReprovar;

  const SolicitacaoCard({
    super.key,
    required this.solicitacao,
    required this.onAprovar,
    required this.onReprovar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primarySurface,
                  child: Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitacao.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        solicitacao.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📅 Data: ${solicitacao.data}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            if (solicitacao.motivo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Motivo: ${solicitacao.motivo}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onReprovar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.reprovada,
                    side: BorderSide(color: AppTheme.reprovada),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reprovar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onAprovar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.aprovada,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprovar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
