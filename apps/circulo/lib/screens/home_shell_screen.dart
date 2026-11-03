import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/online_firestore_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'discover/discover_screen.dart';
import 'circles/forming_circles_screen.dart';
import 'groups/my_groups_screen.dart';
import 'profile/profile_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    FormingCirclesScreen(),
    MyGroupsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final firestore = context.watch<OnlineFirestoreService>();
    final user = auth.currentUser;

    // Calcular cuántos círculos en formación casi completos (3/4) tiene el usuario
    int almostFullCount = 0;
    if (user != null) {
      almostFullCount = firestore.currentGroups
          .where((g) =>
              g.isForming &&
              g.memberIds.length == 3 &&
              g.memberIds.contains(user.id))
          .length;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: l10n.get('navDiscover'),
          ),
          NavigationDestination(
            icon: almostFullCount > 0
                ? Badge(
                    label: Text('$almostFullCount'),
                    backgroundColor: AppTheme.vibrantCoral,
                    child: const Icon(Icons.hourglass_empty_rounded),
                  )
                : const Icon(Icons.hourglass_empty_rounded),
            selectedIcon: almostFullCount > 0
                ? Badge(
                    label: Text('$almostFullCount'),
                    backgroundColor: AppTheme.vibrantCoral,
                    child: const Icon(Icons.hourglass_full_rounded),
                  )
                : const Icon(Icons.hourglass_full_rounded),
            label: l10n.get('navForming'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: l10n.get('navMyCircles'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.get('navProfile'),
          ),
        ],
      ),
    );
  }
}
