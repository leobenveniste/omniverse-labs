import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/security_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/trade_provider.dart';
import '../../premium/screens/paywall_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final SecurityProvider securityProvider;
  final TradeProvider tradeProvider;

  const SettingsScreen({
    super.key,
    required this.settingsProvider,
    required this.securityProvider,
    required this.tradeProvider,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _devModeTapCount = 0;
  DateTime? _lastDevTapTime;

  void _handleDevModeTap(BuildContext context) async {
    final now = DateTime.now();
    if (_lastDevTapTime == null || now.difference(_lastDevTapTime!) > const Duration(seconds: 2)) {
      _devModeTapCount = 1;
    } else {
      _devModeTapCount++;
    }
    _lastDevTapTime = now;

    final l10n = AppLocalizations.of(context);
    if (_devModeTapCount >= 7) {
      _devModeTapCount = 0;
      HapticsHelper.heavy();
      await widget.settingsProvider.toggleDevMode();
      if (!context.mounted) return;
      final isNowDev = widget.settingsProvider.isDevMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowDev
                ? l10n.t('devModeActivatedToast')
                : l10n.t('devModeDeactivatedToast'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (_devModeTapCount >= 4) {
      HapticsHelper.light();
      final remaining = 7 - _devModeTapCount;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('devModeRemainingTapsToast', args: {'remaining': remaining}),
          ),
          duration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _showSetPinDialog(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(l10n.t('setPinDialogTitle'), style: AppTypography.title(colors.textPrimary)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: pinController,
            autofocus: true,
            maxLength: 4,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.t('enterPinSubtitle'),
              prefixIcon: const Icon(Icons.pin_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().length != 4 || int.tryParse(v.trim()) == null) {
                return l10n.t('pinLengthValidation');
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('cancelAction'), style: AppTypography.body(colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                HapticsHelper.medium();
                await widget.securityProvider.setupPin(pinController.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.t('pinSuccessToast'))),
                  );
                }
              }
            },
            child: Text(l10n.t('savePinAction'), style: AppTypography.body(colors.onPrimary, isBold: true)),
          ),
        ],
      ),
    );
  }

  void _showBalanceDialog(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final balanceController = TextEditingController(
      text: widget.settingsProvider.accountBalance.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(l10n.t('initialCapitalTitle'), style: AppTypography.title(colors.textPrimary)),
        content: TextFormField(
          controller: balanceController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '${widget.settingsProvider.currencySymbol} ',
            labelText: l10n.t('accountBalanceLabel'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('cancelAction'), style: AppTypography.body(colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            onPressed: () async {
              final val = double.tryParse(balanceController.text.trim());
              if (val != null && val > 0) {
                HapticsHelper.medium();
                await widget.settingsProvider.setAccountBalance(val);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.t('saveAction'), style: AppTypography.body(colors.onPrimary, isBold: true)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colors.outline, width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.privacy_tip_outlined, color: colors.secondary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.t('privacyDialogTitle'),
                style: AppTypography.title(colors.textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              l10n.t('privacyDialogContent'),
              style: AppTypography.body(colors.textSecondary).copyWith(height: 1.45),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: AppTypography.body(Colors.black, isBold: true),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colors.loss.withValues(alpha: 0.5), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: colors.loss.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: colors.loss, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.t('clearDataConfirmTitle'),
                style: AppTypography.title(colors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.t('clearDataConfirmContent'),
          style: AppTypography.body(colors.textSecondary).copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('cancelAction'), style: AppTypography.body(colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.loss,
              foregroundColor: colors.onLoss,
            ),
            onPressed: () async {
              HapticsHelper.heavy();
              await widget.tradeProvider.clearAll();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('clearDataSuccessToast')),
                    backgroundColor: colors.surfaceElevated,
                  ),
                );
              }
            },
            child: Text(
              l10n.t('clearDataAction'),
              style: AppTypography.body(colors.onLoss, isBold: true),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colors.outline, width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline_rounded, color: colors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.t('aboutAppTitle'),
                style: AppTypography.title(colors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: AppTypography.body(colors.textPrimary, isBold: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.t('aboutCompany'),
              style: AppTypography.caption(colors.primary, isMedium: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.t('aboutMission'),
              style: AppTypography.caption(colors.textSecondary).copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.t('packageIdLabel')}: com.omniverselabs.omnitrade',
              style: AppTypography.caption(colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.t('contactSupportTitle')}: ${l10n.t('contactSupportSubtitle')}',
              style: AppTypography.caption(colors.textTertiary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: AppTypography.body(colors.onPrimary, isBold: true),
            ),
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!widget.settingsProvider.isPro) {
      PaywallSheet.show(
        context,
        settingsProvider: widget.settingsProvider,
        customReason: l10n.t('paywallExportNotice'),
      );
      return;
    }

    final trades = widget.tradeProvider.trades;
    final buffer = StringBuffer();
    buffer.writeln('ID,Symbol,AssetClass,Direction,Status,EntryPrice,ExitPrice,Quantity,Multiplier,Fees,StopLoss,TakeProfit,RealizedPnL,EntryDate,ExitDate,Strategy,Emotion,Notes');

    for (final t in trades) {
      buffer.writeln(
        '${t.id},${t.symbol},${t.assetClass},${t.direction.name},${t.status.name},${t.entryPrice},${t.exitPrice ?? ""},${t.quantity},${t.multiplier},${t.fees},${t.stopLoss ?? ""},${t.takeProfit ?? ""},${t.realizedPnl ?? ""},${t.entryDate.toIso8601String()},${t.exitDate?.toIso8601String() ?? ""},"${t.strategyTag ?? ""}","${t.emotionTag ?? ""}","${t.notes ?? ""}"',
      );
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticsHelper.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('exportCsvSuccessToast'))),
    );
  }

  void _backupJson(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!widget.settingsProvider.isPro) {
      PaywallSheet.show(
        context,
        settingsProvider: widget.settingsProvider,
        customReason: l10n.t('paywallExportNotice'),
      );
      return;
    }

    final jsonStr = jsonEncode(widget.tradeProvider.trades.map((t) => t.toMap()).toList());
    Clipboard.setData(ClipboardData(text: jsonStr));
    HapticsHelper.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('backupJsonSuccessToast'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isPro = widget.settingsProvider.isPro;
    final numFormat = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.t('settingsTitle')),
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // PRO Status Banner / Upsell Card
          Container(
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPro
                    ? [colors.secondary.withValues(alpha: 0.15), colors.surface]
                    : [colors.proGold.withValues(alpha: 0.2), colors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isPro ? colors.secondary.withValues(alpha: 0.6) : colors.proGold,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPro
                        ? colors.secondary.withValues(alpha: 0.15)
                        : colors.proGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPro ? Icons.stars_rounded : Icons.lock_open_rounded,
                    color: isPro ? colors.secondary : colors.proGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isPro ? l10n.t('proBannerActiveTitle') : l10n.t('freeBannerTitle'),
                            style: AppTypography.body(colors.textPrimary, isBold: true),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPro ? colors.secondary : colors.proGold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPro ? l10n.t('activeBadge') : l10n.t('free15TradesBadge'),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro
                            ? l10n.t('proSubtitleActive')
                            : l10n.t('proSubtitleFree'),
                        style: AppTypography.caption(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!isPro)
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios_rounded, color: colors.proGold, size: 16),
                    onPressed: () {
                      PaywallSheet.show(context, settingsProvider: widget.settingsProvider);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // --- 🧪 DEVELOPER TESTING / MODO DE PRUEBAS (Dev Mode protected) ---
          if (widget.settingsProvider.isDevMode) ...[
            _buildSectionHeader(l10n.t('testModeSection'), Icons.science_rounded, colors.proGold),
            Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: BorderSide(
                  color: isPro ? colors.proGold.withValues(alpha: 0.6) : colors.outline,
                  width: 1.2,
                ),
              ),
              child: SwitchListTile.adaptive(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPro
                        ? colors.proGold.withValues(alpha: 0.15)
                        : colors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    color: isPro ? colors.proGold : colors.textSecondary,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('testProToggleTitle'),
                        style: AppTypography.body(colors.textPrimary, isBold: true),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPro ? colors.secondary : colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isPro ? colors.secondary : colors.outline),
                      ),
                      child: Text(
                        isPro ? 'PRO' : 'FREE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isPro ? Colors.black : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  l10n.t('testProToggleSubtitle'),
                  style: AppTypography.caption(colors.textSecondary),
                ),
                value: widget.settingsProvider.isTestProOverride,
                activeTrackColor: colors.proGold,
                onChanged: (val) async {
                  HapticsHelper.medium();
                  await widget.settingsProvider.toggleTestPro(val);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // --- GENERAL PREFERENCES ---
          _buildSectionHeader(l10n.t('financialPrefsSection'), Icons.tune_rounded, colors.primary),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: colors.outline, width: 1.0),
            ),
            child: Column(
              children: [
                // Currency Selector
                ListTile(
                  leading: Icon(Icons.currency_exchange_rounded, color: colors.primary),
                  title: Text(l10n.t('baseCurrencyTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
                  subtitle: Text(
                    '${widget.settingsProvider.baseCurrency} (${widget.settingsProvider.currencySymbol})',
                    style: AppTypography.caption(colors.textSecondary),
                  ),
                  trailing: DropdownButton<String>(
                    value: widget.settingsProvider.baseCurrency,
                    dropdownColor: colors.surface,
                    underline: const SizedBox.shrink(),
                    items: AppConstants.supportedCurrencies.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (c) {
                      if (c != null) {
                        HapticsHelper.selection();
                        widget.settingsProvider.setBaseCurrency(c);
                      }
                    },
                  ),
                ),
                const Divider(),
                // Account Balance
                ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined, color: colors.primary),
                  title: Text(l10n.t('initialCapitalTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
                  subtitle: Text(
                    '${widget.settingsProvider.currencySymbol}${numFormat.format(widget.settingsProvider.accountBalance)}',
                    style: AppTypography.caption(colors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsHelper.light();
                    _showBalanceDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // --- LANGUAGE PREFERENCE ---
          _buildSectionHeader(l10n.t('languageTitle'), Icons.language_rounded, colors.primary),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: colors.outline, width: 1.0),
            ),
            child: ListTile(
              leading: Icon(Icons.translate_rounded, color: colors.primary),
              title: Text(l10n.t('languageTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
              subtitle: Text(
                widget.settingsProvider.locale != null
                    ? AppLocalizations.getLanguageName(widget.settingsProvider.locale!.languageCode)
                    : '${l10n.t('systemDefault')} (${AppLocalizations.getLanguageName(Localizations.localeOf(context).languageCode)})',
                style: AppTypography.caption(colors.textSecondary),
              ),
              trailing: DropdownButton<String?>(
                value: widget.settingsProvider.locale?.languageCode,
                dropdownColor: colors.surface,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.t('systemDefault')),
                  ),
                  ...AppLocalizations.supportedLocales.map((loc) {
                    return DropdownMenuItem<String?>(
                      value: loc.languageCode,
                      child: Text(AppLocalizations.getLanguageName(loc.languageCode)),
                    );
                  }),
                ],
                onChanged: (code) {
                  HapticsHelper.selection();
                  widget.settingsProvider.setLocale(code);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // --- SECURITY & PRIVACY ---
          _buildSectionHeader(l10n.t('securitySection'), Icons.shield_rounded, colors.secondary),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: colors.outline, width: 1.0),
            ),
            child: Column(
              children: [
                // PIN Lock Toggle
                SwitchListTile.adaptive(
                  secondary: Icon(
                    Icons.pin_rounded,
                    color: widget.securityProvider.hasPinCode ? colors.secondary : colors.textSecondary,
                  ),
                  title: Text(
                    l10n.t('pinLockTitle'),
                    style: AppTypography.body(colors.textPrimary, isMedium: true),
                  ),
                  subtitle: Text(
                    widget.securityProvider.hasPinCode ? l10n.t('pinLockEnabledSubtitle') : l10n.t('pinLockDisabledSubtitle'),
                    style: AppTypography.caption(colors.textSecondary),
                  ),
                  value: widget.securityProvider.hasPinCode,
                  activeTrackColor: colors.secondary,
                  onChanged: (val) {
                    HapticsHelper.selection();
                    if (val) {
                      _showSetPinDialog(context);
                    } else {
                      widget.securityProvider.removePin();
                    }
                  },
                ),
                if (widget.securityProvider.hasPinCode) ...[
                  const Divider(),
                  // Biometrics Toggle
                  SwitchListTile.adaptive(
                    secondary: Icon(Icons.fingerprint_rounded, color: colors.primary),
                    title: Text(
                      l10n.t('biometricsTitle'),
                      style: AppTypography.body(colors.textPrimary, isMedium: true),
                    ),
                    subtitle: Text(
                      l10n.t('biometricsSubtitle'),
                      style: AppTypography.caption(colors.textSecondary),
                    ),
                    value: widget.securityProvider.isBiometricsEnabled,
                    activeTrackColor: colors.primary,
                    onChanged: (val) async {
                      HapticsHelper.selection();
                      await widget.securityProvider.toggleBiometrics(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.timer_outlined, color: colors.textSecondary),
                    title: Text(l10n.t('autoLockTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
                    subtitle: Text(
                      widget.securityProvider.autoLockTimeoutSeconds == 0
                          ? l10n.t('autoLockImmediate')
                          : (widget.securityProvider.autoLockTimeoutSeconds == 60
                              ? l10n.t('autoLock1Min')
                              : l10n.t('autoLock5Min')),
                      style: AppTypography.caption(colors.textSecondary),
                    ),
                    trailing: DropdownButton<int>(
                      value: widget.securityProvider.autoLockTimeoutSeconds,
                      dropdownColor: colors.surface,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(value: 0, child: Text(l10n.t('autoLockImmediate'))),
                        DropdownMenuItem(value: 60, child: Text(l10n.t('autoLock1Min'))),
                        DropdownMenuItem(value: 300, child: Text(l10n.t('autoLock5Min'))),
                      ],
                      onChanged: (sec) {
                        if (sec != null) {
                          HapticsHelper.selection();
                          widget.securityProvider.setAutoLockTimeout(sec);
                        }
                      },
                    ),
                  ),
                ],
                const Divider(),
                // Privacy Policy Tile
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: colors.secondary),
                  title: Text(l10n.t('privacyPolicyTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
                  subtitle: Text(l10n.t('privacyPolicySubtitle'), style: AppTypography.caption(colors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsHelper.light();
                    _showPrivacyPolicyDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // --- DATA BACKUP & EXPORT ---
          _buildSectionHeader(l10n.t('dataSection'), Icons.cloud_download_rounded, colors.primary),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: colors.outline, width: 1.0),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.table_chart_rounded, color: colors.primary),
                  title: Text(l10n.t('exportCsvTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
                  subtitle: Text(l10n.t('exportCsvSubtitle'), style: AppTypography.caption(colors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _exportCsv(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.data_object_rounded, color: colors.secondary),
                  title: Text(l10n.t('backupJsonTitle'), style: AppTypography.body(colors.textPrimary, isMedium: true)),
                  subtitle: Text(l10n.t('backupJsonSubtitle'), style: AppTypography.caption(colors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _backupJson(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_forever_rounded, color: colors.loss),
                  title: Text(l10n.t('clearAllDataTitle'), style: AppTypography.body(colors.loss, isMedium: true)),
                  subtitle: Text(l10n.t('clearAllDataSubtitle'), style: AppTypography.caption(colors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsHelper.light();
                    _showClearDataDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Omniverse Labs Branding & About
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () {
                _handleDevModeTap(context);
                _showAboutDialog(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 14, color: colors.textTertiary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${AppConstants.appName} v${AppConstants.appVersion}',
                          style: AppTypography.caption(colors.textTertiary, isMedium: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Omniverse Labs Ecosystem',
                      style: AppTypography.caption(colors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: iconColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
