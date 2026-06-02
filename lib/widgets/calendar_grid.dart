import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/folga_status.dart';

class CalendarGrid extends StatelessWidget {
  final List<CalendarDay> days;
  final Function(CalendarDay) onDayTap;

  const CalendarGrid({
    super.key,
    required this.days,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho dos dias da semana
        Row(
          children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Grid de dias
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            return _buildDayCell(day);
          },
        ),
      ],
    );
  }

  Widget _buildDayCell(CalendarDay day) {
    if (day.status == FolgaStatus.VAZIO) {
      return const SizedBox();
    }

    Color? bgColor;
    Color textColor = AppTheme.textPrimary;

    switch (day.status) {
      case FolgaStatus.APROVADA:
        bgColor = AppTheme.aprovada;
        textColor = Colors.white;
        break;
      case FolgaStatus.PENDENTE:
        bgColor = AppTheme.pendente;
        textColor = Colors.white;
        break;
      case FolgaStatus.REPROVADA:
        bgColor = AppTheme.reprovada;
        textColor = Colors.white;
        break;
      default:
        bgColor = null;
    }

    return GestureDetector(
      onTap: () => onDayTap(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            day.day.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bgColor != null ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
