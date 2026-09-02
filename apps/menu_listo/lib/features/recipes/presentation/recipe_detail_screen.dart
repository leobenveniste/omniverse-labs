import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import '../../meal_planner/providers/meal_planner_provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import 'recipe_cook_mode_screen.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int? _currentServings;

  // Floating Interactive Step Timer
  Timer? _activeTimer;
  int _timerSecondsRemaining = 0;
  int _timerInitialSeconds = 0;
  String _timerLabel = '';
  bool _isTimerRunning = false;

  @override
  void dispose() {
    _activeTimer?.cancel();
    super.dispose();
  }

  void _startStepTimer(String label, int seconds) {
    _activeTimer?.cancel();
    setState(() {
      _timerLabel = label;
      _timerInitialSeconds = seconds;
      _timerSecondsRemaining = seconds;
      _isTimerRunning = true;
    });

    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsRemaining > 1) {
        setState(() => _timerSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _timerSecondsRemaining = 0;
          _isTimerRunning = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.deepOrange,
              content: Row(
                children: [
                  const Icon(Icons.alarm_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('⏰ ¡Tiempo cumplido para $_timerLabel!'),
                ],
              ),
            ),
          );
        }
      }
    });
  }

  void _toggleActiveTimer() {
    if (_isTimerRunning) {
      _activeTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (_timerSecondsRemaining <= 0) return;
      setState(() => _isTimerRunning = true);
      _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerSecondsRemaining > 1) {
          setState(() => _timerSecondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _timerSecondsRemaining = 0;
            _isTimerRunning = false;
          });
        }
      });
    }
  }

  void _resetActiveTimer() {
    _activeTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSecondsRemaining = _timerInitialSeconds;
    });
  }

  void _addMinuteToActiveTimer() {
    setState(() {
      _timerSecondsRemaining += 60;
      _timerInitialSeconds += 60;
    });
  }

  void _closeActiveTimer() {
    _activeTimer?.cancel();
    setState(() {
      _timerInitialSeconds = 0;
      _timerSecondsRemaining = 0;
      _isTimerRunning = false;
    });
  }

  int _detectSeconds(String text) {
    final minMatch = RegExp(r'(\d+)\s*(?:minutos?|mins?|min)\b', caseSensitive: false).firstMatch(text);
    final hourMatch = RegExp(r'(\d+)\s*(?:horas?|hrs?|hs?|h)\b', caseSensitive: false).firstMatch(text);
    final secMatch = RegExp(r'(\d+)\s*(?:segundos?|segs?|seg)\b', caseSensitive: false).firstMatch(text);

    int total = 0;
    if (minMatch != null) total += (int.tryParse(minMatch.group(1)!) ?? 0) * 60;
    if (hourMatch != null) total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 3600;
    if (secMatch != null) total += (int.tryParse(secMatch.group(1)!) ?? 0);
    return total;
  }

  String _formatTimerDisplay(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatTimerChip(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    if (minutes > 0) return '$minutes min';
    return '$totalSeconds seg';
  }

  void _showScheduleSheet(BuildContext context, Recipe recipe, int servings) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final weekStart = ref.read(currentWeekStartProvider);

    final days = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('EEEE', strings.isSpanish ? 'es' : 'en').format(date);
      final capDayName = dayName[0].toUpperCase() + dayName.substring(1);
      return {'dateStr': dateStr, 'label': '$capDayName (${DateFormat('d MMM', strings.isSpanish ? 'es' : 'en').format(date)})'};
    });

    String selectedDateStr = days[0]['dateStr']!;
    String selectedSlot = 'lunch';
    if (recipe.category.toLowerCase().contains('desayuno')) selectedSlot = 'breakfast';
    if (recipe.category.toLowerCase().contains('merienda')) selectedSlot = 'snack';
    if (recipe.category.toLowerCase().contains('cena')) selectedSlot = 'dinner';
    int scheduleServings = servings;
    bool batchCookForTomorrow = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        strings.isSpanish ? 'Planificar en la Agenda' : 'Schedule in Meal Planner',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.title,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),

                  // Day Dropdown
                  Text(
                    strings.isSpanish ? 'Día de la semana' : 'Day of the week',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDateStr,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: days.map((d) => DropdownMenuItem(value: d['dateStr'], child: Text(d['label']!))).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedDateStr = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Meal Slot Dropdown
                  Text(
                    strings.isSpanish ? 'Momento del día' : 'Meal Slot',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSlot,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: [
                      DropdownMenuItem(value: 'breakfast', child: Text(strings.mealBreakfast)),
                      DropdownMenuItem(value: 'lunch', child: Text(strings.mealLunch)),
                      DropdownMenuItem(value: 'snack', child: Text(strings.mealSnack)),
                      DropdownMenuItem(value: 'dinner', child: Text(strings.mealDinner)),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedSlot = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Servings Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.servings,
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove),
                            onPressed: scheduleServings > 1 ? () => setSheetState(() => scheduleServings--) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              '$scheduleServings',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () => setSheetState(() => scheduleServings++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Batch cook / Tupper toggle
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      strings.isSpanish ? '🍱 Cocinar doble y guardar tupper para mañana' : '🍱 Batch cook double for leftovers',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    value: batchCookForTomorrow,
                    onChanged: (val) => setSheetState(() => batchCookForTomorrow = val ?? false),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(strings.assignButton),
                      onPressed: () {
                        final plannerNotifier = ref.read(weeklyMealPlanProvider.notifier);
                        plannerNotifier.assignMeal(
                          dateString: selectedDateStr,
                          mealType: selectedSlot,
                          recipeId: recipe.id,
                          recipeTitle: recipe.title,
                          recipeCategory: recipe.category,
                          servings: scheduleServings,
                        );

                        if (batchCookForTomorrow) {
                          // Auto assign next day lunch
                          final parsedDate = DateTime.parse(selectedDateStr);
                          final nextDateStr = DateFormat('yyyy-MM-dd').format(parsedDate.add(const Duration(days: 1)));
                          plannerNotifier.assignMeal(
                            dateString: nextDateStr,
                            mealType: 'lunch',
                            recipeId: recipe.id,
                            recipeTitle: recipe.title,
                            recipeCategory: recipe.category,
                            servings: scheduleServings,
                            customNote: 'sobras',
                          );
                        }

                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.isSpanish
                                  ? '¡Receta agendada con éxito!'
                                  : 'Recipe scheduled successfully!',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final recipeAsync = ref.watch(recipesListProvider);

    return recipeAsync.when(
      data: (recipes) {
        final recipe = recipes.cast<Recipe?>().firstWhere(
              (r) => r?.id == widget.recipeId,
              orElse: () => null,
            );

        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(strings.emptyTitle)),
          );
        }

        final servings = _currentServings ?? recipe.baseServings;
        final scalingFactor = servings / (recipe.baseServings > 0 ? recipe.baseServings : 2);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Sliver App Bar with Hero Image & contrast scrim
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    child: const BackButton(color: Colors.white),
                  ),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final statusBarHeight = MediaQuery.of(context).padding.top;
                    final isCollapsed = top <= kToolbarHeight + statusBarHeight + 25;

                    return FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(
                        start: 56,
                        end: 145,
                        bottom: 15,
                      ),
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCollapsed ? 1.0 : 0.0,
                        child: Text(
                          recipe.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      background: _buildHeaderImage(recipe, theme),
                    );
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.event_available, color: Colors.white),
                        tooltip: strings.isSpanish ? 'Planificar en la Agenda' : 'Schedule in Planner',
                        onPressed: () => _showScheduleSheet(context, recipe, servings),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () {
                          ref.read(recipesListProvider.notifier).toggleFavorite(recipe.id, recipe.isFavorite);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => RecipeFormScreen(initialRecipe: recipe),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () => _confirmDelete(context, recipe),
                      ),
                    ),
                  ),
                ],
              ),
              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category and Time Badges
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: recipe.categories.map((cat) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.totalTimeMinutes} ${strings.minutes}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Title
                      Text(
                        recipe.title,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (recipe.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          recipe.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Dynamic Portion Scaler Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton.filledTonal(
                              icon: const Icon(Icons.remove_rounded, size: 22),
                              onPressed: servings > 1
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _currentServings = servings - 1);
                                    }
                                  : null,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                  child: Text(
                                    '$servings',
                                    key: ValueKey<int>(servings),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  servings == 1
                                      ? (strings.isSpanish ? 'porción' : 'serving')
                                      : (strings.isSpanish ? 'porciones' : 'servings'),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filled(
                              icon: const Icon(Icons.add_rounded, size: 22),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _currentServings = servings + 1);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Ingredients List Header
                      Text(
                        strings.ingredientsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      // Ingredients List without dividers
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipe.ingredients.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ing = recipe.ingredients[index];

                          if (ing.isSectionHeader) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.bookmark_rounded, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    ing.name.endsWith(':') ? ing.name : '${ing.name}:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final scaledIng = ing.scale(scalingFactor);
                          final emoji = CulinaryCatalog.getEmoji(ing.name);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    scaledIng.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    PortionCalculator.formatIngredientAmount(scaledIng.amount, scaledIng.unit),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      // Step by Step Instructions
                      Text(
                        strings.instructionsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recipe.steps.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final step = recipe.steps[index];

                          if (step.isSectionHeader) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 14.0, bottom: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.bookmark_rounded, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    step.instruction.endsWith(':') ? step.instruction : '${step.instruction}:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final durationSec = _detectSeconds(step.instruction);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${step.stepNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.instruction,
                                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                                    ),
                                    if (durationSec > 0) ...[
                                      const SizedBox(height: 6),
                                      ActionChip(
                                        avatar: const Icon(Icons.timer_outlined, size: 14),
                                        label: Text(
                                          '⏱️ ${_formatTimerChip(durationSec)} (Tocar para iniciar)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                        onPressed: () => _startStepTimer('Paso ${step.stepNumber}', durationSec),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Active Timer Banner (if active)
                  if (_timerInitialSeconds > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: theme.colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          Icon(
                            _isTimerRunning ? Icons.timer : Icons.timer_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _timerLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                _formatTimerDisplay(_timerSecondsRemaining),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _timerSecondsRemaining == 0
                                      ? Colors.red
                                      : theme.colorScheme.onPrimaryContainer,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 20),
                            onPressed: _toggleActiveTimer,
                          ),
                          const SizedBox(width: 4),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.more_time, size: 20),
                            tooltip: '+1 min',
                            onPressed: _addMinuteToActiveTimer,
                          ),
                          const SizedBox(width: 4),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Reiniciar',
                            onPressed: _resetActiveTimer,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _closeActiveTimer,
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => RecipeCookModeScreen(
                                recipe: recipe,
                                initialServings: servings,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.outdoor_grill),
                        label: Text(
                          strings.startCooking,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(body: Center(child: Text(strings.emptyTitle))),
    );
  }

  Widget _buildHeaderImage(Recipe recipe, ThemeData theme) {
    Widget imageWidget;
    if (recipe.imageUrl.isNotEmpty) {
      if (recipe.imageUrl.startsWith('http')) {
        imageWidget = Hero(
          tag: 'recipe_image_${recipe.id}',
          child: Image.network(recipe.imageUrl, cacheWidth: 1080, fit: BoxFit.cover),
        );
      } else {
        final file = File(recipe.imageUrl);
        if (file.existsSync()) {
          imageWidget = Hero(
            tag: 'recipe_image_${recipe.id}',
            child: Image.file(file, cacheWidth: 1080, fit: BoxFit.cover),
          );
        } else {
          imageWidget = Container(
            color: theme.colorScheme.primaryContainer,
            child: Center(
              child: Icon(Icons.restaurant_menu, size: 72, color: theme.colorScheme.primary),
            ),
          );
        }
      }
    } else {
      imageWidget = Container(
        color: theme.colorScheme.primaryContainer,
        child: Center(
          child: Icon(Icons.restaurant_menu, size: 72, color: theme.colorScheme.primary),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        // Status bar & AppBar button contrast protection scrim
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Recipe recipe) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.confirmDeleteRecipe),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(recipesListProvider.notifier).deleteRecipe(recipe.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }
}
