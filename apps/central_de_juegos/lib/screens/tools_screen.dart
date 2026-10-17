import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/dice_roller_widget.dart';
import '../widgets/finger_roulette_widget.dart';
import '../widgets/coin_flipper_widget.dart';
import '../widgets/turn_timer_widget.dart';

class ToolsScreen extends StatefulWidget {
  final int initialTab;

  const ToolsScreen({super.key, this.initialTab = 0});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.t('toolDiceRoller'),
      l10n.t('toolFingerRoulette'),
      l10n.t('toolTurnTimer'),
      l10n.t('toolCoinFlipper'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: DiceRollerWidget(),
            ),
          ),
          FingerRouletteWidget(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: TurnTimerWidget(),
            ),
          ),
          Center(
            child: CoinFlipperWidget(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.casino_outlined),
            selectedIcon: const Icon(Icons.casino),
            label: l10n.t('toolTabDice'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.touch_app_outlined),
            selectedIcon: const Icon(Icons.touch_app),
            label: l10n.t('toolTabRoulette'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer),
            label: l10n.t('toolTabTimer'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.monetization_on_outlined),
            selectedIcon: const Icon(Icons.monetization_on),
            label: l10n.t('toolTabCoin'),
          ),
        ],
      ),
    );
  }
}
