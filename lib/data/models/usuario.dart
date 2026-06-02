import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoUsuario { GESTOR, FUNCIONARIO }

class Usuario {
  final String id;
  final String email;
  final String nome;
  final TipoUsuario tipo;

  Usuario({
    this.id = '',
    this.email = '',
    this.nome = '',
    this.tipo = TipoUsuario.FUNCIONARIO,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Usuario(
      id: doc.id,
      email: data['email'] ?? '',
      nome: data['nome'] ?? '',
      tipo: data['tipo'] == 'GESTOR' ? TipoUsuario.GESTOR : TipoUsuario.FUNCIONARIO,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nome': nome,
      'tipo': tipo == TipoUsuario.GESTOR ? 'GESTOR' : 'FUNCIONARIO',
    };
  }

  Usuario copyWith({
    String? id,
    String? email,
    String? nome,
    TipoUsuario? tipo,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
    );
  }
}
