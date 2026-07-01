import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';

class HealthDataProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _readings = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _medicationLogs = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _adherenceStats;
  bool _isLoading = false;
  bool _isOffline = false;
  
  List<Map<String, dynamic>> get readings => _readings;
  List<Map<String, dynamic>> get medications => _medications;
  List<Map<String, dynamic>> get medicationLogs => _medicationLogs;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get adherenceStats => _adherenceStats;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  
  String get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? 'anonymous';
  }
  
  String? get userName {
    final user = Supabase.instance.client.auth.currentUser;
    return _userProfile?['full_name'] ?? user?.userMetadata?['full_name'] as String?;
  }
  
  String? get userEmail {
    return Supabase.instance.client.auth.currentUser?.email;
  }
  
  // Target ranges from profile
  double get glucoseMin => (_userProfile?['glucose_min'] as num?)?.toDouble() ?? 70;
  double get glucoseMax => (_userProfile?['glucose_max'] as num?)?.toDouble() ?? 125;
  double get systolicMax => (_userProfile?['systolic_max'] as num?)?.toDouble() ?? 140;
  double get diastolicMax => (_userProfile?['diastolic_max'] as num?)?.toDouble() ?? 90;
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _readings = await SupabaseService.getHealthReadings(_userId);
      _medications = await SupabaseService.getMedications(_userId);
      _userProfile = await SupabaseService.getUserProfile(_userId);
      _adherenceStats = await SupabaseService.getAdherenceStats(_userId);
      
      // Load medication logs for last 7 days
      final fromDate = DateTime.now().subtract(const Duration(days: 7));
      _medicationLogs = await SupabaseService.getMedicationLogs(_userId, fromDate: fromDate);
      
      // Cache data locally for offline use
      await LocalStorageService.cacheReadings(_readings);
      await LocalStorageService.cacheMedications(_medications);
      await LocalStorageService.cacheProfile(_userProfile);
      
      // Sync any pending readings
      await _syncPendingReadings();
      
      _isOffline = false;
    } catch (e) {
      debugPrint('Error loading data: $e');
      // Try to load from cache if online fails
      await _loadFromCache();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      _readings = await LocalStorageService.getCachedReadings();
      _medications = await LocalStorageService.getCachedMedications();
      _userProfile = await LocalStorageService.getCachedProfile();
      _isOffline = true;
      debugPrint('Loaded data from cache (offline mode)');
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _syncPendingReadings() async {
    final pending = await LocalStorageService.getPendingReadings();
    if (pending.isEmpty) return;
    
    debugPrint('Syncing ${pending.length} pending readings...');
    for (var reading in pending) {
      try {
        await SupabaseService.addHealthReading(
          userId: _userId,
          glucose: reading['glucose']?.toDouble(),
          systolic: reading['systolic']?.toDouble(),
          diastolic: reading['diastolic']?.toDouble(),
          symptoms: reading['symptoms'],
          readingContext: reading['reading_context'],
          mealType: reading['meal_type'],
        );
      } catch (e) {
        debugPrint('Error syncing reading: $e');
      }
    }
    await LocalStorageService.clearPendingReadings();
  }

  // ==================== READINGS ====================
  
  Future<void> addReading({
    double? glucose,
    double? systolic,
    double? diastolic,
    String? symptoms,
    String? readingContext,
    String? mealType,
  }) async {
    try {
      await SupabaseService.addHealthReading(
        userId: _userId,
        glucose: glucose,
        systolic: systolic,
        diastolic: diastolic,
        symptoms: symptoms,
        readingContext: readingContext,
        mealType: mealType,
      );
      await loadData();
    } catch (e) {
      debugPrint('Error adding reading: $e');
      // Save locally if offline
      await LocalStorageService.savePendingReading({
        'glucose': glucose,
        'systolic': systolic,
        'diastolic': diastolic,
        'symptoms': symptoms,
        'reading_context': readingContext,
        'meal_type': mealType,
        'created_at': DateTime.now().toIso8601String(),
      });
      // Add to local list for immediate display
      _readings.insert(0, {
        'id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'glucose': glucose,
        'systolic': systolic,
        'diastolic': diastolic,
        'symptoms': symptoms,
        'reading_context': readingContext,
        'meal_type': mealType,
        'created_at': DateTime.now().toIso8601String(),
        'pending': true,
      });
      _isOffline = true;
      notifyListeners();
    }
  }
  
  Future<void> deleteReading(dynamic id) async {
    try {
      await SupabaseService.deleteHealthReading(id.toString());
      await loadData();
    } catch (e) {
      debugPrint('Error deleting reading: $e');
      rethrow;
    }
  }
  
  // ==================== MEDICATIONS ====================
  
  Future<Map<String, dynamic>> addMedication({
    required String name,
    required String dosage,
    required List<String> times,
    List<int>? days,
  }) async {
    try {
      final med = await SupabaseService.addMedication(
        userId: _userId,
        name: name,
        dosage: dosage,
        times: times,
        days: days,
      );
      await loadData();
      return med;
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }
  
  Future<void> updateMedication({
    required dynamic id,
    required String name,
    required String dosage,
    required List<String> times,
    List<int>? days,
  }) async {
    try {
      await SupabaseService.updateMedication(
        id: id,
        name: name,
        dosage: dosage,
        times: times,
        days: days,
      );
      await loadData();
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }
  
  Future<void> deleteMedication(dynamic id) async {
    try {
      await SupabaseService.deleteMedication(id);
      await loadData();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  // ==================== MEDICATION ADHERENCE ====================
  
  Future<void> logMedicationTaken(String medicationId, String scheduledTime, {String? notes}) async {
    try {
      await SupabaseService.createMedicationLog(
        userId: _userId,
        medicationId: medicationId,
        scheduledTime: scheduledTime,
        status: 'taken',
        notes: notes,
      );
      await loadData();
    } catch (e) {
      debugPrint('Error logging medication: $e');
      rethrow;
    }
  }
  
  Future<void> logMedicationMissed(String medicationId, String scheduledTime, {String? notes}) async {
    try {
      await SupabaseService.createMedicationLog(
        userId: _userId,
        medicationId: medicationId,
        scheduledTime: scheduledTime,
        status: 'missed',
        notes: notes,
      );
      await loadData();
    } catch (e) {
      debugPrint('Error logging medication: $e');
      rethrow;
    }
  }
  
  Future<void> logMedicationSkipped(String medicationId, String scheduledTime, {String? notes}) async {
    try {
      await SupabaseService.createMedicationLog(
        userId: _userId,
        medicationId: medicationId,
        scheduledTime: scheduledTime,
        status: 'skipped',
        notes: notes,
      );
      await loadData();
    } catch (e) {
      debugPrint('Error logging medication: $e');
      rethrow;
    }
  }
  
  // ==================== USER PROFILE ====================
  
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await SupabaseService.updateUserProfile(_userId, data);
      await loadData();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
  
  Future<void> createProfileIfNeeded() async {
    if (_userProfile == null) {
      try {
        await SupabaseService.createUserProfile(_userId, fullName: userName);
        await loadData();
      } catch (e) {
        debugPrint('Error creating profile: $e');
      }
    }
  }
  
  // ==================== SHARED ACCESS ====================
  
  Future<Map<String, dynamic>> shareWithDoctor(String email, String name) async {
    try {
      return await SupabaseService.createSharedAccess(
        patientUserId: _userId,
        sharedWithEmail: email,
        sharedWithName: name,
        role: 'doctor',
        expiresInHours: 1, // 1 hour expiry, one-time use
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> shareWithCaregiver(String email, String name) async {
    try {
      return await SupabaseService.createSharedAccess(
        patientUserId: _userId,
        sharedWithEmail: email,
        sharedWithName: name,
        role: 'caregiver',
        expiresInHours: 1, // 1 hour expiry, one-time use
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      rethrow;
    }
  }
  
  // ==================== ALERTS ====================
  
  bool checkAlert(double? glucose, double? systolic, double? diastolic) {
    if (glucose != null && (glucose < glucoseMin || glucose > 180)) return true;
    if (systolic != null && (systolic < 90 || systolic > systolicMax)) return true;
    if (diastolic != null && (diastolic < 60 || diastolic > diastolicMax)) return true;
    return false;
  }
}
