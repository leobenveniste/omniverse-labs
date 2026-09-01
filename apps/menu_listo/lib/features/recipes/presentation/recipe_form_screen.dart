import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
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
  late TextEditingController _baseServingsController;
  late TextEditingController _tagsController;

  late String _category;
  String _imageUrl = '';
  late List<_IngredientFormEntry> _ingredientEntries;
  late List<TextEditingController> _stepControllers;

  @override
  void initState() {
    super.initState();
    final init = widget.initialRecipe;

    _titleController = TextEditingController(text: init?.title ?? '');
    _descriptionController = TextEditingController(text: init?.description ?? '');
    _prepTimeController = TextEditingController(text: (init?.prepTimeMinutes ?? 15).toString());
    _cookTimeController = TextEditingController(text: (init?.cookTimeMinutes ?? 20).toString());
    _baseServingsController = TextEditingController(text: (init?.baseServings ?? 2).toString());
    _tagsController = TextEditingController(text: init?.tags.join(', ') ?? '');
    _category = init?.category ?? 'Almuerzo';
    _imageUrl = init?.imageUrl ?? '';

    if (init != null && init.ingredients.isNotEmpty) {
      _ingredientEntries = init.ingredients.map((i) => _IngredientFormEntry(
        amountCtrl: TextEditingController(text: i.amount > 0 ? i.amount.toString().replaceAll('.0', '') : ''),
        unitCtrl: TextEditingController(text: i.unit),
        nameCtrl: TextEditingController(text: i.name),
        notesCtrl: TextEditingController(text: i.notes),
      )).toList();
    } else {
      _ingredientEntries = [
        _IngredientFormEntry(
          amountCtrl: TextEditingController(),
          unitCtrl: TextEditingController(),
          nameCtrl: TextEditingController(),
          notesCtrl: TextEditingController(),
        ),
      ];
    }

    if (init != null && init.steps.isNotEmpty) {
      _stepControllers = init.steps.map((s) => TextEditingController(text: s.instruction)).toList();
    } else {
      _stepControllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _baseServingsController.dispose();
    _tagsController.dispose();
    for (var e in _ingredientEntries) {
      e.dispose();
    }
    for (var s in _stepControllers) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');
      setState(() {
        _imageUrl = savedImage.path;
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientEntries.add(_IngredientFormEntry(
        amountCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
        nameCtrl: TextEditingController(),
        notesCtrl: TextEditingController(),
      ));
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientEntries.length > 1) {
      setState(() {
        _ingredientEntries[index].dispose();
        _ingredientEntries.removeAt(index);
      });
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final strings = AppStrings.of(context);

    // Build ingredients
    final ingredients = <Ingredient>[];
    for (var e in _ingredientEntries) {
      final name = e.nameCtrl.text.trim();
      if (name.isNotEmpty) {
        final amount = double.tryParse(e.amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
        final unit = e.unitCtrl.text.trim();
        final notes = e.notesCtrl.text.trim();
        ingredients.add(Ingredient(
          amount: amount,
          unit: unit,
          name: name,
          notes: notes,
        ));
      }
    }

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.validationIngredientsRequired)),
      );
      return;
    }

    // Build steps
    final steps = <RecipeStep>[];
    int stepNum = 1;
    for (var s in _stepControllers) {
      final instruction = s.text.trim();
      if (instruction.isNotEmpty) {
        steps.add(RecipeStep(stepNumber: stepNum++, instruction: instruction));
      }
    }

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.validationStepsRequired)),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final recipe = Recipe(
      id: widget.initialRecipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      prepTimeMinutes: int.tryParse(_prepTimeController.text.trim()) ?? 15,
      cookTimeMinutes: int.tryParse(_cookTimeController.text.trim()) ?? 20,
      baseServings: int.tryParse(_baseServingsController.text.trim()) ?? 2,
      tags: tags,
      imageUrl: _imageUrl,
      sourceUrl: widget.initialRecipe?.sourceUrl ?? '',
      isFavorite: widget.initialRecipe?.isFavorite ?? false,
      ingredients: ingredients,
      steps: steps,
      createdAt: widget.initialRecipe?.createdAt ?? DateTime.now(),
    );

    await ref.read(recipesListProvider.notifier).saveRecipe(recipe);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.recipeCreatedSuccess)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isEditing = widget.initialRecipe != null;

    final categories = [
      strings.catBreakfast,
      strings.catLunch,
      strings.catSnack,
      strings.catDinner,
      strings.catDessert,
      strings.catOther,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? strings.formTitleEdit : strings.formTitleNew),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: strings.save,
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Image Picker Box
            GestureDetector(
              onTap: () => _showImageSourcePicker(context),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                ),
                child: _imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildCoverPreview(),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(strings.selectPhoto, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: strings.fieldTitle,
                prefixIcon: const Icon(Icons.restaurant),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? strings.validationTitleRequired : null,
            ),
            const SizedBox(height: 14),
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: strings.fieldDescription,
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            // Category Selector
            DropdownButtonFormField<String>(
              value: categories.contains(_category) ? _category : categories.first,
              decoration: InputDecoration(
                labelText: strings.fieldCategory,
                prefixIcon: const Icon(Icons.category),
              ),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 14),
            // Times and Servings Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.fieldPrepTime,
                      prefixIcon: const Icon(Icons.timer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.fieldCookTime,
                      prefixIcon: const Icon(Icons.local_fire_department_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Base Servings & Tags
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _baseServingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.fieldBaseServings,
                      prefixIcon: const Icon(Icons.group_outlined),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return strings.validationServingsRequired;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: strings.fieldTags,
                      prefixIcon: const Icon(Icons.tag),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // --- INGREDIENTS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.ingredientsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: Text(strings.addIngredient),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientEntries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = _ingredientEntries[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Amount
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              controller: entry.amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: strings.ingredientAmount,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unit
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: entry.unitCtrl,
                              decoration: InputDecoration(
                                labelText: strings.ingredientUnit,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Name
                          Expanded(
                            child: TextFormField(
                              controller: entry.nameCtrl,
                              decoration: InputDecoration(
                                labelText: strings.ingredientName,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          if (_ingredientEntries.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                              onPressed: () => _removeIngredient(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Optional Notes
                      TextFormField(
                        controller: entry.notesCtrl,
                        decoration: InputDecoration(
                          hintText: strings.ingredientNotes,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.info_outline, size: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            // --- STEPS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.instructionsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: Text(strings.addStep),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stepControllers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ctrl = _stepControllers[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: ctrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '${strings.step} ${index + 1}...',
                        ),
                      ),
                    ),
                    if (_stepControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                        onPressed: () => _removeStep(index),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.check),
              label: Text(strings.save, style: const TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    if (_imageUrl.startsWith('http')) {
      return Image.network(_imageUrl, fit: BoxFit.cover, width: double.infinity);
    } else {
      return Image.file(File(_imageUrl), fit: BoxFit.cover, width: double.infinity);
    }
  }

  void _showImageSourcePicker(BuildContext context) {
    final strings = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(strings.fromGallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(strings.fromCamera),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text(strings.removePhoto, style: const TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _imageUrl = '');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientFormEntry {
  final TextEditingController amountCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;

  _IngredientFormEntry({
    required this.amountCtrl,
    required this.unitCtrl,
    required this.nameCtrl,
    required this.notesCtrl,
  });

  void dispose() {
    amountCtrl.dispose();
    unitCtrl.dispose();
    nameCtrl.dispose();
    notesCtrl.dispose();
  }
}
