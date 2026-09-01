import 'package:flutter/material.dart';
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

  final List<String> _titles = [
    'Tirador de Dados',
    '¿Quién Empieza?',
    'Temporizador de Turno',
    'Lanzador de Moneda',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
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
        destinations: const [
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
}
