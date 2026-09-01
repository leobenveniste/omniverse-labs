import 'package:flutter/material.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../services/storage_service.dart';
import '../widgets/about_dialog_widget.dart';
import '../widgets/dice_roller_widget.dart';
import '../widgets/finger_roulette_widget.dart';
import '../widgets/turn_timer_widget.dart';
import '../widgets/coin_flipper_widget.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'truco_screen.dart';
import 'generala_screen.dart';
import 'diez_mil_screen.dart';
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
  int _currentNavIndex = 2; // Default to central "Juegos" tab

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
      case GameType.diezMil:
        screen = DiezMilScreen(existingSession: existingSession);
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
      'Tirador de Dados',
      '¿Quién Empieza?',
      'Central de Juegos',
      'Temporizador',
      'Lanzador de Moneda',
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            Text(
              navTitles[_currentNavIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
          // 0: Dados
          const Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: DiceRollerWidget(),
            ),
          ),
          // 1: Quién Empieza
          const FingerRouletteWidget(),
          // 2: Juegos (Home)
          _buildGamesCatalogTab(theme),
          // 3: Temporizador
          const Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: TurnTimerWidget(),
            ),
          ),
          // 4: Moneda
          const Center(
            child: CoinFlipperWidget(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentNavIndex,
        onItemSelected: (idx) {
          setState(() {
            _currentNavIndex = idx;
          });
        },
      ),
    );
  }

  Widget _buildGamesCatalogTab(ThemeData theme) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // Active Match Banner (if any) with Resume & Discard buttons
              if (_activeSession != null) ...[
                _buildActiveMatchCard(theme),
                const SizedBox(height: 14),
              ],

              // 1. Contador Libre Wide Banner Card (Full width)
              _buildWideBannerCard(
                type: GameType.custom,
                imageAsset: 'assets/images/cards/banner_custom.jpg',
                color: const Color(0xFF1565C0),
                badge: '1-12 Jugadores',
              ),
              const SizedBox(height: 14),

              // 2. 2-Column Vertical Game Cards Grid (Borderless Art with Spanish Titles inside Image)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95, // Clean square-ish game art ratio
                children: [
                  _buildVerticalGameCard(
                    type: GameType.truco,
                    imageAsset: 'assets/images/cards/card_truco.jpg',
                    color: const Color(0xFF2E7D32),
                    badge: '30 Pts',
                  ),
                  _buildVerticalGameCard(
                    type: GameType.generala,
                    imageAsset: 'assets/images/cards/card_generala.jpg',
                    color: const Color(0xFFE65100),
                    badge: 'Oficial',
                  ),
                  _buildVerticalGameCard(
                    type: GameType.diezMil,
                    imageAsset: 'assets/images/cards/card_diez_mil.jpg',
                    color: const Color(0xFFF57F17),
                    badge: '10.000 Pts',
                  ),
                  _buildVerticalGameCard(
                    type: GameType.burako,
                    imageAsset: 'assets/images/cards/card_burako.jpg',
                    color: const Color(0xFF7B1FA2),
                    badge: '3000 Pts',
                  ),
                  _buildVerticalGameCard(
                    type: GameType.escoba,
                    imageAsset: 'assets/images/cards/card_escoba.jpg',
                    color: const Color(0xFF00838F),
                    badge: 'Oficial',
                  ),
                ],
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
        padding: const EdgeInsets.all(14.0),
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
            const SizedBox(height: 8),
            Text(
              session.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openGame(session.gameType, existingSession: session),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reanudar Partida'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBannerCard({
    required GameType type,
    required String imageAsset,
    required Color color,
    required String badge,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withOpacity(isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openGame(type),
        child: SizedBox(
          height: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Banner Image with Spanish Title already inside
              Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
              // Badge Top Right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalGameCard({
    required GameType type,
    required String imageAsset,
    required Color color,
    required String badge,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withOpacity(isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openGame(type),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full 3D Card Artwork with Spanish Title inside Image
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
            ),
            // Badge Top Right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
