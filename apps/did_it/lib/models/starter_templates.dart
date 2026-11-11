import 'package:uuid/uuid.dart';

import 'did_it_models.dart';

/// Curated bilingual starter templates users can import into Queue or Flows in one tap.
class StarterTemplate {
  const StarterTemplate({
    required this.key,
    required this.iconKey,
    required this.titleEn,
    required this.titleEs,
    required this.subtitleEn,
    required this.subtitleEs,
    required this.kind,
  });

  final String key;
  final String iconKey;
  final String titleEn;
  final String titleEs;
  final String subtitleEn;
  final String subtitleEs;
  final String kind; // 'flow' | 'chain' | 'item'

  String title(bool isEs) => isEs ? titleEs : titleEn;
  String subtitle(bool isEs) => isEs ? subtitleEs : subtitleEn;
}

abstract final class StarterTemplates {
  static const Uuid _uuid = Uuid();

  static const List<StarterTemplate> catalog = <StarterTemplate>[
    StarterTemplate(
      key: 'leaving_home',
      iconKey: 'lock',
      titleEn: 'Leaving Home Check',
      titleEs: 'Al salir de casa',
      subtitleEn: '4 steps · auto-resets after completion',
      subtitleEs: '4 pasos · reinicio automático al terminar',
      kind: 'flow',
    ),
    StarterTemplate(
      key: 'laundry_chain',
      iconKey: 'laundry',
      titleEn: 'Laundry Auto-Chain',
      titleEs: 'Cadena de Lavado',
      subtitleEn: 'Washer -> Dryer (55m) -> Fold (60m)',
      subtitleEs: 'Lavadora -> Secadora (55m) -> Doblar (60m)',
      kind: 'chain',
    ),
    StarterTemplate(
      key: 'dose_guard',
      iconKey: 'pill',
      titleEn: '8h Med / Vitamin Guard',
      titleEs: 'Dosis cada 8h (Anti-doble)',
      subtitleEn: 'Every 8h from done · 2h cooldown lock',
      subtitleEs: 'Cada 8h tras toma · bloqueo 2h',
      kind: 'item',
    ),
    StarterTemplate(
      key: 'pet_care',
      iconKey: 'pet',
      titleEn: 'Pet Care Daily Flow',
      titleEs: 'Cuidado de Mascota',
      subtitleEn: 'Food, fresh water & walk · resets daily',
      subtitleEs: 'Comida, agua fresca y paseo · diario',
      kind: 'flow',
    ),
    StarterTemplate(
      key: 'plant_water',
      iconKey: 'plant',
      titleEn: 'Plant Watering Cycle',
      titleEs: 'Riego de Plantas',
      subtitleEn: 'Every 4 days from last watered',
      subtitleEs: 'Cada 4 días desde el último riego',
      kind: 'item',
    ),
    StarterTemplate(
      key: 'ac_filter',
      iconKey: 'wrench',
      titleEn: 'Home Filter & Descale',
      titleEs: 'Filtro AC / Mantenimiento',
      subtitleEn: 'Every 90 days from completion',
      subtitleEs: 'Cada 90 días tras completar',
      kind: 'item',
    ),
  ];

