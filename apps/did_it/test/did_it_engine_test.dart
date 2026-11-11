import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:did_it/models/did_it_models.dart';
import 'package:did_it/services/automation_engine.dart';
import 'package:did_it/services/did_it_controller.dart';
import 'package:did_it/services/did_it_scheduler.dart';
import 'package:did_it/services/did_it_storage.dart';

void main() {
  group('AutomationEngine schedule math & chains', () {
    test('computes fromLastDone nextDueAt strictly from completion timestamp', () {
      const item = DidItItem(
        id: 'dose-1',
        title: 'Take Dose',
        repeatMode: LoopRepeatMode.fromLastDone,
        intervalMinutes: 480,
      );
      final doneAt = DateTime(2026, 11, 11, 14, 20);
      final next = AutomationEngine.computeNextDueAt(item, doneAt);
      expect(next, DateTime(2026, 11, 11, 22, 20));
    });

    test('rolls monthly fixed schedule safely across short months', () {
      const item = DidItItem(
        id: 'rent',
        title: 'Filter / Rent Check',
        repeatMode: LoopRepeatMode.fixedMonthly,
        monthDay: 31,
        fixedHour: 9,
        fixedMinute: 30,
      );
      final jan31 = DateTime(2026, 1, 31, 10, 0);
      final next = AutomationEngine.computeNextDueAt(item, jan31);
      expect(next, DateTime(2026, 2, 28, 9, 30));
    });

    test('applies chained downstream trigger with configured delay', () {
      final now = DateTime(2026, 11, 11, 18, 0);
      const washer = DidItItem(
        id: 'wash',
        title: 'Wash Clothes',
        repeatMode: LoopRepeatMode.fromLastDone,
        intervalMinutes: 4320,
        chainTargetItemId: 'dry',
        chainDelayMinutes: 55,
      );
      const dryer = DidItItem(
        id: 'dry',
        title: 'Move to Dryer',
        repeatMode: LoopRepeatMode.chainTriggered,
      );

      final result = AutomationEngine.applyCompletion(
        items: const <DidItItem>[washer, dryer],
        flows: const <CheckFlow>[],
        itemId: 'wash',
        now: now,
        eventId: 'ev-1',
      );

      final updatedWash = result.items.firstWhere((i) => i.id == 'wash');
      final updatedDry = result.items.firstWhere((i) => i.id == 'dry');
      expect(updatedWash.lastDoneAt, now);
      expect(updatedWash.nextDueAt, now.add(const Duration(minutes: 4320)));
      expect(updatedDry.nextDueAt, now.add(const Duration(minutes: 55)));
      expect(result.rescheduleItemIds, containsAll(<String>['wash', 'dry']));
      expect(result.triggeredChainTitle, 'Move to Dryer');
    });

    test('detects active cooldown window to block accidental double taps', () {
      final doneAt = DateTime(2026, 11, 11, 10, 0);
      final item = DidItItem(
        id: 'med',
        title: 'Ibuprofen',
        cooldownMinutes: 120,
        lastDoneAt: doneAt,
      );

      expect(
        AutomationEngine.isInCooldown(item, DateTime(2026, 11, 11, 11, 30)),
        isTrue,
      );
      expect(
        AutomationEngine.isInCooldown(item, DateTime(2026, 11, 11, 12, 0)),
        isFalse,
      );
    });

    test('auto-resets CheckFlow steps on immediate onAllComplete', () {
      final now = DateTime(2026, 11, 11, 8, 15);
      const flow = CheckFlow(
        id: 'f1',
        title: 'Leaving Home',
        resetRule: FlowResetRule.onAllComplete,
        resetCooldownMinutes: 0,
      );
      const s1 = DidItItem(
        id: 's1',
        title: 'Stove off',
        repeatMode: LoopRepeatMode.chainTriggered,
        flowId: 'f1',
        flowOrder: 0,
        flowStepChecked: true,
      );
      const s2 = DidItItem(
        id: 's2',
        title: 'Lock door',
        repeatMode: LoopRepeatMode.chainTriggered,
        flowId: 'f1',
        flowOrder: 1,
        flowStepChecked: false,
      );

      final result = AutomationEngine.applyCompletion(
        items: const <DidItItem>[s1, s2],
        flows: const <CheckFlow>[flow],
        itemId: 's2',
        now: now,
        eventId: 'ev-flow',
        source: 'flow',
      );

      expect(result.flows.first.completedRuns, 1);
      expect(result.items.every((s) => !s.flowStepChecked), isTrue);
    });
  });

  group('DidItController persistence, cooldown & undo', () {
    test('blocks cooldown tap unless forced and supports full undo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = await DidItStorage.open();
      var currentTime = DateTime(2026, 11, 11, 9, 0);
      final scheduler = NoopDidItScheduler();
      final controller = DidItController(
        storage: storage,
        scheduler: scheduler,
        clock: () => currentTime,
      );
      await controller.initialize();

      const custom = DidItItem(
        id: 'pill-test',
        title: 'Vitamin D',
        repeatMode: LoopRepeatMode.fromLastDone,
        intervalMinutes: 1440,
        cooldownMinutes: 60,
      );
      await controller.saveItem(custom);

      final firstRes = await controller.markDone('pill-test');
      expect(firstRes, isNotNull);
      expect(controller.history.first.itemTitle, 'Vitamin D');

      // Within 60m cooldown -> blocked by default
      currentTime = currentTime.add(const Duration(minutes: 20));
      final blockedRes = await controller.markDone('pill-test');
      expect(blockedRes, isNull);

      // Undo restores prior state & removes event
      final undone = await controller.undoCompletion(firstRes!.event.id);
      expect(undone, isTrue);
      final restored = controller.items.firstWhere((i) => i.id == 'pill-test');
      expect(restored.lastDoneAt, isNull);
      expect(controller.history.where((h) => h.itemId == 'pill-test'), isEmpty);

      controller.dispose();
    });
  });
}
