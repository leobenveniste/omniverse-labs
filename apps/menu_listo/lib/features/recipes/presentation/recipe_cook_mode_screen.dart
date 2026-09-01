import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import '../models/recipe_model.dart';

class RecipeCookModeScreen extends StatefulWidget {
  final Recipe recipe;
  final int initialServings;

  const RecipeCookModeScreen({
    super.key,
    required this.recipe,
    required this.initialServings,
  });

  @override
  State<RecipeCookModeScreen> createState() => _RecipeCookModeScreenState();
}

class _RecipeCookModeScreenState extends State<RecipeCookModeScreen> {
  late int _servings;
  int _currentStepIndex = 0;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _servings = widget.initialServings;
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final steps = widget.recipe.steps;
    final totalSteps = steps.length;
    final currentStep = steps.isNotEmpty && _currentStepIndex < totalSteps ? steps[_currentStepIndex] : null;
    final scalingFactor = _servings / (widget.recipe.baseServings > 0 ? widget.recipe.baseServings : 2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.cookModeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(Icons.lock_clock, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(strings.cookModeWakeLockNotice, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: strings.ingredientsTitle,
            onPressed: () => _showIngredientsSheet(context, scalingFactor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: totalSteps > 0 ? (_completedSteps.length / totalSteps) : 0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (currentStep != null) ...[
                      // Step Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${strings.step} ${_currentStepIndex + 1} ${strings.ofSteps} $totalSteps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Big Step Instruction Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Text(
                                currentStep.instruction,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Checkbox to mark done
                              CheckboxListTile(
                                value: _completedSteps.contains(_currentStepIndex),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _completedSteps.add(_currentStepIndex);
                                    } else {
                                      _completedSteps.remove(_currentStepIndex);
                                    }
                                  });
                                },
                                title: Text(
                                  'Paso completado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _completedSteps.contains(_currentStepIndex)
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Navigation Controls (Large Kitchen Touch Target Buttons)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: _currentStepIndex > 0
                          ? () => setState(() => _currentStepIndex--)
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(strings.previousStep),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: () {
                        setState(() {
                          _completedSteps.add(_currentStepIndex);
                          if (_currentStepIndex < totalSteps - 1) {
                            _currentStepIndex++;
                          } else {
                            _showFinishedDialog(context);
                          }
                        });
                      },
                      icon: Icon(_currentStepIndex == totalSteps - 1 ? Icons.check_circle : Icons.arrow_forward),
                      label: Text(_currentStepIndex == totalSteps - 1 ? strings.finishCooking : strings.nextStep),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIngredientsSheet(BuildContext context, double factor) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${strings.ingredientsTitle} ($_servings ${strings.persons})',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: widget.recipe.ingredients.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final ing = widget.recipe.ingredients[index].scale(factor);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
                      title: Text(
                        PortionCalculator.formatIngredientDisplay(
                          amount: ing.amount,
                          unit: ing.unit,
                          name: ing.name,
                          notes: ing.notes,
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinishedDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Text(strings.finishCooking),
          ],
        ),
        content: Text(strings.finishCookingMessage),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }
}
