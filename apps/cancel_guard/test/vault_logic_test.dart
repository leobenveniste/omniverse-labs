import 'package:cancel_guard/models/common_services.dart';
import 'package:cancel_guard/models/guarded_item.dart';
import 'package:cancel_guard/services/alert_scheduler.dart';
import 'package:cancel_guard/services/vault_controller.dart';
import 'package:cancel_guard/services/vault_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GuardedItem & catalog domain logic', () {
    final now = DateTime(2026, 11, 11, 12, 0);

    GuardedItem makeItem({
      required DateTime chargeAt,
      ItemKind kind = ItemKind.trial,
      BillingCycle cycle = BillingCycle.monthly,
      AlertPreset preset = AlertPreset.buffer48And24,
      double amount = 19.99,
    }) {
      return GuardedItem(
        id: 'item-1',
        name: 'Adobe Creative Cloud',
        amount: amount,
        kind: kind,
        billingCycle: cycle,
        chargeAt: chargeAt,
        alertPreset: preset,
        status: ItemStatus.active,
        createdAt: now.subtract(const Duration(days: 1)),
      );
    }

    test('contains 50 common services and leaves cancelUrl empty by default', () {
      expect(kCommonServices.length, 50);
      final item = makeItem(chargeAt: now.add(const Duration(days: 5)));
      expect(item.cancelUrl, '');
    });

    test('classifies urgency levels accurately across 24h and 48h thresholds', () {
      expect(
        makeItem(chargeAt: now.subtract(const Duration(minutes: 1)))
            .urgencyAt(now),
        UrgencyLevel.expired,
      );
      expect(
        makeItem(chargeAt: now.add(const Duration(hours: 12))).urgencyAt(now),
        UrgencyLevel.urgent24h,
      );
      expect(
        makeItem(chargeAt: now.add(const Duration(hours: 36))).urgencyAt(now),
        UrgencyLevel.warning48h,
      );
      expect(
        makeItem(chargeAt: now.add(const Duration(hours: 72))).urgencyAt(now),
        UrgencyLevel.safe,
      );
    });

    test('computes dual-stage alert timestamps accurately', () {
      final chargeAt = DateTime(2026, 11, 20, 10, 0);
      final item = makeItem(
        chargeAt: chargeAt,
        preset: AlertPreset.buffer48And24,
      );
      final alerts = item.scheduledAlertTimes();
      expect(alerts, [
        DateTime(2026, 11, 18, 10, 0),
        DateTime(2026, 11, 19, 10, 0),
      ]);
    });

    test('advances past-due recurring subscriptions without advancing trials', () {
      final pastDue = now.subtract(const Duration(days: 2));
      final trial = makeItem(chargeAt: pastDue, kind: ItemKind.trial);
      expect(trial.advanceRecurringIfDue(now).chargeAt, pastDue);

      final monthly = makeItem(
        chargeAt: pastDue,
        kind: ItemKind.recurring,
        cycle: BillingCycle.monthly,
      );
      final rolledMonthly = monthly.advanceRecurringIfDue(now);
      expect(rolledMonthly.chargeAt.isAfter(now), isTrue);
      expect(rolledMonthly.chargeAt.month, 12);
    });
  });

  group('VaultController ROI, preferences & scheduling', () {
    test('adds trial without default cancel link, banks ROI, and persists settings',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await VaultStorage.open();
      final scheduler = NoopAlertScheduler();
      final fixedNow = DateTime(2026, 11, 11, 12, 0);

      final controller = VaultController(
        storage: storage,
        scheduler: scheduler,
        clock: () => fixedNow,
      );
      await controller.initialize();

      expect(controller.activeItems, isEmpty);
      expect(controller.totalSaved, 0.0);
      expect(controller.themeMode, ThemeMode.dark);

      final item = await controller.addItem(
        name: 'Netflix',
        amount: 15.49,
        kind: ItemKind.trial,
        billingCycle: BillingCycle.monthly,
        chargeAt: fixedNow.add(const Duration(hours: 30)),
        alertPreset: AlertPreset.buffer48And24,
      );

      expect(item.cancelUrl, '');
      expect(controller.activeItems.length, 1);
      expect(controller.urgentActiveItems.length, 1);
      expect(controller.atRiskNext30Days, closeTo(15.49, 0.001));
      expect(scheduler.scheduledIds.contains(item.id), isTrue);

      await controller.markCancelled(item.id);
      expect(controller.activeItems, isEmpty);
      expect(controller.historyItems.length, 1);
      expect(controller.totalSaved, closeTo(15.49, 0.001));
      expect(scheduler.scheduledIds.contains(item.id), isFalse);

      await controller.restoreItem(item.id);
      expect(controller.activeItems.length, 1);
      expect(controller.totalSaved, 0.0);

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
    });
  });
}
