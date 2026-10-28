import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _showMixMatrixSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _MixMatrixModal(),
    );
  }

  void _showFirstAidGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _FirstAidModal(),
    );
  }

  void _showHydrationGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _HydrationModal(),
    );
  }

  void _showRightsGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _RightsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Ayuda'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'GUÍAS DE CONSULTA RÁPIDA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón 1: Tabla de mezclas
              _buildGuideCard(
                context: context,
                title: 'Tabla de Mezclas e Interacciones',
                subtitle:
                    'Riesgos de combinar sustancias, sinergias y contraindicaciones.',
                icon: Icons.science_rounded,
                accentColor: primary,
                badgeText: 'CLÍNICA',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showMixMatrixSheet(context);
                },
              ),

              // Botón 2: Guía de atención
              _buildGuideCard(
                context: context,
                title: 'Guía de Atención y Primeros Auxilios',
                subtitle:
                    'Protocolo P.A.S., desescalada de mal viaje y signos de alarma roja.',
                icon: Icons.medical_services_rounded,
                accentColor: AppTheme.errorRed,
                badgeText: 'URGENCIAS',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFirstAidGuideSheet(context);
                },
              ),

              // Botón 3: Hidratación
              _buildGuideCard(
                context: context,
                title: 'Pautas de Hidratación y Descanso',
                subtitle:
                    'Consumo adecuado de líquidos, electrolitos y prevención de hipertermia.',
                icon: Icons.water_drop_rounded,
                accentColor: AppTheme.cyanAccent,
                badgeText: 'PREVENCIÓN',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showHydrationGuideSheet(context);
                },
              ),

              // Botón 4: Marco Legal
              _buildGuideCard(
                context: context,
                title: 'Marco Ético y Derechos del Usuario',
                subtitle:
                    'Confidencialidad, consentimiento y rol del voluntario en pista.',
                icon: Icons.gavel_rounded,
                accentColor: AppTheme.warningOrange,
                badgeText: 'LEGAL',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showRightsGuideSheet(context);
                },
              ),

              // Botón 5: Próximas guías
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.borderColor(context),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.post_add_rounded,
                      size: 24,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Más Guías Próximamente',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Análisis de sustancias con reactivos, protocolos de género y toxicología avanzada serán incorporados por el equipo.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modales de Guías Específicas
// ---------------------------------------------------------------------------

class _MixMatrixModal extends StatefulWidget {
  const _MixMatrixModal();

  @override
  State<_MixMatrixModal> createState() => _MixMatrixModalState();
}

class _MixMatrixModalState extends State<_MixMatrixModal> {
  String _sub1 = 'Alcohol';
  String _sub2 = 'MDMA';

  final List<String> _substances = const [
    'Alcohol',
    'MDMA',
    'Cannabis',
    'Ketamina',
    'Cocaína',
    'Benzodiacepinas',
    'LSD / Psilocibina',
  ];

