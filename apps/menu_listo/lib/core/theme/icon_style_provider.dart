import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppIconStyle {
  emojis,
  icons,
}

final iconStyleProvider = StateNotifierProvider<IconStyleNotifier, AppIconStyle>((ref) {
  return IconStyleNotifier();
});

class IconStyleNotifier extends StateNotifier<AppIconStyle> {
  IconStyleNotifier() : super(AppIconStyle.emojis) {
    _loadFromPrefs();
  }

  static const _prefKey = 'app_icon_style';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'icons') {
      state = AppIconStyle.icons;
    } else {
      state = AppIconStyle.emojis;
    }
  }

  Future<void> setIconStyle(AppIconStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, style.name);
  }
}
