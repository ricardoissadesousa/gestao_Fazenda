import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoUsuario { GESTOR, FUNCIONARIO }

class Usuario {
  final String id;
  final String email;
  final String nome;
  final TipoUsuario tipo;
  /// Lista de IDs das fazendas vinculadas ao funcionário
  final List<String> fazendasIds;

  Usuario({
    this.id = '',
    this.email = '',
    this.nome = '',
    this.tipo = TipoUsuario.FUNCIONARIO,
    this.fazendasIds = const [],
  });

  /// Getter de compatibilidade — retorna o primeiro fazendaId ou null
  String? get fazendaId => fazendasIds.isNotEmpty ? fazendasIds.first : null;

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Lê a lista de fazendas. Se não existir, tenta migrar do campo antigo.
    List<String> fazendas = [];
    if (data['fazendas_ids'] != null && (data['fazendas_ids'] as List).isNotEmpty) {
      fazendas = List<String>.from(data['fazendas_ids']);
    } else if (data['fazenda_id'] != null && data['fazenda_id'].toString().isNotEmpty) {
      fazendas = [data['fazenda_id']];
    }

    return Usuario(
      id: doc.id,
      email: data['email'] ?? '',
      nome: data['nome'] ?? '',
      tipo: data['tipo'] == 'GESTOR' ? TipoUsuario.GESTOR : TipoUsuario.FUNCIONARIO,
      fazendasIds: fazendas,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nome': nome,
      'tipo': tipo == TipoUsuario.GESTOR ? 'GESTOR' : 'FUNCIONARIO',
      'fazendas_ids': fazendasIds,
      // Mantém campo antigo para compatibilidade
      'fazenda_id': fazendaId,
    };
  }

  Usuario copyWith({
    String? id,
    String? email,
    String? nome,
    TipoUsuario? tipo,
    List<String>? fazendasIds,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      fazendasIds: fazendasIds ?? this.fazendasIds,
    );
  }
}