  Map<String, dynamic> _getMixInfo(String s1, String s2) {
    if (s1 == s2) {
      return {
        'level': 'Misma sustancia',
        'color': AppTheme.cyanAccent,
        'desc':
            'Incrementar la dosis de la misma sustancia aumenta exponencialmente la tolerancia y toxicidad.',
      };
    }
    final pair = {s1.toLowerCase(), s2.toLowerCase()};

    if (pair.contains('alcohol') && pair.contains('benzodiacepinas')) {
      return {
        'level': 'PELIGRO EXTREMO',
        'color': AppTheme.errorRed,
        'desc':
            'Sinergia depresora del SNC. Alto riesgo de pérdida de conocimiento, depresión respiratoria, vómito sin reflejo de deglución y coma.',
      };
    }
    if (pair.contains('alcohol') && pair.contains('ketamina')) {
      return {
        'level': 'PELIGRO ALTO',
        'color': AppTheme.errorRed,
        'desc':
            'Riesgo agudo de sedación profunda, pérdida de motricidad, vómitos y accidentes graves.',
      };
    }
    if (pair.contains('alcohol') && pair.contains('cocaína')) {
      return {
        'level': 'ALTO RIESGO (Cocaetileno)',
        'color': AppTheme.errorRed,
        'desc':
            'El hígado sintetiza cocaetileno, metabólito significativamente más cardiotóxico que la cocaína sola. Aumenta riesgo de arritmias e infarto.',
      };
    }
    if (pair.contains('mdma') && pair.contains('cocaína')) {
      return {
        'level': 'RIESGOSA / CONTRAINDICADA',
        'color': AppTheme.warningOrange,
        'desc':
            'Ambas sobrecargan el sistema cardiovascular y la cocaína atenúa los efectos empáticos del MDMA, llevando a redosificar.',
      };
    }
    if (pair.contains('alcohol') && pair.contains('mdma')) {
      return {
        'level': 'PRECAUCIÓN',
        'color': AppTheme.warningOrange,
        'desc':
            'Potencia fuertemente la deshidratación y la hipertermia. El alcohol enmascara el efecto del MDMA y viceversa.',
      };
    }
    if (pair.contains('cannabis')) {
      return {
        'level': 'PRECAUCIÓN / POTENCIADOR',
        'color': AppTheme.warningOrange,
        'desc':
            'El cannabis suele potenciar de manera impredecible los efectos psicodélicos o disociativos de otras sustancias, pudiendo desencadenar pánico.',
      };
    }
    return {
      'level': 'PRECAUCIÓN GENERAL',
      'color': AppTheme.warningOrange,
      'desc':
          'Toda combinación de sustancias psicoactivas altera la farmacocinética esperada. Priorizar dosis mínimas y pausas.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mix = _getMixInfo(_sub1, _sub2);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Simulador de Mezclas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    style: AppTheme.headerIconButtonStyle(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Seleccioná dos sustancias para comprobar el nivel de interacción toxicológica:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor(ctx),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sub1,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Sustancia A'),
                      items: _substances
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sub1 = v);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.add_rounded, size: 20),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sub2,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Sustancia B'),
                      items: _substances
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sub2 = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (mix['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mix['color'] as Color, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mix['level'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: mix['color'] as Color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mix['desc'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: AppTheme.textPrimaryColor(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FirstAidModal extends StatelessWidget {
  const _FirstAidModal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Guía de Primeros Auxilios',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  style: AppTheme.headerIconButtonStyle(ctx),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: ctx,
              title: '1. PROTOCOLO P.A.S.',
              body:
                  '• PROTEGER: Evitar aglomeraciones, asegurar un área segura y ventilada.\n'
                  '• AVISAR: Contactar al coordinador de staff o ambulancia del evento.\n'
                  '• SOCORRER: Acompañar a la persona sin juzgarla ni dejarla sola.',
            ),
            _buildSection(
              context: ctx,
              title: '2. CONTENCIÓN DE MAL VIAJE / CRISIS DE PÁNICO',
              body:
                  '• Trasladar a un espacio con menos estímulos sonoros y lumínicos.\n'
                  '• Hablar con tono pausado, claro y empático. Recordar que el efecto es transitorio.\n'
                  '• Respiración guiada 4-7-8 (inhalar en 4 seg, retener 7, exhalar en 8).\n'
                  '• Ofrecer agua a pequeños sorbos.',
            ),
            _buildSection(
              context: ctx,
              title: '3. SIGNOS DE ALERTA ROJA (MÉDICO URGENTE)',
              body:
                  '• Pérdida de consciencia que no responde a estímulos.\n'
                  '• Temperatura corporal muy elevada (piel seca y caliente, sin sudoración).\n'
                  '• Convulsiones o rigidez muscular descontrolada.\n'
                  '• Dificultad severa para respirar o dolor agudo en el pecho.\n'
                  '-> Colocar en Posición Lateral de Seguridad (PLS) y llamar a la guardia médica de inmediato.',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String body,
  }) {
    final primary = AppTheme.primaryColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationModal extends StatelessWidget {
  const _HydrationModal();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pautas de Hidratación',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              IconButton(
                style: AppTheme.headerIconButtonStyle(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '• Bailando con actividad física o calor: Beber 1 vaso de agua (250 a 500 ml) por hora.\n'
            '• En descanso o reposo: Beber sólo a demanda (aprox 250 ml por hora).\n'
            '• ¡Atención con sobrehidratarse! Beber litros de agua de golpe sin sales puede inducir hiponatremia peligrosa.\n'
            '• Si la persona sudó en exceso, alternar con bebidas isotónicas o un snack salado.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RightsModal extends StatelessWidget {
  const _RightsModal();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Marco Ético de Staff',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              IconButton(
                style: AppTheme.headerIconButtonStyle(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '• Confidencialidad Absoluta: Todo lo conversado en la posta sanitaria de reducción de daños es privado.\n'
            '• Enfoque de Derechos: La persona que consume sustancias tiene derecho inalienable a la salud, respeto y trato digno.\n'
            '• Rol No Punitivo: El staff no sanciona ni confisca sustancias; nuestro único foco es la salud y el bienestar.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
