import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_session.dart';
import '../models/game_type.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameSession> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService.loadHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  void _deleteSession(String id) async {
    await StorageService.deleteHistoryItem(id);
    _loadHistory();
  }

  void _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar Historial'),
        content: const Text('¿Estás seguro de que deseas eliminar todo el historial de partidas?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar Todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Partidas'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Borrar Todo',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off, size: 72, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text(
                        'No hay partidas finalizadas aún',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Las partidas completadas aparecerán aquí',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final session = _history[idx];
                    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(session.dateStarted);

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getGameIcon(session.gameType),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          session.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (session.winnerName != null)
                              Row(
                                children: [
                                  const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ganador: ${session.winnerName}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.amber),
                                  ),
                                ],
                              ),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteSession(session.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getGameIcon(GameType type) {
    switch (type) {
      case GameType.truco:
        return Icons.style;
      case GameType.generala:
        return Icons.casino;
      case GameType.chinchon:
        return Icons.view_carousel;
      case GameType.uno:
        return Icons.filter_none;
      case GameType.burako:
        return Icons.grid_view;
      case GameType.escoba:
        return Icons.cleaning_services;
      case GameType.custom:
        return Icons.calculate;
    }
  }
}
