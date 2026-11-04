import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_feedback_components.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../l10n/app_localizations.dart';
import '../home_shell_screen.dart';
import 'login_screen.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _selectedGender = AppGenders.preferNotToSay;
  String _selectedRegion = AppRegions.buenosAires;
  String? _photoUrl;
  String _selectedRole = GroupRoles.chill;
  String _selectedVibe = AppVibes.balanced;
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedPlans = {};
  final Set<String> _selectedSlots = {};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _neighborhoodController.text = user.neighborhood;
      _birthDate = user.birthDate;
      if (user.gender.isNotEmpty) {
        _selectedGender = user.gender;
      }
      if (user.region.isNotEmpty) {
        _selectedRegion = user.region;
      }
      _bioController.text = user.bio;
      _photoUrl = user.photoUrl;
      _selectedRole = user.groupRole;
      _selectedVibe = user.socialVibe;
      _selectedInterests.addAll(user.interests);
      _selectedPlans.addAll(user.favoritePlans);
      _selectedSlots.addAll(user.availabilitySlots);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _neighborhoodController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // +18
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleCancel() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('cancel')),
        content: Text(l10n.get('exitOnboardingConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.get('confirm')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = context.read<AuthService>();
      await auth.logout();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleFinish() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthService>();

    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('selectMinInterests')),
          backgroundColor: AppTheme.warmAmber,
        ),
      );
      setState(() => _currentStep = 2);
      return;
    }

    await SavingOverlayHUD.run(
      context,
      message: l10n.get('savingProfile'),
      successMessage: l10n.get('savedSuccess'),
      task: () async {
        return await auth.completeOnboarding(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _birthDate,
          gender: _selectedGender,
          region: _selectedRegion,
          neighborhood: _neighborhoodController.text.trim(),
          bio: _bioController.text.trim(),
          photoUrl: _photoUrl,
          groupRole: _selectedRole,
          interests: _selectedInterests.toList(),
          favoritePlans: _selectedPlans.toList(),
          socialVibe: _selectedVibe,
          availabilitySlots: _selectedSlots.toList(),
        );
      },
    );

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShellScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    final stepTitles = [
      l10n.get('onboardingStep1Title'),
      l10n.get('onboardingStep2Title'),
      l10n.get('onboardingStep3Title'),
      l10n.get('onboardingStep4Title'),
    ];

    return AppScaffold(
      showHelpButton: false,
      title: l10n.get('appName'),
      subtitle: 'Paso ${_currentStep + 1} de 4 • ${stepTitles[_currentStep]}',
      actions: [
        TextButton(
          onPressed: _handleCancel,
          child: Text(
            l10n.get('cancel'),
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          // Barra de progreso de 4 pasos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(4, (i) {
                final isDone = i <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isDone ? primary : AppTheme.borderColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Contenido del Paso Activo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(l10n, textPrimary, textSecondary),
            ),
          ),

          // Botones de Navegación Inferiores
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentStep--);
                    },
                    child: Text(l10n.get('back')),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: LoadingPrimaryButton(
                    label: _currentStep == 3
                        ? l10n.get('finish')
                        : l10n.get('continueBtn'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_currentStep == 0) {
                        if (_firstNameController.text.trim().isEmpty ||
                            _lastNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.get('fillRequiredFields')),
                              backgroundColor: AppTheme.warmAmber,
                            ),
                          );
                          return;
                        }
                      }
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _handleFinish();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(l10n, textPrimary, textSecondary);
      case 1:
        return _buildStep2(l10n, textPrimary, textSecondary);
      case 2:
        return _buildStep3(l10n, textPrimary, textSecondary);
      case 3:
      default:
        return _buildStep4(l10n, textPrimary, textSecondary);
    }
  }

  // Paso 1: Perfil Completo, Foto y Bio
  Widget _buildStep1(
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
  ) {
    final primary = AppTheme.primaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GestureDetector(
            onTap: () {
              // Selección de avatar predefinido o foto
              setState(() {
                _photoUrl =
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400';
              });
            },
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.15),
                border: Border.all(color: primary, width: 2),
              ),
              child: ClipOval(
                child: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? Image.network(
                        _photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.add_a_photo_rounded,
                          size: 32,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 28, color: primary),
                          const SizedBox(height: 4),
                          const Text('Foto', style: TextStyle(fontSize: 11)),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Nombre y Apellido
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: '${l10n.get('firstNameLabel')} *',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: '${l10n.get('lastNameLabel')} *',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selector Fecha de Nacimiento
        InkWell(
          onTap: _selectBirthDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${l10n.get('birthDateLabel')}: ${DateFormat('dd/MM/yyyy').format(_birthDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.edit_calendar_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Selector Género
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: InputDecoration(
            labelText: l10n.get('genderLabel'),
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
          ),
          items: [
            DropdownMenuItem(
              value: AppGenders.female,
              child: Text(l10n.get('genderFemale')),
            ),
            DropdownMenuItem(
              value: AppGenders.male,
              child: Text(l10n.get('genderMale')),
            ),
            DropdownMenuItem(
              value: AppGenders.nonBinary,
              child: Text(l10n.get('genderNonBinary')),
            ),
            DropdownMenuItem(
              value: AppGenders.preferNotToSay,
              child: Text(l10n.get('genderPreferNotToSay')),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedGender = val);
          },
        ),
        const SizedBox(height: 16),

        // Región y Barrio
        DropdownButtonFormField<String>(
          initialValue: _selectedRegion,
          decoration: InputDecoration(
            labelText: l10n.get('regionLabel'),
            prefixIcon: const Icon(Icons.place_outlined, size: 20),
          ),
          items: AppRegions.all.map((r) {
            return DropdownMenuItem(value: r, child: Text(r));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedRegion = val);
          },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _neighborhoodController,
          decoration: InputDecoration(
            labelText: l10n.get('neighborhoodLabel'),
            prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 20),

        // Bio
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.get('bioLabel'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 240,
          decoration: InputDecoration(
            hintText: l10n.get('bioHint'),
          ),
        ),
      ],
    );
  }

  // Paso 2: Rol en el Grupo (Química de Roles)
  Widget _buildStep2(
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
  ) {
    final roles = GroupRoles.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuál es tu rol natural con amigos?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Usamos esto para balancear cada Círculo y que nunca falte un plan.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 16),
        ...roles.map((role) {
          final isSelected = _selectedRole == role;
          final primary = AppTheme.primaryColor(context);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRole = role);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.14)
                    : AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primary : AppTheme.borderColor(context),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(GroupRoles.getIcon(role),
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translateGroupRole(role),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? primary : textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.get('role${role[0].toUpperCase()}${role.substring(1)}Desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: primary, size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Paso 3: Intereses y Planes Favoritos
  Widget _buildStep3(
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegí tus intereses (mínimo 3):',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppInterests.all.map((interest) {
            final isSel = _selectedInterests.contains(interest);
            return InterestTagChip(
              label: l10n.translateInterest(interest),
              isSelected: isSel,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSel) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Tus planes favoritos para juntarse:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppPlans.all.map((plan) {
            final isSel = _selectedPlans.contains(plan);
            return InterestTagChip(
              label: l10n.translatePlan(plan),
              isSelected: isSel,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSel) {
                    _selectedPlans.remove(plan);
                  } else {
                    _selectedPlans.add(plan);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // Paso 4: Disponibilidad Horaria Semanal
  Widget _buildStep4(
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿En qué momentos solés tener tiempo libre?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Conectamos personas con franjas horarias coincidentes para facilitar las salidas.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 16),
        ...AvailabilitySlots.all.map((slot) {
          final isSel = _selectedSlots.contains(slot);
          final primary = AppTheme.primaryColor(context);

          return CheckboxListTile(
            value: isSel,
            title: Text(
              l10n.translateAvailability(slot),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? primary : textPrimary,
              ),
            ),
            activeColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() {
                if (val == true) {
                  _selectedSlots.add(slot);
                } else {
                  _selectedSlots.remove(slot);
                }
              });
            },
          );
        }),
      ],
    );
  }
}
