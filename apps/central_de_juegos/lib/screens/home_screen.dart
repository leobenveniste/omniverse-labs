import 'package:flutter/material.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/about_dialog_widget.dart';
import '../widgets/dice_roller_widget.dart';
import '../widgets/finger_roulette_widget.dart';
import '../widgets/turn_timer_widget.dart';
import '../widgets/coin_flipper_widget.dart';
import 'truco_screen.dart';
import 'generala_screen.dart';
import 'burako_screen.dart';
import 'escoba_screen.dart';
import 'custom_counter_screen.dart';
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
  int _currentNavIndex = 0;

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

  void _discardActiveSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Partida'),
        content: const Text('¿Estás seguro de que deseas descartar la partida en curso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearActiveSession();
      _loadActiveSession();
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
    final isDark = theme.brightness == Brightness.dark;

    final List<String> navTitles = [
      'Central de Juegos',
      'Tirador de Dados',
      '¿Quién Empieza?',
      'Temporizador',
      'Lanzador de Moneda',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            Text(
              navTitles[_currentNavIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Acerca de Omniverse Labs',
            onPressed: () => AboutDialogWidget.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Partidas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Cambiar Tema',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildGamesCatalogTab(theme),
          const Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: DiceRollerWidget(),
            ),
          ),
          const FingerRouletteWidget(),
          const Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: TurnTimerWidget(),
            ),
          ),
          const Center(
            child: CoinFlipperWidget(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentNavIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Juegos',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Dados',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined),
            selectedIcon: Icon(Icons.touch_app),
            label: 'Quién Empieza',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Temporizador',
          ),
          NavigationDestination(
            icon: Icon(Icons.monetization_on_outlined),
            selectedIcon: Icon(Icons.monetization_on),
            label: 'Moneda',
          ),
        ],
      ),
    );
  }

  Widget _buildGamesCatalogTab(ThemeData theme) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Active Match Banner (if any) with Resume & Discard buttons
              if (_activeSession != null) ...[
                _buildActiveMatchCard(theme),
                const SizedBox(height: 18),
              ],

              // Games Catalog Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Catálogo de Juegos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Game Cards: Truco, Generala, Burako, Escoba del 15, Contador Libre
              _buildGameCard(
                type: GameType.truco,
                title: 'Truco',
                subtitle: 'Anotador oficial a 30 puntos con fósforos o números gigantes.',
                icon: Icons.style,
                color: const Color(0xFF2E7D32),
                badge: '30 Puntos',
              ),
              const SizedBox(height: 12),

              _buildGameCard(
                type: GameType.generala,
                title: 'Generala',
                subtitle: 'Planilla oficial completa con cálculo automático y servidas.',
                icon: Icons.casino,
                color: const Color(0xFFE65100),
                badge: '1-6 Jugadores',
              ),
              const SizedBox(height: 12),

              _buildGameCard(
                type: GameType.burako,
                title: 'Burako / Canasta',
                subtitle: 'Canastas puras e impuras, bases, cierre y cartas en mano.',
                icon: Icons.grid_view,
                color: const Color(0xFF6A1B9A),
                badge: 'Por Rondas',
              ),
              const SizedBox(height: 12),

              _buildGameCard(
                type: GameType.escoba,
                title: 'Escoba del 15',
                subtitle: 'Anotador de escobas, cartas, oros, 7 de oro y la setenta.',
                icon: Icons.cleaning_services,
                color: const Color(0xFF00838F),
                badge: 'Oficial',
              ),
              const SizedBox(height: 12),

              _buildGameCard(
                type: GameType.custom,
                title: 'Contador Libre',
                subtitle: 'Suma puntos tocando la tarjeta, personaliza nombres y colores.',
                icon: Icons.calculate,
                color: const Color(0xFF1565C0),
                badge: '1-12 Jugadores',
              ),
              const SizedBox(height: 24),
            ],
          );
  }

  Widget _buildActiveMatchCard(ThemeData theme) {
    final session = _activeSession!;

    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'PARTIDA EN CURSO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Descartar Partida',
                  onPressed: _discardActiveSession,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Juego: ${session.gameType.displayName}',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openGame(session.gameType, existingSession: session),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reanudar Partida'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required GameType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openGame(type),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.disabledColor),
            ],
          ),
        ),
      ),
    );
  }
}
