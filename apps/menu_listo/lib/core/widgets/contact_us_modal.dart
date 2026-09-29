import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/app_localizations.dart';

class ContactUsModal extends StatelessWidget {
  static const String contactEmail = 'leo.benveniste@gmail.com';

  const ContactUsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ContactUsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isSpanish = strings.isSpanish;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isSpanish ? 'Contacto y Sugerencias' : 'Contact & Feedback',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            isSpanish
                ? '¿Tienes sugerencias para mejorar la app, encontraste algún error o quieres proponer una nueva función? Escríbenos directamente y te responderemos a la brevedad:'
                : 'Have suggestions, found a bug, or have ideas for Menú Listo? Reach out directly and we will get back to you promptly:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // Email Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    contactEmail,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: isSpanish ? 'Copiar correo' : 'Copy email',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(const ClipboardData(text: contactEmail));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSpanish
                              ? 'Correo copiado al portapapeles: $contactEmail'
                              : 'Email copied to clipboard: $contactEmail',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Copy CTA
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(
              isSpanish ? 'Copiar dirección de correo' : 'Copy Email Address',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(const ClipboardData(text: contactEmail));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSpanish
                        ? 'Correo copiado: $contactEmail'
                        : 'Email copied: $contactEmail',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSpanish ? 'Cerrar' : 'Close'),
          ),
        ],
      ),
    );
  }
}
