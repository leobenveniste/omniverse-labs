import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/collectible_stamp.dart';
import '../models/packing_item.dart';
import '../models/traveler_profile.dart';
import '../models/trip.dart';
import 'packing_presets.dart';

class StorageRepository extends ChangeNotifier {
  static const String _keyProfile = 'empacarte_profile';
  static const String _keyTrips = 'empacarte_trips';
  static const String _keyItems = 'empacarte_packing_items';
  static const String _keyStamps = 'empacarte_stamps';
  static const String _keyPro = 'empacarte_is_pro';
  static const String _keyAlwaysPack = 'empacarte_always_pack_items';

  static const _uuid = Uuid();

  TravelerProfile _profile = TravelerProfile.empty();
  List<Trip> _trips = [];
  List<PackingItem> _items = [];
  List<CollectibleStamp> _stamps = [];
  List<String> _alwaysPackItems = [];
  bool _isPro = false;
  bool _isLoaded = false;

  TravelerProfile get profile => _profile;
  List<Trip> get trips => List.unmodifiable(_trips);
  List<PackingItem> get items => List.unmodifiable(_items);
  List<CollectibleStamp> get stamps => List.unmodifiable(_stamps);
  List<String> get alwaysPackItems => List.unmodifiable(_alwaysPackItems);
  bool get isPro => _isPro;
  bool get isLoaded => _isLoaded;

  // --- Freemium Limits ---
  int get maxFreeActiveTrips => 1;
  int get maxFreeTotalTrips => 3;
  int get maxFreeAlwaysPackItems => 3;

  List<Trip> get activeTrips => _trips.where((t) => !t.isPast).toList();

  List<Trip> get upcomingTrips {
    final list = _trips.where((t) => !t.isPast).toList();
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
    return list;
  }

  List<Trip> get pastTrips {
    final list = _trips.where((t) => t.isPast).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  bool get canCreateTrip =>
      _isPro || (activeTrips.length < maxFreeActiveTrips && _trips.length < maxFreeTotalTrips);

  String? get tripCreationBlockReason {
    if (_isPro) return null;
    if (activeTrips.length >= maxFreeActiveTrips) {
      return 'Límite alcanzado: Ya tienes 1 viaje activo. Desbloquea EmpacArte PRO para viajes ilimitados.';
    }
    if (_trips.length >= maxFreeTotalTrips) {
      return 'Límite alcanzado: Has alcanzado el máximo de 3 viajes históricos. Desbloquea EmpacArte PRO para continuar.';
    }
    return null;
  }

  bool get canAddAlwaysPackItem => _isPro || _alwaysPackItems.length < maxFreeAlwaysPackItems;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Profile
    final profileJson = prefs.getString(_keyProfile);
    if (profileJson != null) {
      try {
        _profile = TravelerProfile.fromJson(jsonDecode(profileJson));
      } catch (e) {
        _profile = TravelerProfile.empty();
      }
    } else {
      _profile = TravelerProfile.empty();
    }

    // 2. Trips
    final tripsJson = prefs.getString(_keyTrips);
    if (tripsJson != null) {
      try {
        final list = jsonDecode(tripsJson) as List;
        _trips = list.map((e) => Trip.fromJson(e)).toList();
      } catch (e) {
        _trips = [];
      }
    }

    // 3. Items
    final itemsJson = prefs.getString(_keyItems);
    if (itemsJson != null) {
      try {
        final list = jsonDecode(itemsJson) as List;
        _items = list.map((e) => PackingItem.fromJson(e)).toList();
      } catch (e) {
        _items = [];
      }
    }

    // 4. Stamps
    final stampsJson = prefs.getString(_keyStamps);
    if (stampsJson != null) {
      try {
        final list = jsonDecode(stampsJson) as List;
        _stamps = list.map((e) => CollectibleStamp.fromJson(e)).toList();
      } catch (e) {
        _stamps = [];
      }
    }

    // 5. PRO Status & Always Pack
    _isPro = prefs.getBool(_keyPro) ?? false;
    _alwaysPackItems = prefs.getStringList(_keyAlwaysPack) ?? [
      'Cepillo de dientes',
      'Cargador de celular',
      'Documentos / Pasaporte',
    ];

    _isLoaded = true;
    notifyListeners();
  }

  // --- PRO Operations ---
  Future<void> unlockPro() async {
    await setPro(true);
  }

