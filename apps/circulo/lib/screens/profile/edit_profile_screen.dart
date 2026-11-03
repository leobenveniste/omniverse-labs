import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_feedback_components.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _neighborhoodCtrl;

  late String _selectedRegion;
  late String _selectedRole;
  late String _selectedVibe;
  late Set<String> _interests;
  late Set<String> _plans;
  late Set<String> _slots;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser!;
    _firstNameCtrl = TextEditingController(text: user.firstName);
    _lastNameCtrl = TextEditingController(text: user.lastName);
    _bioCtrl = TextEditingController(text: user.bio);
    _phoneCtrl = TextEditingController(text: user.phone);
    _instagramCtrl = TextEditingController(text: user.instagram ?? '');
    _neighborhoodCtrl = TextEditingController(text: user.neighborhood);

    _selectedRegion = user.region;
    _selectedRole = user.groupRole;
    _selectedVibe = user.socialVibe;
    _interests = Set<String>.from(user.interests);
    _plans = Set<String>.from(user.favoritePlans);
    _slots = Set<String>.from(user.availabilitySlots);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _instagramCtrl.dispose();
    _neighborhoodCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

    final updated = user.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      instagram: _instagramCtrl.text.trim().replaceAll('@', ''),
      region: _selectedRegion,
      neighborhood: _neighborhoodCtrl.text.trim(),
      groupRole: _selectedRole,
      socialVibe: _selectedVibe,
      interests: _interests.toList(),
      favoritePlans: _plans.toList(),
      availabilitySlots: _slots.toList(),
    );

    await SavingOverlayHUD.run(
      context,
      message: 'Guardando perfil en la nube...',
      successMessage: '¡Perfil actualizado con éxito!',
      task: () async {
        return await auth.updateProfile(updated);
      },
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return AppScaffold(
      title: l10n.get('editProfileBtn'),
      actions: [
        IconButton(
          tooltip: 'Guardar',
          style: AppTheme.headerIconButtonStyle(context),
          icon: const Icon(Icons.check_rounded),
          onPressed: _handleSave,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.get('firstNameLabel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastNameCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.get('lastNameLabel')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 240,
              decoration: InputDecoration(
                labelText: l10n.get('bioLabel'),
              ),
            ),
            const SizedBox(height: 16),

            // Rol en el Grupo
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: l10n.get('onboardingStep2Title'),
              ),
              items: GroupRoles.all.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                      '${GroupRoles.getIcon(r)} ${l10n.translateGroupRole(r)}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            const SizedBox(height: 16),

            // Región y Barrio
            DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: InputDecoration(
                labelText: l10n.get('regionLabel'),
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
              controller: _neighborhoodCtrl,
              decoration: InputDecoration(
                labelText: l10n.get('neighborhoodLabel'),
              ),
            ),
            const SizedBox(height: 16),

            // Instagram y Teléfono
            TextField(
              controller: _instagramCtrl,
              decoration: InputDecoration(
                labelText: l10n.get('instagramLabel'),
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.get('phoneLabel'),
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Intereses
            Text(
              'Intereses',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppInterests.all.map((i) {
                final isSel = _interests.contains(i);
                return InterestTagChip(
                  label: l10n.translateInterest(i),
                  isSelected: isSel,
                  onTap: () {
                    setState(() {
                      if (isSel) {
                        _interests.remove(i);
                      } else {
                        _interests.add(i);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            LoadingPrimaryButton(
              label: 'Guardar Cambios',
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
