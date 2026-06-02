enum FolgaStatus {
  DISPONIVEL,
  PENDENTE,
  APROVADA,
  REPROVADA,
  VAZIO,
}

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
