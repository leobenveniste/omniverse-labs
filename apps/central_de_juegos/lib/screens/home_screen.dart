import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/game_type.dart';
import '../models/game_session.dart';
import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_title.dart';
import '../widgets/dice_roller_widget.dart';
import '../widgets/finger_roulette_widget.dart';
import '../widgets/first_use_guide_card.dart';
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
import 'settings_screen.dart';

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
  bool _showGamesGuide = false;
  bool _showDiceGuide = false;
  bool _showRouletteGuide = false;
  bool _showTimerGuide = false;
  bool _showCoinGuide = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadGuidesState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyPromo();
    });
  }

  Future<void> _loadGuidesState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showGamesGuide = !(prefs.getBool('has_seen_guide_games') ?? false);
        _showDiceGuide = !(prefs.getBool('has_seen_guide_dice') ?? false);
        _showRouletteGuide = !(prefs.getBool('has_seen_guide_roulette') ?? false);
        _showTimerGuide = !(prefs.getBool('has_seen_guide_timer') ?? false);
        _showCoinGuide = !(prefs.getBool('has_seen_guide_coin') ?? false);
      });
    }
  }

  Future<void> _dismissGuide(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    if (mounted) {
      setState(() {
        if (key == 'has_seen_guide_games') _showGamesGuide = false;
        if (key == 'has_seen_guide_dice') _showDiceGuide = false;
        if (key == 'has_seen_guide_roulette') _showRouletteGuide = false;
        if (key == 'has_seen_guide_timer') _showTimerGuide = false;
        if (key == 'has_seen_guide_coin') _showCoinGuide = false;
      });
    }
  }

  Future<void> _checkDailyPromo() async {
    try {
      final premium = await PremiumService.getInstance();
      if (premium.isPro) return;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastTimestamp = prefs.getInt('last_pro_promo_timestamp');
      const fourDaysMs = 4 * 24 * 60 * 60 * 1000;

      if (lastTimestamp == null || (now - lastTimestamp) >= fourDaysMs) {
        await prefs.setInt('last_pro_promo_timestamp', now);
        if (mounted) {
          PaywallSheet.show(
            context,
            premiumService: premium,
          );
        }
      }
    } catch (_) {}
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
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(l10n.t('discardMatchTitle'), style: const TextStyle(color: Colors.white)),
        content: Text(l10n.t('discardMatchConfirm'), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.t('discardMatch')),
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
    final l10n = AppLocalizations.of(context);

    final List<String> navTitles = [
      l10n.t('navDice'),
      l10n.t('navWhoStarts'),
      l10n.t('navGames'),
      l10n.t('navTimer'),
      l10n.t('navCoin'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        centerTitle: false,
        titleSpacing: 16,
        title: AppHeaderTitle(
          title: navTitles[_currentNavIndex],
          isPro: _premiumService?.isPro ?? false,
        ),
        actions: [
          if (!(_premiumService?.isPro ?? false))
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'Central de Juegos PRO',
              onPressed: () {
                if (_premiumService != null) {
                  PaywallSheet.show(context, premiumService: _premiumService!);
                }
              },
            ),
          // Header Add / Quick Custom Match button
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.cyberGold),
            tooltip: l10n.t('gameSetupTitle'),
            onPressed: () => _openGame(GameType.custom),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: l10n.t('historyTitle'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryScreen(premiumService: _premiumService),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: l10n.t('settingsTitle'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(premiumService: _premiumService),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // 0: Dados
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showDiceGuide)
                    FirstUseGuideCard(
                      icon: Icons.casino_rounded,
                      title: l10n.locale.languageCode == 'es' ? 'Tirador de Dados' : 'Dice Roller',
                      description: l10n.locale.languageCode == 'es'
                          ? 'Tira hasta 6 dados con físicas y sonidos realistas para cualquier juego de mesa.'
                          : 'Roll up to 6 dice with realistic physics and sound effects for any tabletop game.',
                      bulletPoints: l10n.locale.languageCode == 'es'
                          ? [
                              'Toca o agita la pantalla para lanzar los dados.',
                              'Ajusta la cantidad de dados (1 a 6) según las reglas de tu juego.',
                              'La suma total se calcula y anuncia al instante.',
                            ]
                          : [
                              'Tap or shake the screen to roll the dice.',
                              'Adjust the number of dice (1 to 6) depending on game rules.',
                              'Total sum is automatically calculated on each roll.',
                            ],
                      onDismiss: () => _dismissGuide('has_seen_guide_dice'),
                    ),
                  const DiceRollerWidget(),
                ],
              ),
            ),
          ),
          // 1: Quién Empieza
          Column(
            children: [
              if (_showRouletteGuide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: FirstUseGuideCard(
                    icon: Icons.touch_app_rounded,
                    title: l10n.locale.languageCode == 'es' ? 'Ruleta de Dedos' : 'Finger Roulette',
                    description: l10n.locale.languageCode == 'es'
                        ? 'Decide quién empieza o quién paga la ronda en 3 segundos.'
                        : 'Decide who starts first or who pays the round in seconds.',
                    bulletPoints: l10n.locale.languageCode == 'es'
                        ? [
                            'Cada jugador apoya un dedo en la pantalla y lo mantiene.',
                            'El sensor detecta los contactos y comenzará una cuenta regresiva.',
                            'Un haz de neón elegirá al afortunado al azar con vibración táctil.',
                          ]
                        : [
                            'Each player holds a finger on the screen simultaneously.',
                            'Sensors will detect each touch and trigger a countdown.',
                            'A neon pulse randomly selects the chosen player with haptics.',
                          ],
                    onDismiss: () => _dismissGuide('has_seen_guide_roulette'),
                  ),
                ),
              const Expanded(child: FingerRouletteWidget()),
            ],
          ),
          // 2: Juegos (Home)
          _buildGamesCatalogTab(theme),
          // 3: Temporizador
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showTimerGuide)
                    FirstUseGuideCard(
                      icon: Icons.timer_rounded,
                      title: l10n.locale.languageCode == 'es' ? 'Reloj de Turno y Blitz' : 'Turn & Blitz Timer',
                      description: l10n.locale.languageCode == 'es'
                          ? 'Controla el tiempo por turno en juegos rápidos para que nadie se duerma.'
                          : 'Keep everyone moving with an audio-visual countdown for turn-based games.',
                      bulletPoints: l10n.locale.languageCode == 'es'
                          ? [
                              'Elige presets rápidos (30s, 60s, 2m) o configura tu propio límite.',
                              'Alertas sonoras y visuales cuando resten 5 segundos.',
                              'Toca para pausar o reiniciar con un solo toque.',
                            ]
                          : [
                              'Choose quick presets (30s, 60s, 2m) or set a custom time.',
                              'Audio-visual alerts trigger when 5 seconds remain.',
                              'Tap to pause or restart with a single gesture.',
                            ],
                      onDismiss: () => _dismissGuide('has_seen_guide_timer'),
                    ),
                  const TurnTimerWidget(),
                ],
              ),
            ),
          ),
          // 4: Moneda
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showCoinGuide)
                    FirstUseGuideCard(
                      icon: Icons.monetization_on_rounded,
                      title: l10n.locale.languageCode == 'es' ? 'Cara o Cruz Consular' : 'Heads or Tails Coin',
                      description: l10n.locale.languageCode == 'es'
                          ? 'Resuelve empates y decisiones con un giro equilibrado de moneda.'
                          : 'Resolve ties and fair choices with a balanced coin flip.',
                      bulletPoints: l10n.locale.languageCode == 'es'
                          ? [
                              'Toca la moneda para lanzarla al aire.',
                              'Físicas realistas con rotación sobre múltiples ejes.',
                              'Resultado instantáneo con retroalimentación háptica.',
                            ]
                          : [
                              'Tap the coin to flip it high into the air.',
                              'Realistic physics with multi-axis rotation.',
                              'Instant result feedback with tactile haptics.',
                            ],
                      onDismiss: () => _dismissGuide('has_seen_guide_coin'),
                    ),
                  const CoinFlipperWidget(),
                ],
              ),
            ),
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
    final l10n = AppLocalizations.of(context);
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.cyberGold))
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              if (_showGamesGuide)
                FirstUseGuideCard(
                  icon: Icons.sports_esports_rounded,
                  title: l10n.locale.languageCode == 'es' ? 'Anotador de Juegos' : 'Game Scorekeeper',
                  description: l10n.locale.languageCode == 'es'
                      ? 'Lleva el puntaje de Truco, Generala, 10.000, Burako, Escoba o cualquier juego personalizado.'
                      : 'Track scores for Truco, Generala, 10,000, Burako, Escoba or custom games.',
                  bulletPoints: l10n.locale.languageCode == 'es'
                      ? [
                          'Toca (+) arriba o en Contador Libre para iniciar una partida multijugador.',
                          'Elige un juego del catálogo para usar planillas con reglas y cálculos automáticos.',
                          'Tus partidas se guardan solas y puedes retomarlas cuando quieras.',
                        ]
                      : [
                          'Tap (+) on top or Custom Match to launch a multiplayer scoreboard.',
                          'Select any catalog game for tailored rule sheets and automatic calculations.',
                          'Matches are autosaved so you can resume them at any time.',
                        ],
                  onDismiss: () => _dismissGuide('has_seen_guide_games'),
                ),
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
    final l10n = AppLocalizations.of(context);

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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        l10n.t('activeMatch'),
                        style: const TextStyle(
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
                  tooltip: l10n.t('discardMatch'),
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
                label: Text(
                  l10n.t('resumeMatch'),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                ),
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
