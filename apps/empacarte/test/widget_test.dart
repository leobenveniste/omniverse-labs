import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:empacarte/core/localization/app_localizations.dart';
import 'package:empacarte/models/collectible_stamp.dart';
import 'package:empacarte/models/packing_item.dart';
import 'package:empacarte/models/traveler_profile.dart';
import 'package:empacarte/models/trip.dart';
import 'package:empacarte/models/trip_leg.dart';
import 'package:empacarte/repositories/packing_presets.dart';

void main() {
  group('EmpacArte Core Logic Tests', () {
    test('TravelerProfile default and MRZ formatting', () {
      final profile = TravelerProfile.defaultProfile();
      expect(profile.fullName, 'ALEX VOYAGER');
      expect(profile.nationality, 'ARG');
      expect(profile.isExpiringSoon, isFalse);
      expect(profile.isConfigured, isTrue);

      final mrz = profile.formattedMrz;
      expect(mrz.contains('P<ARGALEX<VOYAGER'), isTrue);
      expect(mrz.contains('PA984721'), isTrue);
    });

    test('TravelerProfile empty state is not configured', () {
      final emptyProfile = TravelerProfile.empty();
      expect(emptyProfile.fullName, '');
      expect(emptyProfile.passportNumber, '');
      expect(emptyProfile.isConfigured, isFalse);
    });

    test('Trip departure countdown and computed properties', () {
      final now = DateTime.now();
      final trip = Trip(
        id: 'test_trip_1',
        destination: 'Tokyo, Japan',
        originCode: 'EZE',
        destinationCode: 'HND',
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        travelMode: TravelMode.flight,
        purpose: TripPurpose.vacation,
      );

      expect(trip.daysUntilDeparture, 10);
      expect(trip.isDepartsToday, isFalse);
      expect(trip.isPast, isFalse);
    });

    test('PackingPresets generates items for all 3 bags', () {
      final items = PackingPresets.generateSmartList(
        tripId: 'smart_trip',
        purpose: TripPurpose.vacation,
        durationDays: 7,
      );

      expect(items.isNotEmpty, isTrue);

      final personalItems = items.where((i) => i.compartment == BagCompartment.personalItem);
      final carryOnItems = items.where((i) => i.compartment == BagCompartment.carryOn);

      expect(personalItems.isNotEmpty, isTrue);
      expect(carryOnItems.isNotEmpty, isTrue);
    });

    test('TripLeg and multi-destination itinerary support', () {
      final now = DateTime.now();
      final leg1 = TripLeg(
        id: 'leg_1',
        destination: 'Roma, Italia',
        destinationCode: 'FCO',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 9)),
        climate: DestinationClimate.warm,
        hotelName: 'Hotel Quirinale',
        checkInTime: '14:00',
        checkOutTime: '11:00',
      );

      final leg2 = TripLeg(
        id: 'leg_2',
        destination: 'Florencia, Italia',
        destinationCode: 'FLR',
        startDate: now.add(const Duration(days: 9)),
        endDate: now.add(const Duration(days: 14)),
        climate: DestinationClimate.cold,
        hotelName: 'Hotel Santa Maria Novella',
        checkInTime: '15:00',
        checkOutTime: '10:30',
      );

      final trip = Trip(
        id: 'multi_trip',
        destination: 'Roma, Italia',
        destinationCode: 'FCO',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 14)),
        legs: [leg1, leg2],
      );

      expect(trip.isMultiDestination, isTrue);
      expect(trip.routeDisplay, 'Roma ➔ Florencia');
      expect(trip.allClimates.contains(DestinationClimate.warm), isTrue);
      expect(trip.allClimates.contains(DestinationClimate.cold), isTrue);

      // Verify serialization round-trip
      final json = trip.toJson();
      final restored = Trip.fromJson(json);
      expect(restored.isMultiDestination, isTrue);
      expect(restored.legs.length, 2);
      expect(restored.legs.first.hotelName, 'Hotel Quirinale');

      // Test multi-climate packing aggregation
      final multiItems = PackingPresets.generateSmartList(
        tripId: trip.id,
        purpose: TripPurpose.vacation,
        durationDays: trip.durationDays,
        climates: trip.allClimates,
      );

      // Should contain both warm and cold clothes without crashing
      final hasWarmItem = multiItems.any((i) => i.name.toLowerCase().contains('sunscreen') || i.name.toLowerCase().contains('swimsuit') || i.name.toLowerCase().contains('protector'));
      final hasColdItem = multiItems.any((i) => i.name.toLowerCase().contains('parka') || i.name.toLowerCase().contains('coat') || i.name.toLowerCase().contains('campera'));
      expect(hasWarmItem, isTrue);
      expect(hasColdItem, isTrue);
    });

    test('CollectibleStamp serialization and types', () {
      final stamp = CollectibleStamp(
        id: 'stamp_1',
        tripId: 'trip_1',
        cityName: 'ROME',
        countryCode: 'ITA',
        stationCode: 'FCO',
        date: DateTime(2026, 9, 5),
        shape: StampShape.hexagonal,
        inkColor: StampInkColor.crimson,
        rotationRadians: 0.04,
        type: StampType.entry,
      );

      final json = stamp.toJson();
      final reconstructed = CollectibleStamp.fromJson(json);

      expect(reconstructed.cityName, 'ROME');
      expect(reconstructed.shape, StampShape.hexagonal);
      expect(reconstructed.inkColor, StampInkColor.crimson);
      expect(reconstructed.type, StampType.entry);
    });

    test('All 6 languages contain core translation keys', () {
      final languages = ['en', 'es', 'it', 'fr', 'pt', 'de'];
      const testKeys = [
        'app_name',
        'nav_passport',
        'nav_trips',
        'nav_packing',
        'nav_tools',
        'nav_settings',
        'passport_title',
        'stamp_customs_cleared',
        'pack_cleared_badge',
      ];

      for (final lang in languages) {
        final loc = AppLocalizations(Locale(lang));
        for (final key in testKeys) {
          final translation = loc.t(key);
          expect(translation, isNotEmpty, reason: 'Key $key missing in $lang');
          expect(translation, isNot(equals(key)), reason: 'Key $key fell back to raw key in $lang');
        }
      }
    });

    test('TravelerProfile.fromJson with empty payload gives unconfigured profile', () {
      final parsed = TravelerProfile.fromJson({});
      expect(parsed.fullName, '');
      expect(parsed.passportNumber, '');
      expect(parsed.isConfigured, isFalse);
    });
  });
}
