enum StatusFolga { PENDENTE, APROVADA, REPROVADA }

class HistoricoFolga {
  final String nome;
  final String data;
  final StatusFolga status;

  HistoricoFolga({
    required this.nome,
    required this.data,
    required this.status,
  });
}