  static TemplateBundle instantiate(
    String key, {
    required bool isEs,
    required DateTime now,
  }) {
    switch (key) {
      case 'leaving_home':
        final flowId = _uuid.v4();
        final flow = CheckFlow(
          id: flowId,
          title: isEs ? 'Al salir de casa' : 'Leaving Home Check',
          iconKey: 'lock',
          resetRule: FlowResetRule.onAllComplete,
          resetCooldownMinutes: 15,
        );
        final labels = isEs
            ? ['Apagar estufa / luces', 'Cerrar ventanas', 'Llevar llaves y billetera', 'Cerrar puerta principal']
            : ['Stove & appliances off', 'Windows closed', 'Grab keys & wallet', 'Front door locked'];
        final steps = <DidItItem>[];
        for (var i = 0; i < labels.length; i++) {
          steps.add(DidItItem(
            id: _uuid.v4(),
            title: labels[i],
            categoryIcon: 'lock',
            repeatMode: LoopRepeatMode.chainTriggered,
            flowId: flowId,
            flowOrder: i,
            notificationsEnabled: false,
          ));
        }
        return TemplateBundle(flow: flow, items: steps);

      case 'pet_care':
        final flowId = _uuid.v4();
        final flow = CheckFlow(
          id: flowId,
          title: isEs ? 'Cuidado de Mascota' : 'Pet Care Daily Flow',
          iconKey: 'pet',
          resetRule: FlowResetRule.scheduledDaily,
          resetHour: 6,
          resetMinute: 0,
        );
        final labels = isEs
            ? ['Desayuno y agua fresca', 'Paseo principal', 'Cena de mascota']
            : ['Breakfast & fresh water', 'Main walk', 'Evening dinner'];
        final steps = <DidItItem>[];
        for (var i = 0; i < labels.length; i++) {
          steps.add(DidItItem(
            id: _uuid.v4(),
            title: labels[i],
            categoryIcon: 'pet',
            repeatMode: LoopRepeatMode.fixedDaily,
            fixedHour: i == 0 ? 8 : (i == 1 ? 14 : 20),
            fixedMinute: 0,
            cooldownMinutes: 60,
            flowId: flowId,
            flowOrder: i,
          ));
        }
        return TemplateBundle(flow: flow, items: steps);

      case 'laundry_chain':
        final foldId = _uuid.v4();
        final dryerId = _uuid.v4();
        final washerId = _uuid.v4();
        return TemplateBundle(
          items: <DidItItem>[
            DidItItem(
              id: washerId,
              title: isEs ? 'Poner lavadora' : 'Start Washer',
              categoryIcon: 'laundry',
              repeatMode: LoopRepeatMode.fromLastDone,
              intervalMinutes: 4320,
              chainTargetItemId: dryerId,
              chainDelayMinutes: 55,
              nextDueAt: now,
            ),
            DidItItem(
              id: dryerId,
              title: isEs ? 'Pasar ropa a secadora' : 'Move Laundry to Dryer',
              categoryIcon: 'laundry',
              repeatMode: LoopRepeatMode.chainTriggered,
              chainTargetItemId: foldId,
              chainDelayMinutes: 60,
            ),
            DidItItem(
              id: foldId,
              title: isEs ? 'Doblar y guardar ropa' : 'Fold & Put Away',
              categoryIcon: 'laundry',
              repeatMode: LoopRepeatMode.chainTriggered,
            ),
          ],
        );

      case 'dose_guard':
        return TemplateBundle(
          items: <DidItItem>[
            DidItItem(
              id: _uuid.v4(),
              title: isEs ? 'Tomar dosis / vitamina' : 'Take Dose / Supplement',
              categoryIcon: 'pill',
              repeatMode: LoopRepeatMode.fromLastDone,
              intervalMinutes: 480,
              cooldownMinutes: 120,
              nextDueAt: now,
            ),
          ],
        );

      case 'plant_water':
        return TemplateBundle(
          items: <DidItItem>[
            DidItItem(
              id: _uuid.v4(),
              title: isEs ? 'Regar plantas de interior' : 'Water Indoor Plants',
              categoryIcon: 'plant',
              repeatMode: LoopRepeatMode.fromLastDone,
              intervalMinutes: 5760,
              nextDueAt: now,
            ),
          ],
        );

      case 'ac_filter':
      default:
        return TemplateBundle(
          items: <DidItItem>[
            DidItItem(
              id: _uuid.v4(),
              title: isEs ? 'Cambiar filtro de aire' : 'Replace AC / Home Filter',
              categoryIcon: 'wrench',
              repeatMode: LoopRepeatMode.fromLastDone,
              intervalMinutes: 129600,
              nextDueAt: now,
            ),
          ],
        );
    }
  }
}

class TemplateBundle {
  const TemplateBundle({this.flow, required this.items});

  final CheckFlow? flow;
  final List<DidItItem> items;
}
