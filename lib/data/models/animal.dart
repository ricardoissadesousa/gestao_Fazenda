import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  String id;
  final String numero;
  final String nome;
  final String sexo;
  final String nascimento;
  final String mae;

  Animal({
    this.id = '',
    this.numero = '',
    this.nome = '',
    this.sexo = '',
    this.nascimento = '',
    this.mae = '',
  });

  factory Animal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Animal(
      id: doc.id,
      numero: data['numero'] ?? '',
      nome: data['nome'] ?? '',
      sexo: data['sexo'] ?? '',
      nascimento: data['nascimento'] ?? '',
      mae: data['mae'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'numero': numero,
      'nome': nome,
      'sexo': sexo,
      'nascimento': nascimento,
      'mae': mae,
    };
  }

  Animal copyWith({
    String? id,
    String? numero,
    String? nome,
    String? sexo,
    String? nascimento,
    String? mae,
  }) {
    return Animal(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      nome: nome ?? this.nome,
      sexo: sexo ?? this.sexo,
      nascimento: nascimento ?? this.nascimento,
      mae: mae ?? this.mae,
    );
  }
}
