import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/recipe_scraper.dart';
import '../../models/recipe_model.dart';
import '../recipe_form_screen.dart';

import 'recipe_import_social_dialog.dart';

class RecipeImportUrlDialog extends StatefulWidget {
  const RecipeImportUrlDialog({super.key});

  static Future<Recipe?> show(BuildContext context) {
    return showDialog<Recipe>(
      context: context,
      builder: (ctx) => const RecipeImportUrlDialog(),
    );
  }

  @override
  State<RecipeImportUrlDialog> createState() => _RecipeImportUrlDialogState();
}

class _RecipeImportUrlDialogState extends State<RecipeImportUrlDialog> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isSocialUrl {
    final lower = _urlController.text.toLowerCase();
    return lower.contains('instagram.com') || lower.contains('tiktok.com');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (_isSocialUrl) {
      Navigator.of(context).pop();
      RecipeImportSocialDialog.show(context, initialText: url);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final recipe = await RecipeScraper.scrapeUrl(url);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (recipe != null && recipe.title.isNotEmpty) {
      Navigator.of(context).pop();
      // Navigate to form to preview and save
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => RecipeFormScreen(initialRecipe: recipe),
        ),
      );
    } else {
      final strings = AppStrings.of(context);
      setState(() {
        _errorMessage = strings.scrapingFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.link, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    strings.importUrlTitle,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              strings.importUrlSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: InputDecoration(
                hintText: strings.urlInputHint,
                prefixIcon: const Icon(Icons.language),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _urlController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_isSocialUrl) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1306C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE1306C).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFE1306C),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.socialUrlRedirectNotice,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          final currentUrl = _urlController.text.trim();
                          Navigator.of(context).pop();
                          RecipeImportSocialDialog.show(context, initialText: currentUrl);
                        },
                        icon: const Icon(Icons.post_add_rounded, size: 16),
                        label: Text(strings.switchToSocialPaste),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(strings.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isLoading || _urlController.text.trim().isEmpty ? null : _extract,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? strings.importingProgress : strings.importButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
