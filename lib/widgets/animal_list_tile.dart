import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/animal.dart';

class AnimalListTile extends StatelessWidget {
  final Animal animal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnimalListTile({
    super.key,
    required this.animal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primarySurface,
          child: Text(
            animal.numero,
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          animal.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${animal.sexo} • Mãe: ${animal.mae} • Nasc: ${animal.nascimento}',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: AppTheme.reprovada, size: 20),
              tooltip: 'Excluir',
            ),
          ],
        ),
      ),
    );
  }
}
