import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/game_session.dart';
import '../models/game_type.dart';
import '../services/premium_service.dart';
import '../services/stats_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paywall_sheet.dart';

class HistoryScreen extends StatefulWidget {
  final PremiumService? premiumService;

  const HistoryScreen({super.key, this.premiumService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PremiumService? _premiumService;
  List<GameSession> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    _premiumService = widget.premiumService ?? await PremiumService.getInstance();
    final list = await StorageService.loadHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deleteSession(String id) async {
    await StorageService.deleteHistoryItem(id);
    _initData();
  }

  void _clearAll() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(l10n.t('clearAll'), style: const TextStyle(color: Colors.white)),
        content: Text(l10n.t('clearHistoryConfirm'), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.t('clearAll')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearHistory();
      _initData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final premium = _premiumService;
    final isPro = premium?.isPro ?? false;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text(l10n.t('historyTitle')),
        actions: [
          if (!isPro && premium != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                backgroundColor: AppTheme.cyberGold.withValues(alpha: 0.15),
                side: const BorderSide(color: AppTheme.cyberGold, width: 1),
                avatar: const Icon(Icons.workspace_premium_rounded, color: AppTheme.cyberGold, size: 16),
                label: Text(
                  l10n.t('proBadge'),
                  style: const TextStyle(
                    color: AppTheme.cyberGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: () => PaywallSheet.show(
                  context,
                  premiumService: premium,
                  customReason: l10n.t('proDefaultSubtitle'),
                ),
              ),
            ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              tooltip: l10n.t('clearAll'),
              onPressed: _clearAll,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cyberGold,
          labelColor: AppTheme.cyberGold,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: const Icon(Icons.history_rounded), text: l10n.t('tabMatches')),
            Tab(icon: const Icon(Icons.emoji_events_rounded), text: l10n.t('tabHallOfFame')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.cyberGold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesTab(theme, isPro),
                _buildLeaderboardTab(theme, isPro),
              ],
            ),
    );
  }

  Widget _buildMatchesTab(ThemeData theme, bool isPro) {
    final l10n = AppLocalizations.of(context);
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 72, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              l10n.t('noMatchesYet'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('noMatchesSub'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Free users can only see top 5 completed sessions
    final displaySessions = isPro ? _history : _history.take(5).toList();
    final hasHiddenSessions = !isPro && _history.length > 5;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasHiddenSessions && _premiumService != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cyberGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock_rounded, color: AppTheme.cyberGold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('showingCountOf', {'count': '5', 'total': _history.length.toString()}),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.t('unlockInfiniteHistory'),
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppTheme.cyberGold),
                  onPressed: () => PaywallSheet.show(
                    context,
                    premiumService: _premiumService!,
                    customReason: l10n.t('unlockInfiniteHistory'),
                  ),
                  child: Text(l10n.t('seeMore'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
        ...displaySessions.map((session) {
          final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(session.dateStarted);

          return Card(
            color: AppTheme.surfaceDark,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderDark),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cyberGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGameIcon(session.gameType),
                  color: AppTheme.cyberGold,
                ),
              ),
              title: Text(
                session.title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (session.winnerName != null && session.winnerName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 16, color: AppTheme.cyberGold),
                        const SizedBox(width: 4),
                        Text(
                          l10n.t('winnerLabel', {'name': session.winnerName!}),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.cyberGold),
                        ),
                      ],
                    ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white54),
                onPressed: () => _deleteSession(session.id),
              ),
            ),
          );
        }),
      ],
    );
  }
  Widget _buildLeaderboardTab(ThemeData theme, bool isPro) {
    final l10n = AppLocalizations.of(context);
    final stats = StatsService.computeStats(_history);

    if (!isPro && _premiumService != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cyberGold.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.cyberGold, width: 2),
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 48, color: AppTheme.cyberGold),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.t('hallOfFameTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('hallOfFameDesc'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Locked Preview Bento Cards
              _buildLockedStatPreview(
                icon: Icons.military_tech_rounded,
                title: l10n.t('podiumPreviewTitle'),
                desc: l10n.t('podiumPreviewDesc'),
              ),
              const SizedBox(height: 10),
              _buildLockedStatPreview(
                icon: Icons.percent_rounded,
                title: l10n.t('winRatePreviewTitle'),
                desc: l10n.t('winRatePreviewDesc'),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyberGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(l10n.t('unlockHallOfFameBtn'), style: const TextStyle(fontWeight: FontWeight.w900)),
                onPressed: () => PaywallSheet.show(
                  context,
                  premiumService: _premiumService!,
                  customReason: l10n.t('hallOfFameDesc'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (stats.leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              l10n.t('noChampionsYet'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('noChampionsSub'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Winner Banner
        if (stats.overallChampion != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.cyberGold.withValues(alpha: 0.25),
                  AppTheme.surfaceElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cyberGold, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.cyberGold, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('kingOfTheTable'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.cyberGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        stats.overallChampion!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l10n.t('winsEffectiveness', {
                          'wins': stats.leaderboard.first.totalWins.toString(),
                          'rate': stats.leaderboard.first.winRate.toString(),
                        }),
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        Text(
          l10n.t('playerRanking'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),

        ...stats.leaderboard.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;

          Color rankColor;
          if (index == 0) {
            rankColor = AppTheme.cyberGold; // Gold
          } else if (index == 1) {
            rankColor = const Color(0xFFC0C0C0); // Silver
          } else if (index == 2) {
            rankColor = const Color(0xFFCD7F32); // Bronze
          } else {
            rankColor = Colors.white38;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor, width: 1),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: rankColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        l10n.t('winsRatioText', {
                          'wins': player.totalWins.toString(),
                          'games': player.totalGamesPlayed.toString(),
                        }),
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cyberGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${player.winRate}%',
                    style: const TextStyle(
                      color: AppTheme.cyberGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLockedStatPreview({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.cyberGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 18),
        ],
      ),
    );
  }

  IconData _getGameIcon(GameType type) {
    switch (type) {
      case GameType.truco:
        return Icons.style;
      case GameType.generala:
      case GameType.diezMil:
        return Icons.casino;
      case GameType.burako:
        return Icons.grid_view;
      case GameType.escoba:
        return Icons.cleaning_services;
      case GameType.custom:
        return Icons.calculate;
    }
  }
}

