import 'package:cloud_firestore/cloud_firestore.dart';

class Fazenda {
  final String id;
  final String nome;
  final String proprietarioId;
  final String endereco;
  final String codigoVinculo;
  final DateTime? dataCriacao;
  final bool ativa;

  Fazenda({
    this.id = '',
    this.nome = '',
    this.proprietarioId = '',
    this.endereco = '',
    this.codigoVinculo = '',
    this.dataCriacao,
    this.ativa = true,
  });

  factory Fazenda.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Fazenda(
      id: doc.id,
      nome: data['nome'] ?? '',
      proprietarioId: data['proprietario_id'] ?? '',
      endereco: data['endereco'] ?? '',
      codigoVinculo: data['codigo_vinculo'] ?? '',
      dataCriacao: (data['data_criacao'] as Timestamp?)?.toDate(),
      ativa: data['ativa'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'proprietario_id': proprietarioId,
      'endereco': endereco,
      'codigo_vinculo': codigoVinculo,
      'data_criacao': dataCriacao != null
          ? Timestamp.fromDate(dataCriacao!)
          : FieldValue.serverTimestamp(),
      'ativa': ativa,
    };
  }

  Fazenda copyWith({
    String? id,
    String? nome,
    String? proprietarioId,
    String? endereco,
    String? codigoVinculo,
    DateTime? dataCriacao,
    bool? ativa,
  }) {
    return Fazenda(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      proprietarioId: proprietarioId ?? this.proprietarioId,
      endereco: endereco ?? this.endereco,
      codigoVinculo: codigoVinculo ?? this.codigoVinculo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativa: ativa ?? this.ativa,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fazenda && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
