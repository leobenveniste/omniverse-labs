import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'truco_screen.dart';
import 'generala_screen.dart';
import 'rounds_screen.dart';
import 'burako_screen.dart';
import 'escoba_screen.dart';
import 'custom_counter_screen.dart';
import 'tools_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameSession? _activeSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    final session = await StorageService.loadActiveSession();
    if (mounted) {
      setState(() {
        _activeSession = session;
        _isLoading = false;
      });
    }
  }

  void _openGame(GameType type, {GameSession? existingSession}) async {
    Widget screen;
    switch (type) {
      case GameType.truco:
        screen = TrucoScreen(existingSession: existingSession);
        break;
      case GameType.generala:
        screen = GeneralaScreen(existingSession: existingSession);
        break;
      case GameType.chinchon:
        screen = RoundsScreen(gameType: GameType.chinchon, existingSession: existingSession);
        break;
      case GameType.uno:
        screen = RoundsScreen(gameType: GameType.uno, existingSession: existingSession);
        break;
      case GameType.burako:
        screen = BurakoScreen(existingSession: existingSession);
        break;
      case GameType.escoba:
        screen = EscobaScreen(existingSession: existingSession);
        break;
      case GameType.custom:
        screen = CustomCounterScreen(existingSession: existingSession);
        break;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );

    _loadActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.scoreboard, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 8),
            const Text('Anotador de Juegos', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Cambiar Tema',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Active session banner
                if (_activeSession != null) ...[
                  _buildActiveSessionCard(theme),
                  const SizedBox(height: 16),
                ],

                // Tools card (Quick Access)
                _buildToolsBanner(theme),
                const SizedBox(height: 20),

                // Section Header
                Text(
                  'Elige un Juego',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Game Catalog Grid
                _buildGameCard(
                  title: 'Truco',
                  subtitle: '15, 24 o 30 pts • Fósforos y Números Gigantes',
                  icon: Icons.style,
                  color: AppTheme.trucoGreen,
                  onTap: () => _openGame(GameType.truco),
                ),
                const SizedBox(height: 10),

                _buildGameCard(
                  title: 'Generala',
                  subtitle: 'Planilla oficial • Cálculo automático y servidas',
                  icon: Icons.casino,
                  color: AppTheme.generalaBurgundy,
                  onTap: () => _openGame(GameType.generala),
                ),
                const SizedBox(height: 10),

                _buildGameCard(
                  title: 'Contador Libre Multijugador',
                  subtitle: '1 a 12 jugadores o equipos con sumas rápidas',
                  icon: Icons.calculate,
                  color: AppTheme.customPurple,
                  onTap: () => _openGame(GameType.custom),
                ),
                const SizedBox(height: 10),

                _buildGameCard(
                  title: 'Chinchón / Rummy',
                  subtitle: 'Rondas acumulativas, límite de eliminación y reenganche',
                  icon: Icons.view_carousel,
                  color: AppTheme.chinchonAmber,
                  onTap: () => _openGame(GameType.chinchon),
                ),
                const SizedBox(height: 10),

                _buildGameCard(
                  title: 'Uno',
                  subtitle: 'Conteo de cartas por rondas y límite de puntos',
                  icon: Icons.filter_none,
                  color: AppTheme.unoRed,
                  onTap: () => _openGame(GameType.uno),
                ),
                const SizedBox(height: 10),

                _buildGameCard(
                  title: 'Burako / Canasta',
                  subtitle: 'Canastas puras/impuras, bases, puntos y muertos',
                  icon: Icons.grid_view,
                  color: AppTheme.burakoBlue,
                  onTap: () => _openGame(GameType.burako),
                ),
                const SizedBox(height: 10),

                _buildGameCard(
                  title: 'Escoba de 15 / Tute',
                  subtitle: 'Escobas, 7 de oro, oros, setenta y cartas',
                  icon: Icons.cleaning_services,
                  color: AppTheme.escobaTeal,
                  onTap: () => _openGame(GameType.escoba),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildActiveSessionCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partida en Curso',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _activeSession!.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _activeSession!.gameType.displayName,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => _openGame(_activeSession!.gameType, existingSession: _activeSession),
              child: const Text('Reanudar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsBanner(ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ToolsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handyman, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caja de Herramientas de Mesa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '🎲 Dados • 👆 Quién Empieza • ⏱️ Temporizador • 🪙 Moneda',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
