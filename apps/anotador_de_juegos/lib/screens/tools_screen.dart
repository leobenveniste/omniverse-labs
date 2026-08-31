import 'package:flutter/material.dart';
import '../widgets/dice_roller_widget.dart';
import '../widgets/finger_roulette_widget.dart';
import '../widgets/coin_flipper_widget.dart';
import '../widgets/turn_timer_widget.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caja de Herramientas'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(icon: Icon(Icons.casino), text: 'Dados'),
              Tab(icon: Icon(Icons.touch_app), text: 'Quién Empieza'),
              Tab(icon: Icon(Icons.timer), text: 'Temporizador'),
              Tab(icon: Icon(Icons.monetization_on), text: 'Moneda'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(), // Disable swiping on touch roulette tab
          children: [
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: CoinFlipperWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
