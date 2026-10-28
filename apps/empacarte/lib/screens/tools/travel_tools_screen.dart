import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_header_title.dart';
import '../../core/widgets/first_use_guide_card.dart';
import '../../core/widgets/tactile_pressable.dart';
import '../../repositories/storage_repository.dart';
import '../pro/pro_paywall_modal.dart';

class TravelToolsScreen extends StatefulWidget {
  final GuideController guideController;
  final StorageRepository? storage;

  const TravelToolsScreen({
    super.key,
    required this.guideController,
    this.storage,
  });

  @override
  State<TravelToolsScreen> createState() => _TravelToolsScreenState();
}

class _TravelToolsScreenState extends State<TravelToolsScreen> {
  // Currency Converter State
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';

  // Personal Offline Vault State
  final _insuranceController = TextEditingController();
  final _insurancePhoneController = TextEditingController();
  final _hotelAddressController = TextEditingController();

  static const Map<String, double> _ratesToUsd = {
    'USD': 1.0,
    'EUR': 1.08,
    'GBP': 1.28,
    'JPY': 0.0068,
    'ARS': 0.00098,
    'BRL': 0.18,
  };

  @override
  void initState() {
    super.initState();
    _loadVaultData();
  }

  Future<void> _loadVaultData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _insuranceController.text = prefs.getString('empacarte_vault_insurance') ?? '';
      _insurancePhoneController.text = prefs.getString('empacarte_vault_phone') ?? '';
      _hotelAddressController.text = prefs.getString('empacarte_vault_hotel') ?? '';
    });
  }

  Future<void> _saveVaultData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('empacarte_vault_insurance', _insuranceController.text.trim());
    await prefs.setString('empacarte_vault_phone', _insurancePhoneController.text.trim());
    await prefs.setString('empacarte_vault_hotel', _hotelAddressController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bóveda privada de viaje guardada 100% offline')),
      );
    }
  }

  double get _convertedAmount {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final fromRate = _ratesToUsd[_fromCurrency] ?? 1.0;
    final toRate = _ratesToUsd[_toCurrency] ?? 1.0;
    return (amount * fromRate) / toRate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _insuranceController.dispose();
    _insurancePhoneController.dispose();
    _hotelAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpanish = t.locale.languageCode == 'es';
    final isPro = widget.storage?.isPro ?? false;

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    final now = DateTime.now();
    final localTimeFormatted = DateFormat('HH:mm').format(now);
    final tokyoTimeFormatted = DateFormat('HH:mm').format(now.toUtc().add(const Duration(hours: 9)));

    return Scaffold(
      appBar: AppBar(
        title: AppHeaderTitle(
          title: t.t('tools_title'),
          isPro: isPro,
        ),
        actions: [
          if (!isPro && widget.storage != null)
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'EmpacArte PRO',
              onPressed: () => ProPaywallModal.show(context, widget.storage!),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.guideController.shouldShowGuide(GuideController.toolsGuide))
            FirstUseGuideCard(
              icon: Icons.workspaces_outline,
              title: isSpanish ? 'Bolsillo de Herramientas de Viaje' : 'Traveler Pocket Toolkit',
              description: isSpanish
                  ? 'Utilidades esenciales 100% offline para resolver situaciones frecuentes durante tus travesías.'
                  : 'Essential 100% offline travel utilities to handle common situations on the road.',
              bulletPoints: isSpanish
                  ? [
                      'Conversor de divisas instantáneo sin necesidad de internet o roaming.',
                      'Reloj comparador con el huso horario de tu origen y destino.',
                      'Normas de seguridad aeroportuaria y bóveda médica offline.',
                    ]
                  : [
                      'Instant offline currency converter requiring zero internet or roaming data.',
                      'Dual timezone comparison clock between origin and destination.',
                      'Airport security liquid & battery rules with offline travel vault.',
                    ],
              onDismiss: () => widget.guideController.markGuideSeen(GuideController.toolsGuide),
            ),

          // --- 1. AIRPORT SECURITY & TSA / IATA RULES (CRITICAL TRAVEL UTILITY) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldFoil.withValues(alpha: 0.5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, color: goldAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isSpanish ? 'Seguridad Aeroportuaria (TSA / IATA)' : 'Airport Security & TSA Rules',
                      style: AppTypography.subheadSerif(color: goldAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SecurityRuleTile(
                  icon: Icons.water_drop_outlined,
                  title: isSpanish ? 'Líquidos en Cabina (Regla 3-1-1)' : 'Liquids in Cabin (3-1-1 Rule)',
                  description: isSpanish
                      ? 'Máximo 100 ml (3.4 oz) por envase. Todos deben caber en una única bolsa transparente de 1 litro.'
                      : 'Max 100 ml (3.4 oz) per bottle. All must fit inside a single clear 1-quart/liter plastic zip bag.',
                  isDark: isDark,
                  badgeColor: AppColors.stampEmeraldLight,
                  badgeText: isSpanish ? 'PERMITIDO < 100ml' : 'ALLOWED < 100ml',
                ),
                const SizedBox(height: 8),
                _SecurityRuleTile(
                  icon: Icons.battery_charging_full_rounded,
                  title: isSpanish ? 'Baterías y Powerbanks' : 'Lithium Batteries & Powerbanks',
                  description: isSpanish
                      ? '¡OBLIGATORIO en equipaje de mano! Prohibido en bodega por riesgo de incendio (IATA).'
                      : 'MANDATORY in hand luggage! Strictly prohibited in checked luggage due to fire hazards (IATA).',
                  isDark: isDark,
                  badgeColor: AppColors.stampCrimsonLight,
                  badgeText: isSpanish ? 'SOLO EN MANO' : 'CABIN ONLY',
                ),
                const SizedBox(height: 8),
                _SecurityRuleTile(
                  icon: Icons.content_cut_rounded,
                  title: isSpanish ? 'Objetos Cortantes y Aerosoles' : 'Sharp Objects & Large Sprays',
                  description: isSpanish
                      ? 'Tijeras > 6cm, navajas, alicates y aerosoles grandes deben ir SIEMPRE despachados en bodega.'
                      : 'Scissors > 6cm, pocket knives, corkscrews and large sprays must ALWAYS be checked in.',
                  isDark: isDark,
                  badgeColor: AppColors.goldFoilDark,
                  badgeText: isSpanish ? 'SOLO EN BODEGA' : 'CHECKED ONLY',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- 2. OFFLINE CURRENCY CONVERTER ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.currency_exchange_rounded, color: goldAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      t.t('tools_currency_title'),
                      style: AppTypography.subheadSerif(color: goldAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('tools_currency_sub'),
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: 16),

                // Amount input
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t.t('tools_currency_amount'),
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // From / To Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fromCurrency,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _ratesToUsd.keys.map((curr) {
                          return DropdownMenuItem(value: curr, child: Text(curr));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _fromCurrency = val);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_rounded),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _toCurrency,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _ratesToUsd.keys.map((curr) {
                          return DropdownMenuItem(value: curr, child: Text(curr));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _toCurrency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Result Box
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.t('tools_currency_result'), style: AppTypography.body(color: textSecondary)),
                      Text(
                        '${_convertedAmount.toStringAsFixed(2)} $_toCurrency',
                        style: AppTypography.monoBody(color: goldAccent, medium: true).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- 3. DUAL TIMEZONE COMPARISON ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: goldAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      t.t('tools_time_title'),
                      style: AppTypography.subheadSerif(color: goldAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('tools_time_sub'),
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(t.t('tools_time_home'), style: AppTypography.caption(color: textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              localTimeFormatted,
                              style: AppTypography.monoBody(color: textPrimary, medium: true).copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('TOKYO (UTC+9)', style: AppTypography.caption(color: textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              tokyoTimeFormatted,
                              style: AppTypography.monoBody(color: goldAccent, medium: true).copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- 4. PERSONAL OFFLINE TRAVEL VAULT (INSURANCE & HOTEL) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: AppColors.stampCrimsonLight, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isSpanish ? 'Bóveda Offline de Asistencia Médica & Hotel' : 'Offline Medical & Hotel Vault',
                      style: AppTypography.subheadSerif(color: AppColors.stampCrimsonLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isSpanish
                      ? 'Datos críticos accesibles sin conexión para formularios de migraciones o emergencias.'
                      : 'Critical offline data for border customs arrival cards and medical emergencies.',
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _insuranceController,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Póliza de Asistencia al Viajero / Seguro' : 'Travel Insurance Policy No.',
                    prefixIcon: const Icon(Icons.health_and_safety_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _insurancePhoneController,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Teléfono 24h de Asistencia Médica' : '24h Emergency Medical Assistance Phone',
                    prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _hotelAddressController,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Dirección del Primer Alojamiento' : 'First Hotel / Accommodation Address',
                    prefixIcon: const Icon(Icons.home_work_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.goldFoil : AppColors.burgundyBase,
                    foregroundColor: isDark ? AppColors.textDarkPrimary : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveVaultData,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(isSpanish ? 'Guardar en Dispositivo' : 'Save Locally on Device'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- 5. EMERGENCY CALL NUMBERS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: AppColors.stampCrimsonLight, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      t.t('tools_vault_title'),
                      style: AppTypography.subheadSerif(color: AppColors.stampCrimsonLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('tools_vault_sub'),
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: 12),

                _EmergencyTile(
                  title: t.t('tools_emergency_police'),
                  number: '112 / 911',
                  isDark: isDark,
                  onCopy: () {
                    Clipboard.setData(const ClipboardData(text: '112'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied 112 to clipboard')));
                  },
                ),
                const SizedBox(height: 8),
                _EmergencyTile(
                  title: t.t('tools_emergency_medical'),
                  number: '107 / 999',
                  isDark: isDark,
                  onCopy: () {
                    Clipboard.setData(const ClipboardData(text: '107'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied 107 to clipboard')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SecurityRuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final Color badgeColor;
  final String badgeText;

  const _SecurityRuleTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    required this.badgeColor,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: badgeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                          medium: true,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTypography.caption(color: badgeColor, medium: true).copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.caption(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final String title;
  final String number;
  final bool isDark;
  final VoidCallback onCopy;

  const _EmergencyTile({
    required this.title,
    required this.number,
    required this.isDark,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.body(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary, medium: true)),
            Row(
              children: [
                Text(number, style: AppTypography.monoCaption(color: AppColors.stampCrimsonLight, medium: true)),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, size: 16, color: AppColors.stampCrimsonLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
