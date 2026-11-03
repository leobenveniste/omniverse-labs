import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_background.dart';
import 'app_header.dart';
import '../screens/auth/welcome_guide_screen.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showHelpButton;
  final bool isBusy;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showHelpButton = true,
    this.isBusy = false,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        title: AppHeaderTitle(title: title, subtitle: subtitle),
        actions: [
          if (showHelpButton)
            IconButton(
              tooltip: 'Cómo funciona Círculo',
              style: AppTheme.headerIconButtonStyle(context),
              icon: const Icon(Icons.help_outline_rounded, size: 22),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const WelcomeGuideScreen(isModal: true),
                  ),
                );
              },
            ),
          ...?actions,
          const SizedBox(width: 8),
        ],
        bottom: isBusy
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppTheme.electricViolet : AppTheme.deepViolet,
                  ),
                ),
              )
            : null,
      ),
      body: AppBackground(
        child: SafeArea(
          bottom: bottomNavigationBar == null,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar != null
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: bottomNavigationBar,
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
