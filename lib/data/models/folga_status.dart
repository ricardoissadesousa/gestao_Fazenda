// Os nomes em maiúsculas são mantidos por compatibilidade com os dados salvos.
// ignore_for_file: constant_identifier_names

enum FolgaStatus { DISPONIVEL, PENDENTE, APROVADA, REPROVADA, VAZIO }

class CalendarDay {
  final int day;
  final FolgaStatus status;
  final String fullDate;

  CalendarDay({
    required this.day,
    this.status = FolgaStatus.DISPONIVEL,
    this.fullDate = '',
  });
}

String formatarDataFolga(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

/// Gera todos os espaços e dias visíveis de um mês.
///
/// A grade é local e, portanto, continua aparecendo mesmo enquanto as
/// solicitações ainda estão sendo carregadas.
List<CalendarDay> gerarDiasDoMes(
  DateTime mesAtual,
  Map<String, FolgaStatus> statusPorData,
) {
  final dias = <CalendarDay>[];
  final primeiroDia = DateTime(mesAtual.year, mesAtual.month, 1);
  final espacosIniciais = primeiroDia.weekday % 7; // 0 = domingo
  final quantidadeDias = DateTime(mesAtual.year, mesAtual.month + 1, 0).day;

  for (var i = 0; i < espacosIniciais; i++) {
    dias.add(CalendarDay(day: 0, status: FolgaStatus.VAZIO));
  }

  for (var dia = 1; dia <= quantidadeDias; dia++) {
    final data = DateTime(mesAtual.year, mesAtual.month, dia);
    final dataFormatada = formatarDataFolga(data);
    dias.add(
      CalendarDay(
        day: dia,
        status: statusPorData[dataFormatada] ?? FolgaStatus.DISPONIVEL,
        fullDate: dataFormatada,
      ),
    );
  }

  return dias;
}
