import 'package:flutter/material.dart';

class QuickScoreDialog extends StatefulWidget {
  final String playerName;
  final int currentScore;
  final ValueChanged<int> onApply;

  const QuickScoreDialog({
    super.key,
    required this.playerName,
    required this.currentScore,
    required this.onApply,
  });

  @override
  State<QuickScoreDialog> createState() => _QuickScoreDialogState();
}

class _QuickScoreDialogState extends State<QuickScoreDialog> {
  int _delta = 0;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(int amount) {
    setState(() {
      _delta += amount;
      _controller.text = _delta.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Anotar a ${widget.playerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Puntaje actual: ${widget.currentScore}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0',
              prefixIcon: const Icon(Icons.exposure),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val) ?? 0;
              setState(() {
                _delta = parsed;
              });
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _presetChip('+1', () => _add(1)),
              _presetChip('+2', () => _add(2)),
              _presetChip('+5', () => _add(5)),
              _presetChip('+10', () => _add(10)),
              _presetChip('+25', () => _add(25)),
              _presetChip('-1', () => _add(-1), isNegative: true),
              _presetChip('-5', () => _add(-5), isNegative: true),
              _presetChip('-10', () => _add(-10), isNegative: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nuevo total: ${widget.currentScore + _delta}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onApply(_delta);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _presetChip(String label, VoidCallback onTap, {bool isNegative = false}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isNegative ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
      labelStyle: TextStyle(color: isNegative ? Colors.red : Colors.green),
      onPressed: onTap,
    );
  }
}
