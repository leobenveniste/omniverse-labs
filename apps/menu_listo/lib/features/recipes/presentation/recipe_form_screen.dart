import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/core/utils/culinary_catalog.dart';
import 'package:menu_listo/core/utils/ingredient_parser.dart';
import 'package:menu_listo/core/utils/portion_calculator.dart';
import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';
import '../models/recipe_step_model.dart';
import '../providers/recipe_provider.dart';

class RecipeFormScreen extends ConsumerStatefulWidget {
  final Recipe? initialRecipe;

  const RecipeFormScreen({super.key, this.initialRecipe});

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;
  late TextEditingController _ingredientsTextController;
  late TextEditingController _stepsTextController;
  late String _selectedCategory;
  String? _imagePath;

  List<Ingredient> _parsedIngredients = [];
  List<RecipeStep> _parsedSteps = [];

  final List<String> _categories = [
    'Desayuno',
    'Almuerzo',
    'Merienda',
    'Cena',
    'Postres',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRecipe;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _prepTimeController = TextEditingController(text: r != null ? r.prepTimeMinutes.toString() : '15');
    _cookTimeController = TextEditingController(text: r != null ? r.cookTimeMinutes.toString() : '25');
    _servingsController = TextEditingController(text: r != null ? r.baseServings.toString() : '4');
    _selectedCategory = r?.category ?? 'Almuerzo';
    _imagePath = r != null && r.imageUrl.isNotEmpty ? r.imageUrl : null;

    // Initialize ingredients text
    if (r != null && r.ingredients.isNotEmpty) {
      _ingredientsTextController = TextEditingController(
        text: r.ingredients
            .map((i) => PortionCalculator.formatIngredientDisplay(
                  amount: i.amount,
                  unit: i.unit,
                  name: i.name,
                  notes: i.notes,
                ))
            .join('\n'),
      );
    } else {
      _ingredientsTextController = TextEditingController();
    }

    // Initialize steps text
    if (r != null && r.steps.isNotEmpty) {
      _stepsTextController = TextEditingController(
        text: r.steps.map((s) => '${s.stepNumber}. ${s.instruction}').join('\n\n'),
      );
    } else {
      _stepsTextController = TextEditingController();
    }

    // Initial parsing
    _updateParsedIngredients();
    _updateParsedSteps();

    // Listeners for live preview update
    _ingredientsTextController.addListener(_updateParsedIngredients);
    _stepsTextController.addListener(_updateParsedSteps);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _ingredientsTextController.dispose();
    _stepsTextController.dispose();
    super.dispose();
  }

  void _updateParsedIngredients() {
    final text = _ingredientsTextController.text;
    final lines = text.split(RegExp(r'\r?\n+'));
    final List<Ingredient> parsed = [];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final ing = IngredientParser.parseLine(line);
      if (ing.name.trim().isNotEmpty) {
        parsed.add(ing);
      }
    }

