import 'package:firebase_auth/firebase_auth.dart';

enum AuthOperation { login, cadastro, recuperacaoSenha }

/// Exceção para falhas de negócio cuja mensagem pode ser exibida ao usuário.
class UserMessageException implements Exception {
  const UserMessageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converte falhas técnicas em mensagens claras e seguras para a interface.
class AppErrorMessages {
  const AppErrorMessages._();

  static String auth(Object error, AuthOperation operation) {
    if (error is UserMessageException) return error.message;
    if (error is! FirebaseAuthException) {
      return _fallbackAuth(operation);
    }

    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return operation == AuthOperation.login
            ? 'E-mail ou senha incorretos. Confira os dados e tente novamente.'
            : _fallbackAuth(operation);
      case 'invalid-email':
      case 'missing-email':
        return 'Informe um endereço de e-mail válido.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o responsável.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Entre na sua conta ou recupere a senha.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas foram realizadas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
      case 'operation-not-allowed':
        return operation == AuthOperation.recuperacaoSenha
            ? 'A recuperação de senha não está disponível no momento.'
            : 'O acesso por e-mail e senha não está disponível no momento.';
      case 'requires-recent-login':
        return 'Por segurança, entre novamente antes de continuar.';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'Estas credenciais já estão vinculadas a outra conta.';
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'O código de verificação é inválido ou expirou.';
      case 'app-not-authorized':
        return 'Não foi possível validar este aplicativo. Tente novamente mais tarde.';
      case 'internal-error':
        return 'Ocorreu uma falha temporária. Tente novamente em alguns instantes.';
      default:
        return _fallbackAuth(operation);
    }
  }

  static String firebase(
    FirebaseException error, {
    String fallback = 'Não foi possível concluir a operação. Tente novamente.',
  }) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Você não tem permissão para realizar esta ação.';
      case 'unauthenticated':
        return 'Sua sessão expirou. Entre novamente para continuar.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
      case 'deadline-exceeded':
      case 'retry-limit-exceeded':
        return 'A operação demorou mais que o esperado. Tente novamente.';
      case 'not-found':
      case 'object-not-found':
        return 'O registro solicitado não foi encontrado.';
      case 'already-exists':
        return 'Este registro já existe.';
      case 'resource-exhausted':
      case 'quota-exceeded':
        return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';
      case 'invalid-argument':
        return 'Algum dado informado é inválido. Revise as informações e tente novamente.';
      case 'cancelled':
      case 'canceled':
        return 'A operação foi cancelada.';
      default:
        return fallback;
    }
  }

  static String from(
    Object error, {
    String fallback = 'Não foi possível concluir a operação. Tente novamente.',
  }) {
    if (error is UserMessageException) return error.message;
    if (error is FirebaseAuthException) {
      return auth(error, AuthOperation.login);
    }
    if (error is FirebaseException) {
      return firebase(error, fallback: fallback);
    }
    return fallback;
  }

  static String _fallbackAuth(AuthOperation operation) {
    switch (operation) {
      case AuthOperation.login:
        return 'Não foi possível entrar. Confira os dados e tente novamente.';
      case AuthOperation.cadastro:
        return 'Não foi possível criar a conta. Revise os dados e tente novamente.';
      case AuthOperation.recuperacaoSenha:
        return 'Não foi possível enviar o link. Tente novamente.';
    }
  }
}
