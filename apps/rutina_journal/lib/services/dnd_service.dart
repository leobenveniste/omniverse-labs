import 'package:flutter/services.dart';

class DndService {
  static const _channel = MethodChannel('com.omniverselabs.ritmo/dnd');

  static Future<bool> hasPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('hasDndPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openDndSettings');
    } catch (_) {}
  }

  static Future<bool> enableDnd() async {
    try {
      final res = await _channel.invokeMethod<bool>('enableDnd');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> disableDnd() async {
    try {
      final res = await _channel.invokeMethod<bool>('disableDnd');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
