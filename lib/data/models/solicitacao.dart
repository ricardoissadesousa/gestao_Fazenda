class Solicitacao {
  final String id;
  final String nome;
  final String email;
  final String data;
  final String motivo;

  Solicitacao({
    required this.id,
    this.nome = '',
    this.email = '',
    this.data = '',
    this.motivo = '',
  });
}
