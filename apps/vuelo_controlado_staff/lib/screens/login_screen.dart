import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completá tu correo y contraseña.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final success = await authService.login(email, password);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && authService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage!),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _fillCredentials(String email, String pass) {
    _emailController.text = email;
    _passwordController.text = pass;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Oficial
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/images/logo_color.png',
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          children: [
                            Icon(Icons.flight_takeoff,
                                size: 60, color: AppTheme.neonGreen),
                            SizedBox(height: 8),
                            Text(
                              'FUNDACIÓN VUELO CONTROLADO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.neonGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'PORTAL DE STAFF',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Formulario
                const Text(
                  'Correo electrónico',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppTheme.neonGreen),
                    hintText: 'nombre@vuelocontrolado.org',
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Contraseña',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: AppTheme.neonGreen),
                    hintText: 'Número de documento inicial',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ℹ️ Si es tu primer ingreso, tu clave es tu número de documento.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 28),

                // Botón Ingresar
                ElevatedButton(
                  onPressed: authService.isLoading ? null : _handleLogin,
                  child: authService.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text('INGRESAR AL SISTEMA'),
                ),
                const SizedBox(height: 32),

                // Accesos rápidos para testing
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acceso rápido de prueba:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Superadmin (Leo)'),
                            backgroundColor: AppTheme.darkCard,
                            side: const BorderSide(color: AppTheme.neonGreen),
                            labelStyle: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 12,
                            ),
                            onPressed: () => _fillCredentials(
                                'leobenveniste@vuelocontrolado.org', 'admin'),
                          ),
                          ActionChip(
                            label: const Text('Staff Demo'),
                            backgroundColor: AppTheme.darkCard,
                            side: const BorderSide(color: AppTheme.darkBorder),
                            labelStyle: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                            onPressed: () => _fillCredentials(
                                'demo@vuelocontrolado.org', '12345678'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
