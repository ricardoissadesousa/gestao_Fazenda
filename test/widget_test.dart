import 'package:app_gestao_fazenda/core/app_theme.dart';
import 'package:app_gestao_fazenda/core/utils/app_error_messages.dart';
import 'package:app_gestao_fazenda/data/models/abastecimento.dart';
import 'package:app_gestao_fazenda/data/models/historico_preco.dart';
import 'package:app_gestao_fazenda/data/models/folga_status.dart';
import 'package:app_gestao_fazenda/widgets/abastecimento_card.dart';
import 'package:app_gestao_fazenda/widgets/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('reconhece comprovante salvo pelo caminho do Storage', () {
    final abastecimento = Abastecimento(
      fotoComprovantePath: 'fazendas/f1/abastecimentos/a1/comprovante.jpg',
    );

    expect(abastecimento.temFotoComprovante, isTrue);
  });

  test('gera um documento de preco diferente para cada competencia', () {
    expect(HistoricoPreco.gerarId(10, 2026), '2026-10');
    expect(HistoricoPreco.gerarId(11, 2026), '2026-11');
    expect(
      HistoricoPreco.gerarId(10, 2026),
      isNot(HistoricoPreco.gerarId(11, 2026)),
    );
  });

  test('traduz credencial inválida sem expor mensagem técnica', () {
    final mensagem = AppErrorMessages.auth(
      FirebaseAuthException(code: 'invalid-credential'),
      AuthOperation.login,
    );

    expect(
      mensagem,
      'E-mail ou senha incorretos. Confira os dados e tente novamente.',
    );
    expect(mensagem.toLowerCase(), isNot(contains('firebase')));
    expect(mensagem, isNot(contains('invalid-credential')));
  });

  test('personaliza erros de cadastro e conexão', () {
    expect(
      AppErrorMessages.auth(
        FirebaseAuthException(code: 'email-already-in-use'),
        AuthOperation.cadastro,
      ),
      'Este e-mail já está cadastrado. Entre na sua conta ou recupere a senha.',
    );
    expect(
      AppErrorMessages.firebase(
        FirebaseException(plugin: 'teste', code: 'unavailable'),
      ),
      'Não foi possível conectar. Verifique sua internet e tente novamente.',
    );
  });

  test('gera todos os dias do calendário sem depender de dados externos', () {
    final dias = gerarDiasDoMes(DateTime(2026, 10), const {});
    final diasDoMes = dias.where((item) => item.day > 0).toList();

    expect(diasDoMes.length, 31);
    expect(diasDoMes.first.fullDate, '01/10/2026');
    expect(diasDoMes.last.fullDate, '31/10/2026');
    expect(
      diasDoMes.every((item) => item.status == FolgaStatus.DISPONIVEL),
      isTrue,
    );
  });

  testWidgets('calendário exibe os dias mesmo sem solicitações', (
    WidgetTester tester,
  ) async {
    final dias = gerarDiasDoMes(DateTime(2026, 10), const {});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: CalendarGrid(days: dias, onDayTap: (_) {}),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
  });

  testWidgets('abre os detalhes do abastecimento com conteudo visivel', (
    WidgetTester tester,
  ) async {
    final abastecimento = Abastecimento(
      data: DateTime(2026, 10, 23, 9, 42),
      motorista: 'Ricardo',
      litros: 50,
      equipamento: 'Trator',
      horimetro: 123,
      aplicacao: 'Servico no pasto',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(body: AbastecimentoCard(abastecimento: abastecimento)),
      ),
    );

    await tester.tap(find.text('Trator').first);
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do Abastecimento'), findsOneWidget);
    expect(find.text('Motorista'), findsOneWidget);
    expect(find.text('Ricardo'), findsOneWidget);
    expect(
      find.text('Este abastecimento não possui comprovante.'),
      findsOneWidget,
    );
  });
}
