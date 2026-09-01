import 'package:flutter/material.dart';

class PlayerNameDialog {
  static Future<String?> show(
    BuildContext context, {
    required String currentName,
    String title = 'Editar Nombre',
  }) async {
    final controller = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del Jugador / Equipo',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            Navigator.of(ctx).pop(trimmed.isEmpty ? currentName : trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.of(ctx).pop(trimmed.isEmpty ? currentName : trimmed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
