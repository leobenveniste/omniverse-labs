import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';

class DuoModeSheet extends StatefulWidget {
  const DuoModeSheet({super.key});

  @override
  State<DuoModeSheet> createState() => _DuoModeSheetState();
}

class _DuoModeSheetState extends State<DuoModeSheet> {
  final _partnerCodeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _partnerCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLinkDuo() async {
    final code = _partnerCodeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final ok = await auth.linkDuoPartner(code);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('duoLinkedSuccess')),
            backgroundColor: AppTheme.emeraldMint,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Código inválido.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleUnlinkDuo() async {
    final auth = context.read<AuthService>();
    await auth.unlinkDuoPartner();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    final hasDuo = user?.hasDuoPartner ?? false;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('duoModeTitle'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.get('duoModeSubtitle'),
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 20),

          if (hasDuo) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.emeraldMint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.emeraldMint),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded,
                      color: AppTheme.emeraldMint, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.format('duoModeActive', {'name': 'tu partner'}),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LoadingOutlinedButton(
              label: l10n.get('duoUnlinkBtn'),
              color: AppTheme.errorRed,
              onPressed: _handleUnlinkDuo,
            ),
          ] else ...[
            // Código Propio
            Text(
              l10n.get('duoMyCode'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    user?.duoInviteCode ?? 'CIR-XXXX',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: primary,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.get('duoCopyCode'),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: user?.duoInviteCode ?? ''));
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.get('duoCodeCopied')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ingresar código de amigo
            Text(
              l10n.get('duoEnterPartnerCode'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _partnerCodeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ej: CIR-LEO1',
                prefixIcon: Icon(Icons.key_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            LoadingPrimaryButton(
              label: l10n.get('duoLinkBtn'),
              isLoading: _isLoading,
              onPressed: _handleLinkDuo,
            ),
          ],
        ],
      ),
    );
  }
}
