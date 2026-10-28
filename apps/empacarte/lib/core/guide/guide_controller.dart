import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideController extends ChangeNotifier {
  static const String _prefPrefix = 'empacarte_seen_guide_';

  static const String passportGuide = 'passport';
  static const String tripsGuide = 'trips';
  static const String packingGuide = 'packing';
  static const String toolsGuide = 'tools';
  static const String albumGuide = 'album';

  final Map<String, bool> _seenGuides = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  bool shouldShowGuide(String guideKey) {
    return !(_seenGuides[guideKey] ?? false);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [passportGuide, tripsGuide, packingGuide, toolsGuide, albumGuide];
    for (final k in keys) {
      _seenGuides[k] = prefs.getBool('$_prefPrefix$k') ?? false;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> markGuideSeen(String guideKey) async {
    _seenGuides[guideKey] = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix$guideKey', true);
  }

  Future<void> resetAllGuides() async {
    final keys = [passportGuide, tripsGuide, packingGuide, toolsGuide, albumGuide];
    final prefs = await SharedPreferences.getInstance();
    for (final k in keys) {
      _seenGuides[k] = false;
      await prefs.remove('$_prefPrefix$k');
    }
    notifyListeners();
  }
}
