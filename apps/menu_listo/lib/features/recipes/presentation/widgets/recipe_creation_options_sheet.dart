import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:menu_listo/core/localization/app_localizations.dart';
import 'package:menu_listo/features/recipes/services/recipe_photo_scanner.dart';
import 'package:menu_listo/features/recipes/presentation/recipe_form_screen.dart';
import 'package:menu_listo/features/recipes/presentation/widgets/recipe_import_url_dialog.dart';

void showRecipeCreationOptions(BuildContext context) {
  final strings = AppStrings.of(context);
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.isSpanish ? 'Agregar Nueva Receta' : 'Add New Recipe',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Option 1: Manual Form
            _buildOptionTile(
              context: ctx,
              icon: Icons.edit_note_rounded,
              iconColor: theme.colorScheme.primary,
              title: strings.isSpanish ? 'Crear receta manualmente' : 'Create recipe manually',
              subtitle: strings.isSpanish ? 'Ingresa tus ingredientes y pasos paso a paso' : 'Type in your custom ingredients and steps',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            // Option 2: Scan Photo OCR
            _buildOptionTile(
              context: ctx,
              icon: Icons.document_scanner_rounded,
              iconColor: const Color(0xFF2E7D32),
              title: strings.scanRecipePhoto,
              subtitle: strings.isSpanish ? 'Toma una foto de un libro o recetario impreso' : 'Take a photo of a cookbook or printed recipe',
              onTap: () {
                Navigator.pop(ctx);
                _showPhotoSourcePicker(context);
              },
            ),
            const SizedBox(height: 10),

            // Option 3: Import Web URL
            _buildOptionTile(
              context: ctx,
              icon: Icons.link_rounded,
              iconColor: const Color(0xFF0288D1),
              title: strings.importWebRecipe,
              subtitle: strings.isSpanish ? 'Pega el enlace de cualquier blog de cocina' : 'Paste the URL from any food blog or website',
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => const RecipeImportUrlDialog(),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showPhotoSourcePicker(BuildContext context) {
  final strings = AppStrings.of(context);
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.scanRecipePhoto,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
              ),
              title: Text(strings.takePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _performPhotoScan(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
              ),
              title: Text(strings.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _performPhotoScan(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _performPhotoScan(BuildContext context, ImageSource source) async {
  final strings = AppStrings.of(context);
  final scanner = RecipePhotoScanner();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Text(strings.scanningRecipe),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );

  final recipe = await scanner.scanRecipeFromImage(source: source);
  scanner.dispose();

  if (!context.mounted) return;

  if (recipe != null) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeFormScreen(initialRecipe: recipe),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.scanningFailed),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

Widget _buildOptionTile({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    ),
  );
}
