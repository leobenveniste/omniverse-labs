import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/country_helper.dart';
import '../../models/traveler_profile.dart';
import '../../repositories/storage_repository.dart';

class ProfileSetupScreen extends StatefulWidget {
  final StorageRepository storage;
  final VoidCallback onProfileComplete;

  const ProfileSetupScreen({
    super.key,
    required this.storage,
    required this.onProfileComplete,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _natController = TextEditingController(text: 'ARG');
  final _passportNumController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365 * 5));
  String _selectedEmoji = '🧳';

  static const List<String> _avatarOptions = ['🧳', '✈️', '🌍', '🧭', '🎒', '🏝️', '📸', '🗺️'];
  static const List<String> _popularCountries = ['ARG', 'USA', 'ESP', 'ITA', 'FRA', 'DEU', 'BRA', 'MEX', 'CHL', 'URY', 'COL', 'GBR'];

  @override
  void dispose() {
    _nameController.dispose();
    _natController.dispose();
    _passportNumController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 15)),
      helpText: 'Fecha de Vencimiento / Date of Expiry',
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submitProfile() {
    if (!_formKey.currentState!.validate()) return;

    final profile = TravelerProfile(
      fullName: _nameController.text.trim().toUpperCase(),
      nationality: _natController.text.trim().toUpperCase(),
      passportNumber: _passportNumController.text.trim().toUpperCase(),
      expiryDate: _expiryDate,
      avatarIcon: _selectedEmoji,
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
    );

    widget.storage.updateProfile(profile);
    HapticFeedback.heavyImpact();
    widget.onProfileComplete();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;

    final isSpanish = t.locale.languageCode == 'es';

    final title = isSpanish ? 'Emisión de Pasaporte' : 'Traveler Passport Issuance';
    final subtitle = isSpanish
        ? 'Bienvenido a EmpacArte. Completá tus datos de viajero para emitir tu pasaporte y comenzar a registrar tus viajes y valijas.'
        : 'Welcome to EmpacArte. Set up your traveler bio data to issue your passport and begin logging your journeys and luggage.';
    final expiryFormatted = DateFormat('dd MMM yyyy').format(_expiryDate).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Stamp Badge
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: goldAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: goldAccent, width: 2),
                    ),
                    child: Center(
                      child: Text(_selectedEmoji, style: const TextStyle(fontSize: 34)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.subheadSerif(color: goldAccent).copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: textSecondary).copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 24),

                // Passport Card Container
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpanish ? 'DATOS DEL TITULAR' : 'HOLDER BIO DATA',
                        style: AppTypography.monoCaption(color: goldAccent).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: isSpanish ? 'Nombre Completo' : 'Full Name',
                          hintText: 'e.g. ALEX SANTIAGO VOYAGER',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: goldAccent),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isSpanish ? 'Ingresá tu nombre completo' : 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nationality & Passport Number row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _natController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 3,
                              decoration: InputDecoration(
                                labelText: isSpanish ? 'País (3 letras)' : 'Country (3 letters)',
                                hintText: 'ARG',
                                counterText: '',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CountryHelper.buildFlag(_natController.text, width: 22, height: 15),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().length < 2) {
                                  return isSpanish ? 'Cód. país' : 'Country code';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _passportNumController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: isSpanish ? 'N° Pasaporte' : 'Passport No.',
                                hintText: 'AB123456',
                                prefixIcon: Icon(Icons.pin_outlined, color: goldAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return isSpanish ? 'Ingresá tu N°' : 'Enter number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Country Selector Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _popularCountries.map((c) {
                          final isSelected = _natController.text == c;
                          return InkWell(
                            onTap: () {
                              setState(() => _natController.text = c);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? goldAccent : goldAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? AppColors.darkBackground : Colors.white)
                                      : textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Expiry Date Picker Tile
                      InkWell(
                        onTap: _pickExpiryDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, color: goldAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSpanish ? 'Fecha de Vencimiento' : 'Date of Expiry',
                                      style: AppTypography.caption(color: textSecondary),
                                    ),
                                    Text(
                                      expiryFormatted,
                                      style: AppTypography.body(color: textPrimary).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Avatar Emoji Selector
                      Text(
                        isSpanish ? 'Ícono del Pasaporte' : 'Passport Emblem / Emoji',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _avatarOptions.map((e) {
                          final isSelected = _selectedEmoji == e;
                          return InkWell(
                            onTap: () => setState(() => _selectedEmoji = e),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? goldAccent.withValues(alpha: 0.25) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? goldAccent : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(e, style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _submitProfile,
                  icon: const Icon(Icons.verified_rounded, size: 20),
                  label: Text(
                    isSpanish ? 'Emitir Pasaporte & Continuar' : 'Issue Passport & Get Started',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
