import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_feedback_components.dart';
import '../../widgets/motion_components.dart';
import '../../l10n/app_localizations.dart';
import 'register_screen.dart';
import 'welcome_guide_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final AnimationController _shakeController;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final lastUser = auth.getLastLoggedInUser();
      if (lastUser != null && _emailController.text.isEmpty) {
        _emailController.text = lastUser.email;
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completá tu correo y contraseña.'),
          backgroundColor: AppTheme.warmAmber,
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final success = await auth.login(email, password);
    if (!success && mounted) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al iniciar sesión.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final auth = context.read<AuthService>();
    final success = await auth.signInWithGoogle();
    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Error al conectar con Google.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final auth = context.read<AuthService>();
    final biometric = context.read<BiometricService>();
    final lastUser = auth.getLastLoggedInUser();

    if (lastUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay una cuenta previa para validar biometría.'),
          backgroundColor: AppTheme.warmAmber,
        ),
      );
      return;
    }

    final ok = await biometric.authenticate(
      localizedReason: 'Identificate como ${lastUser.fullName} para acceder',
    );

    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      await auth.loginWithBiometrics(lastUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final settings = context.watch<SettingsService>();
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Acciones superiores: Ayuda, Idioma y Tema
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: l10n.get('guideTitle'),
                          style: AppTheme.headerIconButtonStyle(context),
                          icon: const Icon(Icons.help_outline_rounded, size: 22),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) =>
                                    const WelcomeGuideScreen(isModal: true),
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'Idioma',
                              initialValue: settings.localeCode,
                              onSelected: (c) => settings.setLocaleCode(c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainer(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Text(
                                  settings.localeCode.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                    value: 'auto', child: Text('🌐 Auto')),
                                const PopupMenuItem(
                                    value: 'es', child: Text('🇪🇸 ES')),
                                const PopupMenuItem(
                                    value: 'en', child: Text('🇺🇸 EN')),
                                const PopupMenuItem(
                                    value: 'pt', child: Text('🇧🇷 PT')),
                                const PopupMenuItem(
                                    value: 'fr', child: Text('🇫🇷 FR')),
                                const PopupMenuItem(
                                    value: 'it', child: Text('🇮🇹 IT')),
                                const PopupMenuItem(
                                    value: 'de', child: Text('🇩🇪 DE')),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Tema',
                              style: AppTheme.headerIconButtonStyle(context),
                              icon: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 20,
                              ),
                              onPressed: () {
                                settings.setThemeModePreference(
                                    isDark ? 'light' : 'dark');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Logo y Marca
                    const CirculoLogoIcon(size: 48),
                    const SizedBox(height: 12),
                    Text(
                      l10n.get('appName'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.get('appTagline'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta Principal
                    ShakeAnimation(
                      controller: _shakeController,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.get('loginTitle'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Campo Email
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.get('emailLabel'),
                                prefixIcon: const Icon(Icons.email_outlined,
                                    size: 20),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Campo Password
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: l10n.get('passwordLabel'),
                                prefixIcon: const Icon(Icons.lock_outline_rounded,
                                    size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Botón Iniciar Sesión con animación
                            LoadingPrimaryButton(
                              label: l10n.get('loginBtn'),
                              loadingLabel: l10n.get('loggingIn'),
                              isLoading: auth.isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 16),

                            // Botón Continuar con Google
                            LoadingOutlinedButton(
                              label: l10n.get('googleSignInBtn'),
                              loadingLabel: l10n.get('connectingGoogle'),
                              isLoading: _isGoogleLoading,
                              icon: const Icon(Icons.g_mobiledata_rounded,
                                  size: 24),
                              onPressed: _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 12),

                            // Botón Biometría
                            if (settings.biometricEnabled) ...[
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      AppTheme.primaryColor(context),
                                ),
                                icon: const Icon(Icons.fingerprint_rounded,
                                    size: 20),
                                label: Text(
                                  l10n.get('biometricBtn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: _handleBiometricLogin,
                              ),
                            ],

                            // Acceso rápido para pruebas
                            const Divider(height: 28),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: [
                                ActionChip(
                                  label: const Text('Superadmin Demo',
                                      style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    _emailController.text =
                                        AppRoles.superAdminEmail;
                                    _passwordController.text = '29583026';
                                    _handleLogin();
                                  },
                                ),
                                ActionChip(
                                  label: const Text('Usuario Demo (Valen)',
                                      style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    _emailController.text = 'valen@circulo.app';
                                    _passwordController.text = '123456';
                                    _handleLogin();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Registro Público
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.get('noAccountPrompt'),
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.get('createAccountBtn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
