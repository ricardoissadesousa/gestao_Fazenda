import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usuariosCollection => _firestore.collection('usuarios');

  /// Login com email e senha
  Future<Usuario> login(String email, String senha) async {
    final authResult = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    final uid = authResult.user?.uid;
    if (uid == null) throw Exception('Usuário não encontrado');

    final userDoc = await _usuariosCollection.doc(uid).get();
    if (!userDoc.exists) throw Exception('Dados do usuário não encontrados');

    return Usuario.fromFirestore(userDoc);
  }

  /// Registrar novo usuário
  Future<Usuario> registrar(String email, String senha, String nome, String tipo) async {
    final authResult = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    final uid = authResult.user?.uid;
    if (uid == null) throw Exception('Erro ao criar usuário');

    final usuario = Usuario(
      id: uid,
      email: email,
      nome: nome,
      tipo: tipo.toUpperCase() == 'GESTOR' ? TipoUsuario.GESTOR : TipoUsuario.FUNCIONARIO,
    );

    await _usuariosCollection.doc(uid).set(usuario.toFirestore());
    return usuario;
  }

  /// Observar estado do usuário atual
  Stream<Usuario?> obterUsuarioAtual() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _usuariosCollection.doc(user.uid).get();
      if (!doc.exists) return null;
      return Usuario.fromFirestore(doc);
    });
  }

  /// Buscar nome do usuário logado
  Future<String> buscarNomeUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return 'Funcionário';
    final doc = await _usuariosCollection.doc(user.uid).get();
    if (!doc.exists) return 'Funcionário';
    return (doc.data() as Map<String, dynamic>)['nome'] ?? 'Funcionário';
  }

  /// Logout
  void logout() {
    _auth.signOut();
  }

  /// Verifica se há usuário logado
  bool isUsuarioLogado() {
    return _auth.currentUser != null;
  }

  /// Retorna o UID do usuário logado
  String? get currentUserId => _auth.currentUser?.uid;

  /// Retorna o email do usuário logado
  String? get currentUserEmail => _auth.currentUser?.email;
}
