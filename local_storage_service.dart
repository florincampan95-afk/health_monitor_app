import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _readingsKey = 'cached_readings';
  static const String _medicationsKey = 'cached_medications';
  static const String _profileKey = 'cached_profile';
  static const String _lastSyncKey = 'last_sync';
  static const String _pendingReadingsKey = 'pending_readings';

  // Cache readings locally
  static Future<void> cacheReadings(List<Map<String, dynamic>> readings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readingsKey, jsonEncode(readings));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Get cached readings
  static Future<List<Map<String, dynamic>>> getCachedReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_readingsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Cache medications locally
  static Future<void> cacheMedications(List<Map<String, dynamic>> medications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_medicationsKey, jsonEncode(medications));
  }

  // Get cached medications
  static Future<List<Map<String, dynamic>>> getCachedMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_medicationsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Cache profile locally
  static Future<void> cacheProfile(Map<String, dynamic>? profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile != null) {
      await prefs.setString(_profileKey, jsonEncode(profile));
    }
  }

  // Get cached profile
  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);
    if (data == null) return null;
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  // Save pending reading (when offline)
  static Future<void> savePendingReading(Map<String, dynamic> reading) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getString(_pendingReadingsKey);
    List<Map<String, dynamic>> pending = [];
    if (pendingData != null) {
      final list = jsonDecode(pendingData) as List;
      pending = list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    pending.add(reading);
    await prefs.setString(_pendingReadingsKey, jsonEncode(pending));
  }

  // Get pending readings
  static Future<List<Map<String, dynamic>>> getPendingReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_pendingReadingsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Clear pending readings after sync
  static Future<void> clearPendingReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingReadingsKey);
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastSyncKey);
    if (data == null) return null;
    return DateTime.parse(data);
  }

  // Check if we have cached data
  static Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_readingsKey);
  }
}