    setState(() {
      _parsedIngredients = parsed;
    });
  }

  void _updateParsedSteps() {
    final text = _stepsTextController.text;
    final lines = text.split(RegExp(r'\r?\n+'));
    final List<RecipeStep> parsed = [];
    int stepNum = 1;

    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.endsWith(':') || line.startsWith('#')) {
        final cleanHeader = line.replaceAll(RegExp(r'^[#\s]+'), '').trim();
        parsed.add(RecipeStep(
          stepNumber: 0,
          instruction: cleanHeader,
          isSectionHeader: true,
        ));
        continue;
      }

      // Clean leading step labels like "1.", "1)", "Paso 1:", "- ", "* ", "• "
      line = line.replaceFirst(
        RegExp(r'^(?:paso\s*\d+[\s:\.\-]*|\d+[\.\)\-:]*|[-*•])\s*', caseSensitive: false),
        '',
      ).trim();

      if (line.isNotEmpty) {
        parsed.add(RecipeStep(
          stepNumber: stepNum++,
          instruction: line,
        ));
      }
    }

    setState(() {
      _parsedSteps = parsed;
    });
  }

  void _insertNextStepNumber() {
    final currentText = _stepsTextController.text;
    final nextNumber = _parsedSteps.where((s) => !s.isSectionHeader).length + 1;
    final prefix = currentText.isEmpty || currentText.endsWith('\n') ? '' : '\n\n';
    final addition = '$prefix$nextNumber. ';

    _stepsTextController.text = '$currentText$addition';
    _stepsTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _stepsTextController.text.length),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final strings = AppStrings.of(context);

    if (_parsedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.isSpanish
                ? 'Por favor, ingresa al menos un ingrediente'
                : 'Please enter at least one ingredient',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (_parsedSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.isSpanish
                ? 'Por favor, ingresa al menos un paso de preparación'
                : 'Please enter at least one step',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final recipeId = widget.initialRecipe?.id ?? const Uuid().v4();
    final now = DateTime.now();

    final recipe = Recipe(
      id: recipeId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      prepTimeMinutes: int.tryParse(_prepTimeController.text.trim()) ?? 15,
      cookTimeMinutes: int.tryParse(_cookTimeController.text.trim()) ?? 25,
      baseServings: int.tryParse(_servingsController.text.trim()) ?? 4,
      imageUrl: _imagePath ?? '',
      isFavorite: widget.initialRecipe?.isFavorite ?? false,
      ingredients: _parsedIngredients,
      steps: _parsedSteps,
      createdAt: widget.initialRecipe?.createdAt ?? now,
    );

    await ref.read(recipesListProvider.notifier).saveRecipe(recipe);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isEditing = widget.initialRecipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? strings.editRecipeTitle : strings.newRecipeTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(strings.saveRecipe),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          children: [
            // Image Picker Header Card
            Center(
              child: GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _imagePath!.startsWith('http')
                                  ? Image.network(_imagePath!, fit: BoxFit.cover)
                                  : Image.file(File(_imagePath!), fit: BoxFit.cover),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(strings.changePhoto, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: theme.colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              strings.addPhoto,
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Basic Info
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.basicInfoSection, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: strings.titleLabel,
                prefixIcon: const Icon(Icons.restaurant_rounded, size: 20),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? strings.titleRequired : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: strings.categoryLabel,
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),

            // Compact 3-Column Metrics (Prep, Cook, Servings)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                      labelText: strings.prepLabel,
                      hintText: '15',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.soup_kitchen_outlined, size: 18),
                      labelText: strings.cookLabel,
                      hintText: '25',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.people_outline, size: 18),
                      labelText: strings.servingsLabel,
                      hintText: '4',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Section 2: Unified Ingredients Input
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  strings.ingredientsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_parsedIngredients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_parsedIngredients.length} ${strings.ingredientsDetected}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _ingredientsTextController,
              minLines: 4,
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: strings.ingredientsQuickInputHint,
                hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.outline.withValues(alpha: 0.8)),
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),

            // Live Ingredients Preview Chips
            if (_parsedIngredients.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          strings.isSpanish ? 'Vista previa detectada:' : 'Detected preview:',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _parsedIngredients.map((ing) {
                        if (ing.isSectionHeader) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Row(
                              children: [
                                Icon(Icons.bookmark_outline, size: 15, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  ing.name.endsWith(':') ? ing.name : '${ing.name}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final emoji = CulinaryCatalog.getEmoji(ing.name);
                        final display = PortionCalculator.formatIngredientDisplay(
                          amount: ing.amount,
                          unit: ing.unit,
                          name: ing.name,
                          notes: ing.notes,
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(
                                display,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Section 3: Unified Steps Input
            Row(
              children: [
                Icon(Icons.format_list_numbered_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  strings.stepsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_parsedSteps.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_parsedSteps.where((s) => !s.isSectionHeader).length} ${strings.stepsDetected}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _stepsTextController,
              minLines: 5,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: strings.stepsQuickInputHint,
                hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.outline.withValues(alpha: 0.8)),
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 8),

            // Helper button: Insert next step
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _insertNextStepNumber,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(strings.insertNextStep),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Live Steps Preview
            if (_parsedSteps.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          strings.isSpanish ? 'Pasos reconocidos para el Modo Cocina:' : 'Recognized Cook Mode steps:',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._parsedSteps.map((step) {
                      if (step.isSectionHeader) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_outline, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                step.instruction.endsWith(':') ? step.instruction : '${step.instruction}:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Check for detected time in step
                      final hasTimer = RegExp(r'\b\d+\s*(?:minutos?|mins?|min|horas?|hrs?)\b', caseSensitive: false)
                          .hasMatch(step.instruction);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              child: Text(
                                '${step.stepNumber}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.instruction,
                                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                                  ),
                                  if (hasTimer) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 12, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          strings.isSpanish ? 'Temporizador detectable' : 'Detectable timer',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(strings.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(strings.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
