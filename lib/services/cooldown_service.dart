import 'package:shared_preferences/shared_preferences.dart';

class CooldownService {
  static const int cooldownMinutes = 30;
  static const Duration cooldownDuration = Duration(minutes: cooldownMinutes);

  String _getKey(String stationId, String userId) => 'cooldown_${userId}_$stationId';

  /// Check whether the user is permitted to update the station
  Future<bool> canUserUpdate(String stationId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(stationId, userId);
    final lastUpdateEpoch = prefs.getInt(key);

    if (lastUpdateEpoch == null) return true;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdateEpoch);
    final elapsed = DateTime.now().difference(lastUpdateTime);
    return elapsed >= cooldownDuration;
  }

  /// Get the remaining cooldown duration for the given station & user
  Future<Duration> getRemainingCooldown(String stationId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(stationId, userId);
    final lastUpdateEpoch = prefs.getInt(key);

    if (lastUpdateEpoch == null) return Duration.zero;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdateEpoch);
    final elapsed = DateTime.now().difference(lastUpdateTime);
    if (elapsed >= cooldownDuration) {
      return Duration.zero;
    }
    return cooldownDuration - elapsed;
  }

  /// Record a new update event timestamp locally
  Future<void> recordUpdate(String stationId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(stationId, userId);
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Reset/clear cooldown for testing purposes
  Future<void> clearCooldown(String stationId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(stationId, userId);
    await prefs.remove(key);
  }
}