  Future<void> setPro(bool isPro) async {
    _isPro = isPro;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPro, isPro);
  }

  Future<bool> shouldShowDailyPromo() async {
    if (_isPro) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastTimestamp = prefs.getInt('last_pro_promo_timestamp');
    final now = DateTime.now().millisecondsSinceEpoch;
    const fourDaysMs = 4 * 24 * 60 * 60 * 1000;
    return lastTimestamp == null || (now - lastTimestamp) >= fourDaysMs;
  }

  Future<void> markDailyPromoSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('last_pro_promo_timestamp', now);
  }

  // --- Always Pack Operations ---
  Future<void> toggleAlwaysPack(String itemName, bool always) async {
    final normalized = itemName.trim();
    if (normalized.isEmpty) return;

    if (always) {
      if (!_alwaysPackItems.contains(normalized)) {
        _alwaysPackItems.add(normalized);
      }
    } else {
      _alwaysPackItems.remove(normalized);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAlwaysPack, _alwaysPackItems);
  }

  // --- Profile Operations ---
  Future<void> updateProfile(TravelerProfile updated) async {
    _profile = updated;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(_profile.toJson()));
  }

  // --- Trip Operations ---
  Future<void> addTrip(Trip trip, [List<PackingItem>? customItems]) async {
    _trips.insert(0, trip);

    if (customItems != null && customItems.isNotEmpty) {
      _items.addAll(customItems);
    } else {
      final newItems = PackingPresets.generateSmartList(
        tripId: trip.id,
        purpose: trip.purpose,
        durationDays: trip.durationDays,
        climate: trip.climate,
        climates: trip.allClimates,
        alwaysPackItemNames: _alwaysPackItems,
      );
      _items.addAll(newItems);
    }

    // Stamp arrival visa in album for all stops/legs (or main destination)
    if (trip.legs.isNotEmpty) {
      for (final leg in trip.legs) {
        final stamp = CollectibleStamp(
          id: _uuid.v4(),
          tripId: trip.id,
          cityName: leg.destination.split(',').first.trim().toUpperCase(),
          countryCode: leg.destinationCode,
          stationCode: leg.destinationCode,
          date: leg.startDate,
          shape: _randomShape(_stamps.length),
          inkColor: _randomInk(_stamps.length),
          rotationRadians: (_stamps.length % 2 == 0 ? 0.04 : -0.05),
          type: StampType.entry,
        );
        _stamps.insert(0, stamp);
      }
    } else {
      final stamp = CollectibleStamp(
        id: _uuid.v4(),
        tripId: trip.id,
        cityName: trip.destination.split(',').first.trim().toUpperCase(),
        countryCode: trip.destinationCode,
        stationCode: trip.destinationCode,
        date: trip.startDate,
        shape: _randomShape(_stamps.length),
        inkColor: _randomInk(_stamps.length),
        rotationRadians: (_stamps.length % 2 == 0 ? 0.04 : -0.05),
        type: StampType.entry,
      );
      _stamps.insert(0, stamp);
    }

    notifyListeners();
    await _persistAll();
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    final idx = _trips.indexWhere((t) => t.id == updatedTrip.id);
    if (idx != -1) {
      _trips[idx] = updatedTrip;
      notifyListeners();
      await _persistAll();
    }
  }

  StampShape _randomShape(int index) {
    return StampShape.values[index % StampShape.values.length];
  }

  StampInkColor _randomInk(int index) {
    return StampInkColor.values[index % StampInkColor.values.length];
  }

  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((t) => t.id == tripId);
    _items.removeWhere((item) => item.tripId == tripId);
    notifyListeners();
    await _persistAll();
  }

  // --- Packing Item Operations ---
  List<PackingItem> getItemsForTrip(String tripId) {
    return _items.where((i) => i.tripId == tripId).toList();
  }

  Future<void> toggleItemPacked(String itemId) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final current = _items[index];
    _items[index] = current.copyWith(isPacked: !current.isPacked);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyItems, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> addPackingItem(PackingItem item) async {
    _items.add(item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyItems, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> deletePackingItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyItems, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> addCustomsClearedStamp(String tripId, String destinationName) async {
    final stamp = CollectibleStamp(
      id: _uuid.v4(),
      tripId: tripId,
      cityName: destinationName.toUpperCase(),
      countryCode: 'PASSPORT',
      stationCode: 'CLEARED',
      date: DateTime.now(),
      shape: StampShape.rectangular,
      inkColor: StampInkColor.emerald,
      rotationRadians: 0.02,
      type: StampType.customsCleared,
    );
    _stamps.insert(0, stamp);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStamps, jsonEncode(_stamps.map((e) => e.toJson()).toList()));
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(_profile.toJson()));
    await prefs.setString(_keyTrips, jsonEncode(_trips.map((e) => e.toJson()).toList()));
    await prefs.setString(_keyItems, jsonEncode(_items.map((e) => e.toJson()).toList()));
    await prefs.setString(_keyStamps, jsonEncode(_stamps.map((e) => e.toJson()).toList()));
  }
}
