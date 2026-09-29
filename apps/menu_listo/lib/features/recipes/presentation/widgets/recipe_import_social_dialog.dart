import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/social_recipe_parser.dart';
import '../recipe_form_screen.dart';

class RecipeImportSocialDialog extends StatefulWidget {
  final String? initialText;

  const RecipeImportSocialDialog({
    super.key,
    this.initialText,
  });

  static Future<void> show(BuildContext context, {String? initialText}) {
    return showDialog(
      context: context,
      builder: (ctx) => RecipeImportSocialDialog(initialText: initialText),
    );
  }

  @override
  State<RecipeImportSocialDialog> createState() => _RecipeImportSocialDialogState();
}

class _RecipeImportSocialDialogState extends State<RecipeImportSocialDialog> {
  late final TextEditingController _textController;
  int _detectedIngredientsCount = 0;
  int _detectedStepsCount = 0;
  String _detectedTitle = '';
  bool _showHelpGuide = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _textController.addListener(_onTextChanged);
    if (_textController.text.isNotEmpty) {
      _analyzeText(_textController.text);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _analyzeText(_textController.text);
  }

  void _analyzeText(String text) {
    if (text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _detectedIngredientsCount = 0;
          _detectedStepsCount = 0;
          _detectedTitle = '';
        });
      }
      return;
    }

    final parsed = SocialRecipeParser.parsePostText(text);
    if (mounted) {
      setState(() {
        _detectedIngredientsCount = parsed.ingredients.length;
        _detectedStepsCount = parsed.steps.length;
        _detectedTitle = parsed.title;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text ?? '';
    if (text.trim().isNotEmpty) {
      _textController.text = text;
      _textController.selection = TextSelection.collapsed(offset: text.length);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El portapapeles está vacío o no contiene texto.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _createRecipe() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    final recipe = SocialRecipeParser.parsePostText(text);

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeFormScreen(initialRecipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final hasText = _textController.text.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with social icon and title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE1306C), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.post_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.socialImportTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Instagram, TikTok, Facebook',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showHelpGuide ? Icons.help_rounded : Icons.help_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    tooltip: strings.socialHowToTitle,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showHelpGuide = !_showHelpGuide);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // How-to guide banner (expandable)
              if (_showHelpGuide) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.socialHowToTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.socialHowToStep1,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.socialHowToStep2,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.socialHowToOcrTip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Subtitle & Paste action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      strings.socialImportSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                    label: Text(
                      strings.pasteFromClipboard,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Multi-line Text Area
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: strings.socialInputHint,
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Live Detection Badge
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasText ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasText
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasText ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
                        size: 16,
                        color: hasText ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasText
                              ? '$_detectedIngredientsCount ${strings.ingredientsDetected} • $_detectedStepsCount ${strings.stepsDetected}'
                              : 'Pega el texto para previsualizar los ingredientes y pasos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: hasText ? FontWeight.w600 : FontWeight.normal,
                            color: hasText ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasText && _detectedTitle.isNotEmpty)
                        Text(
                          _detectedTitle.length > 20
                              ? '${_detectedTitle.substring(0, 20)}...'
                              : _detectedTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: hasText ? _createRecipe : null,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(strings.convertRecipe),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
