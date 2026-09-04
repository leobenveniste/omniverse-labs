import 'package:flutter/material.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/about_dialog_widget.dart';
import '../widgets/dice_roller_widget.dart';
import '../widgets/finger_roulette_widget.dart';
import '../widgets/turn_timer_widget.dart';
import '../widgets/coin_flipper_widget.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/paywall_sheet.dart';
import 'game_setup_screen.dart';
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
  PremiumService? _premiumService;
  bool _isLoading = true;
  int _currentNavIndex = 2; // Default to central "Juegos" tab

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _premiumService = await PremiumService.getInstance();
    final session = await StorageService.loadActiveSession();
    if (mounted) {
      setState(() {
        _activeSession = session;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveSession() async {
    final session = await StorageService.loadActiveSession();
    if (mounted) {
      setState(() {
        _activeSession = session;
      });
    }
  }

  void _discardActiveSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Descartar Partida', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas descartar la partida en curso?', style: TextStyle(color: Colors.white70)),
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
    if (existingSession != null) {
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
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      _loadActiveSession();
      return;
    }

    // Games with New Game Player Setup
    if (type == GameType.generala ||
        type == GameType.diezMil ||
        type == GameType.custom ||
        type == GameType.escoba) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GameSetupScreen(
            gameTitle: type.displayName,
            maxPlayers: type == GameType.custom ? 12 : 8,
            onStartGame: (configuredPlayers, config) {
              Widget gameScreen;
              switch (type) {
                case GameType.generala:
                  gameScreen = GeneralaScreen(configuredPlayers: configuredPlayers);
                  break;
                case GameType.diezMil:
                  gameScreen = DiezMilScreen(
                    configuredPlayers: configuredPlayers,
                    entryScore: (config['entryScore'] as int?) ?? 750,
                    minRoundScore: (config['minRoundScore'] as int?) ?? 350,
                  );
                  break;
                case GameType.escoba:
                  gameScreen = EscobaScreen(configuredPlayers: configuredPlayers);
                  break;
                case GameType.custom:
                  gameScreen = CustomCounterScreen(configuredPlayers: configuredPlayers);
                  break;
                default:
                  gameScreen = CustomCounterScreen(configuredPlayers: configuredPlayers);
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => gameScreen),
              );
            },
          ),
        ),
      );
    } else {
      // 2-team direct games (Truco & Burako)
      Widget screen;
      if (type == GameType.truco) {
        screen = const TrucoScreen();
      } else {
        screen = const BurakoScreen();
      }
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    _loadActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<String> navTitles = [
      'TIRADOR_DADOS',
      'QUIEN_EMPIEZA',
      'CENTRAL_DE_JUEGOS',
      'TEMPORIZADOR',
      'LANZADOR_MONEDA',
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_dark.png',
              width: 26,
              height: 26,
            ),
            const SizedBox(width: 8),
            Text(
              navTitles[_currentNavIndex],
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
                color: AppTheme.cyberGold,
              ),
            ),
          ],
        ),
        actions: [
          if (_premiumService != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: AnimatedBuilder(
                animation: _premiumService!,
                builder: (context, _) {
                  final isPro = _premiumService!.isPro;
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: isPro
                        ? AppTheme.cyberGold.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: isPro ? AppTheme.cyberGold : Colors.white24,
                      width: 1,
                    ),
                    avatar: Icon(
                      isPro ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                      color: isPro ? AppTheme.cyberGold : Colors.white70,
                      size: 16,
                    ),
                    label: Text(
                      isPro ? 'PRO' : 'PRO',
                      style: TextStyle(
                        color: isPro ? AppTheme.cyberGold : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: () => PaywallSheet.show(
                      context,
                      premiumService: _premiumService!,
                    ),
                  );
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            tooltip: 'Acerca de Omniverse Labs',
            onPressed: () => AboutDialogWidget.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Historial de Partidas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryScreen(premiumService: _premiumService),
              ),
            ),
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
        ? const Center(child: CircularProgressIndicator(color: AppTheme.cyberGold))
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // Active Match Banner (if any) with Resume & Discard buttons
              if (_activeSession != null) ...[
                _buildActiveMatchCard(theme),
                const SizedBox(height: 14),
              ],

              // 1. Contador Libre Wide Banner Card (16:9 Aspect Ratio)
              _buildWideBannerCard(
                type: GameType.custom,
                imageAsset: 'assets/images/cards/banner_custom.jpg',
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(height: 14),

              // 2. 2-Column Game Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildVerticalGameCard(
                    type: GameType.truco,
                    imageAsset: 'assets/images/cards/card_truco.jpg',
                    color: const Color(0xFF2E7D32),
                  ),
                  _buildVerticalGameCard(
                    type: GameType.generala,
                    imageAsset: 'assets/images/cards/card_generala.jpg',
                    color: const Color(0xFFE65100),
                  ),
                  _buildVerticalGameCard(
                    type: GameType.diezMil,
                    imageAsset: 'assets/images/cards/card_diez_mil.jpg',
                    color: const Color(0xFFF57F17),
                  ),
                  _buildVerticalGameCard(
                    type: GameType.burako,
                    imageAsset: 'assets/images/cards/card_burako.jpg',
                    color: const Color(0xFF7B1FA2),
                  ),
                  _buildVerticalGameCard(
                    type: GameType.escoba,
                    imageAsset: 'assets/images/cards/card_escoba.jpg',
                    color: const Color(0xFF00838F),
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
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.cyberGold, width: 1.5),
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
                    color: AppTheme.cyberGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, size: 14, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'PARTIDA EN CURSO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openGame(session.gameType, existingSession: session),
                icon: const Icon(Icons.play_arrow, color: Colors.black),
                label: const Text('Reanudar Partida', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.cyberGold),
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
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: AppTheme.borderDark,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openGame(type),
        child: AspectRatio(
          aspectRatio: 3.2, // Half the height for sleek horizontal banner
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalGameCard({
    required GameType type,
    required String imageAsset,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppTheme.borderDark,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openGame(type),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
