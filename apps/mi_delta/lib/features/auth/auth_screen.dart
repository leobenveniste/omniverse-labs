import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/municipality_config.dart';
import '../../providers/app_providers.dart';
import '../../widgets/municipality_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // Mode: true = Login, false = Register
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedDocType = 'DNI';

  final _dniController = TextEditingController(text: '29583026');
  final _passController = TextEditingController(text: 'vecino1234');
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final Color _navyDark = const Color(0xFF032244);
  final Color _blueBrand = const Color(0xFF0260C2);
  final Color _slateDark = const Color(0xFF0F2644);
  final Color _slateMuted = const Color(0xFF64748B);

  @override
  void dispose() {
    _dniController.dispose();
    _passController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (_isLogin) {
      final dni = _dniController.text.trim();
      final pass = _passController.text.trim();

      if (dni.isEmpty || pass.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresá tu DNI y contraseña.')),
        );
        return;
      }

      final success = ref.read(authProvider.notifier).loginWithDni(dni, pass);
      if (!success && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas. Verificá tus datos.')),
        );
      }
    } else {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final pass = _passController.text.trim();
      final dni = _dniController.text.trim();

      if (name.isEmpty || email.isEmpty || pass.isEmpty || dni.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor completá todos los campos para el registro.')),
        );
        return;
      }

      final success = ref.read(authProvider.notifier).register(name, email, pass);
      if (!success && mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear tu cuenta.')),
        );
      }
    }
  }

  void _loginBiometric() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final bioService = ref.read(biometricServiceProvider);
    final result = await bioService.authenticate();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF064E3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 22),
              SizedBox(width: 12),
              Text(
                'Identidad biométrica confirmada con éxito.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        ref.read(authProvider.notifier).loginAsDemo();
      }
    } else if (result.canceled) {
      // User canceled biometric prompt; simply return
      return;
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.fingerprint_rounded, color: Color(0xFFFCA5A5), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.errorMessage ?? 'No se pudo verificar la huella digital.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _loginFastDemo() {
    HapticFeedback.selectionClick();
    ref.read(authProvider.notifier).loginAsDemo();
  }

  void _showEmergencyDialog() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Color(0xFFBA1A1A), size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Líneas de Urgencias 24 hs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _slateDark,
                      ),
                    ),
                    Text(
                      'Asistencia inmediata de Altos del Delta',
                      style: TextStyle(fontSize: 12, color: _slateMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEmergencyTile('SAME Delta / Ambulancias', '107', Icons.local_hospital_rounded, const Color(0xFF006C49)),
            const SizedBox(height: 10),
            _buildEmergencyTile('Centro de Operaciones Delta (COD)', '0800-333-3358', Icons.shield_rounded, const Color(0xFF0260C2)),
            const SizedBox(height: 10),
            _buildEmergencyTile('Bomberos Voluntarios', '100', Icons.local_fire_department_rounded, const Color(0xFFE06D53)),
            const SizedBox(height: 10),
            _buildEmergencyTile('Línea DAMA - Asistencia Género', '144', Icons.favorite_rounded, const Color(0xFF9333EA)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile(String title, String number, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFBA1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Llamando a $title ($number)...')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD0E4ED),
      body: Stack(
        children: [
          // 1. Base subtle gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD0E4ED),
                    Color(0xFFE8F3F8),
                    Color(0xFFF6FAFD),
                  ],
                  stops: [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),

          // 2. Mapcn-inspired subtle cartographic vector map (waterways & streets)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _MapcnBackgroundPainter(),
              ),
            ),
          ),

          // 3. Foreground Safe Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                    child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // 1. TOP MUNICIPALITY LOGO (Prominent, standalone, without container)
                        const MunicipalityLogo(size: 84),
                        const SizedBox(height: 14),

                        // 2. MUNICIPALITY TITLE & WELCOME
                        Text(
                          MunicipalityConfig.shortName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _slateDark,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin ? 'Bienvenido a tu comunidad' : 'Creá tu cuenta',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _slateMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3. REGISTER ONLY: FULL NAME & EMAIL
                        if (!_isLogin) ...[
                          _buildLabelRow('Nombre y Apellido', 'Como figura en tu DNI'),
                          const SizedBox(height: 6),
                          _buildContainerInput(
                            child: TextField(
                              controller: _nameController,
                              style: TextStyle(fontSize: 14, color: _slateDark, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Ej: Valentina Gómez',
                                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                suffixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabelRow('Correo Electrónico', 'Para avisos y turnos'),
                          const SizedBox(height: 6),
                          _buildContainerInput(
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: 14, color: _slateDark, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'tu.correo@ejemplo.com',
                                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                suffixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 4. FIELD 1: IDENTIFICACIÓN (DNI)
                        _buildLabelRow('Identificación', 'Sin puntos ni guiones'),
                        const SizedBox(height: 6),
                        _buildContainerInput(
                          child: Row(
                            children: [
                              // Document Type Selector
                              PopupMenuButton<String>(
                                onSelected: (val) => setState(() => _selectedDocType = val),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'DNI', child: Text('DNI')),
                                  const PopupMenuItem(value: 'LC', child: Text('LC')),
                                  const PopupMenuItem(value: 'LE', child: Text('LE')),
                                  const PopupMenuItem(value: 'PAS', child: Text('Pasaporte')),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 14, right: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedDocType,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _slateDark,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),

                              // Vertical Divider
                              Container(
                                width: 1.2,
                                height: 22,
                                color: const Color(0xFFCBD5E1),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                              ),

                              // Number Text Field
                              Expanded(
                                child: TextField(
                                  controller: _dniController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _slateDark,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Ej: 29583026',
                                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                    isDense: true,
                                  ),
                                ),
                              ),

                              // Citizen Badge Icon
                              const Padding(
                                padding: EdgeInsets.only(right: 14),
                                child: Icon(Icons.badge_outlined, color: Color(0xFF94A3B8), size: 20),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 5. FIELD 2: CONTRASEÑA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _slateDark,
                              ),
                            ),
                            if (_isLogin)
                              InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enviamos instrucciones de recuperación a tu correo.'),
                                    ),
                                  );
                                },
                                child: Text(
                                  '¿Olvidaste tu clave?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _blueBrand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildContainerInput(
                          child: TextField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _slateDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ingresá tu clave personal',
                              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 19,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 6. PRIMARY CTA BUTTON: "Ingresar a mi cuenta →"
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navyDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin ? 'Ingresar a mi cuenta' : 'Crear mi cuenta',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 7. BIOMETRICS: "Ingresar con Huella o Face ID"
                        if (_isLogin) ...[
                          InkWell(
                            onTap: _loginBiometric,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 20,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Ingresar con Huella o Face ID',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _slateDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // 8. REGISTRATION LINK: "¿No tenés cuenta? Registrate"
                        Center(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isLogin = !_isLogin);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text.rich(
                                TextSpan(
                                  text: _isLogin ? '¿No tenés cuenta? ' : '¿Ya tenés cuenta? ',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: _slateMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _isLogin ? 'Registrate' : 'Iniciá sesión',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: _blueBrand,
                                        decoration: TextDecoration.underline,
                                        decorationColor: _blueBrand.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtle Developer 1-Tap Demo Chip (DEBAJO DEL LINK DE REGISTRACIÓN)
                        Center(
                          child: InkWell(
                            onTap: _loginFastDemo,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 13, color: _blueBrand),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ingreso Demo 1-Tap',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _slateDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // SPACER TO PUSH EMERGENCY BUTTON AND FOOTER TO THE VERY BOTTOM
                        const Spacer(),
                        const SizedBox(height: 16),

                        // 9. EMERGENCY / SOS CARD: "URGENCIAS 24 HS - Llamar a Emergencias (911 / 107)"
                        InkWell(
                          onTap: _showEmergencyDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B0F0B),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B0F0B).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Red SOS badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'SOS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title & Subtitle
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'URGENCIAS 24 HS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFB4AB),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Llamar a Emergencias (911 / 107)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Phone Icon
                                const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 10. FOOTER LINKS & MUNICIPALITY TAGLINE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFooterLink('Centro de Ayuda'),
                            _buildDot(),
                            _buildFooterLink('Términos de Privacidad'),
                            _buildDot(),
                            _buildFooterLink('Línea 147'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${MunicipalityConfig.name} • Buenos Aires',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLabelRow(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _slateDark,
          ),
        ),
        Text(
          right,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildContainerInput({required Widget child}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildFooterLink(String title) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sección: $title')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: _slateMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('•', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
    );
  }
}

/// Minimalist cartographic background inspired by mapcn (Mapbox / Carto vector styling).
/// Renders subtle delta waterways, street grids, and cartographic coordinate nodes
/// at very low opacity with a radial vignette to ensure 100% WCAG AA text contrast.
class _MapcnBackgroundPainter extends CustomPainter {
  const _MapcnBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Organic Delta Waterways
    final waterFill = Paint()
      ..color = const Color(0xFF0260C2).withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final waterStroke = Paint()
      ..color = const Color(0xFF0260C2).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final riverPath = Path();
    riverPath.moveTo(w * 0.65, 0);
    riverPath.cubicTo(w * 0.85, h * 0.22, w * 0.52, h * 0.58, w * 0.88, h * 0.88);
    riverPath.lineTo(w, h * 0.88);
    riverPath.lineTo(w, 0);
    riverPath.close();
    canvas.drawPath(riverPath, waterFill);

    final riverEdge = Path();
    riverEdge.moveTo(w * 0.65, 0);
    riverEdge.cubicTo(w * 0.85, h * 0.22, w * 0.52, h * 0.58, w * 0.88, h * 0.88);
    canvas.drawPath(riverEdge, waterStroke);

    // Secondary tributary channel
    final tributary = Path();
    tributary.moveTo(w * 0.62, h * 0.44);
    tributary.cubicTo(w * 0.40, h * 0.52, w * 0.30, h * 0.68, 0, h * 0.74);
    canvas.drawPath(
      tributary,
      Paint()
        ..color = const Color(0xFF0260C2).withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 2. Arterial Avenues / Highways
    final arterialPaint = Paint()
      ..color = const Color(0xFF0F2644).withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawLine(Offset(0, h * 0.22), Offset(w, h * 0.38), arterialPaint);
    canvas.drawLine(Offset(0, h * 0.62), Offset(w, h * 0.75), arterialPaint);
    canvas.drawLine(Offset(w * 0.32, 0), Offset(w * 0.45, h), arterialPaint);

    // 3. Secondary Vector Street Grid
    final streetPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const spacing = 38.0;
    for (double y = -h * 0.2; y < h * 1.2; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(w, y + w * 0.18), streetPaint);
    }
    for (double x = -w * 0.2; x < w * 1.2; x += spacing * 1.5) {
      canvas.drawLine(Offset(x, 0), Offset(x - h * 0.14, h), streetPaint);
    }

    // 4. Subtle Cartographic Crosshairs & Point Markers
    final crosshairPaint = Paint()
      ..color = const Color(0xFF0260C2).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFF0260C2).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(w * 0.14, h * 0.09),
      Offset(w * 0.86, h * 0.13),
      Offset(w * 0.82, h * 0.62),
      Offset(w * 0.16, h * 0.80),
      Offset(w * 0.52, h * 0.94),
    ];

    for (final pt in points) {
      canvas.drawCircle(pt, 2.0, dotPaint);
      canvas.drawLine(Offset(pt.dx - 4, pt.dy), Offset(pt.dx + 4, pt.dy), crosshairPaint);
      canvas.drawLine(Offset(pt.dx, pt.dy - 4), Offset(pt.dx, pt.dy + 4), crosshairPaint);
    }

    // 5. Soft Vignette / Central Radial Mask
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.72,
        colors: [
          Colors.white.withValues(alpha: 0.88),
          Colors.white.withValues(alpha: 0.20),
        ],
        stops: const [0.30, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

