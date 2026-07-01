import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  
  // ==================== HEALTH READINGS ====================
  
  static Future<List<Map<String, dynamic>>> getHealthReadings(String userId) async {
    final response = await client
        .from('health_readings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<void> addHealthReading({
    required String userId,
    double? glucose,
    double? systolic,
    double? diastolic,
    String? symptoms,
    String? readingContext,
    String? mealType,
  }) async {
    await client.from('health_readings').insert({
      'user_id': userId,
      'glucose': glucose,
      'systolic': systolic,
      'diastolic': diastolic,
      'symptoms': symptoms,
      'reading_context': readingContext,
      'meal_type': mealType,
    });
  }
  
  static Future<void> deleteHealthReading(String readingId) async {
    await client.from('health_readings').delete().eq('id', readingId);
  }
  
  // ==================== MEDICATIONS ====================
  
  static Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    final response = await client
        .from('medications')
        .select()
        .eq('user_id', userId)
        .eq('active', true);
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<Map<String, dynamic>> addMedication({
    required String userId,
    required String name,
    required String dosage,
    required List<String> times,
    List<int>? days,
  }) async {
    final data = {
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'times': times,
      'active': true,
    };
    if (days != null && days.isNotEmpty) {
      data['days'] = days;
    }
    final response = await client.from('medications').insert(data).select().single();
    return response;
  }
  
  static Future<void> updateMedication({
    required dynamic id,
    required String name,
    required String dosage,
    required List<String> times,
    List<int>? days,
  }) async {
    final data = {
      'name': name,
      'dosage': dosage,
      'times': times,
      'days': days,
    };
    await client.from('medications').update(data).eq('id', id);
  }
  
  static Future<void> deleteMedication(dynamic id) async {
    await client.from('medications').delete().eq('id', id);
  }

  static Future<void> deactivateMedication(String medicationId) async {
    await client.from('medications').update({'active': false}).eq('id', medicationId);
  }

  // ==================== MEDICATION LOGS (Adherence) ====================
  
  static Future<List<Map<String, dynamic>>> getMedicationLogs(String userId, {DateTime? fromDate}) async {
    var query = client
        .from('medication_logs')
        .select('*, medications(name, dosage)')
        .eq('user_id', userId);
    
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<void> logMedicationTaken({
    required String userId,
    required String medicationId,
    required String scheduledTime,
    String? notes,
  }) async {
    await client.from('medication_logs').insert({
      'user_id': userId,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime,
      'taken_at': DateTime.now().toIso8601String(),
      'status': 'taken',
      'notes': notes,
    });
  }
  
  static Future<void> createMedicationLog({
    required String userId,
    required String medicationId,
    required String scheduledTime,
    required String status,
    String? notes,
  }) async {
    await client.from('medication_logs').insert({
      'user_id': userId,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime,
      'status': status,
      'taken_at': status == 'taken' ? DateTime.now().toIso8601String() : null,
      'notes': notes,
    });
  }
  
  static Future<void> updateMedicationLog(String logId, String status, {String? notes}) async {
    await client.from('medication_logs').update({
      'status': status,
      'taken_at': status == 'taken' ? DateTime.now().toIso8601String() : null,
      'notes': notes,
    }).eq('id', logId);
  }
  
  static Future<Map<String, dynamic>> getAdherenceStats(String userId, {int days = 30}) async {
    final fromDate = DateTime.now().subtract(Duration(days: days));
    final logs = await getMedicationLogs(userId, fromDate: fromDate);
    
    int total = logs.length;
    int taken = logs.where((l) => l['status'] == 'taken').length;
    int missed = logs.where((l) => l['status'] == 'missed').length;
    int skipped = logs.where((l) => l['status'] == 'skipped').length;
    
    return {
      'total': total,
      'taken': taken,
      'missed': missed,
      'skipped': skipped,
      'adherence_percent': total > 0 ? (taken / total * 100).round() : 0,
    };
  }

  // ==================== USER PROFILE ====================
  
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> createUserProfile(String userId, {String? fullName}) async {
    await client.from('user_profiles').insert({
      'user_id': userId,
      'full_name': fullName,
    });
  }
  
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    data['user_id'] = userId;
    
    // Use upsert to create profile if it doesn't exist
    await client.from('user_profiles').upsert(
      data,
      onConflict: 'user_id',
    );
  }
  
  // ==================== SHARED ACCESS ====================
  
  static String _generateAccessCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  static Future<Map<String, dynamic>> createSharedAccess({
    required String patientUserId,
    required String sharedWithEmail,
    String? sharedWithName,
    String role = 'viewer',
    int? expiresInDays,
    int? expiresInHours,
  }) async {
    final accessCode = _generateAccessCode();
    
    // Default to 1 hour expiry for quick codes, or use specified days/hours
    String expiresAt;
    if (expiresInHours != null) {
      expiresAt = DateTime.now().add(Duration(hours: expiresInHours)).toIso8601String();
    } else if (expiresInDays != null) {
      expiresAt = DateTime.now().add(Duration(days: expiresInDays)).toIso8601String();
    } else {
      // Default: 1 hour for security
      expiresAt = DateTime.now().add(const Duration(hours: 1)).toIso8601String();
    }
    
    final response = await client.from('shared_access').insert({
      'patient_user_id': patientUserId,
      'shared_with_email': sharedWithEmail,
      'shared_with_name': sharedWithName,
      'access_code': accessCode,
      'role': role,
      'expires_at': expiresAt,
    }).select().single();
    
    return response;
  }
  
  static Future<List<Map<String, dynamic>>> getSharedAccess(String userId) async {
    final response = await client
        .from('shared_access')
        .select()
        .eq('patient_user_id', userId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<void> revokeSharedAccess(String accessId) async {
    await client.from('shared_access').update({'is_active': false}).eq('id', accessId);
  }
  
  static Future<Map<String, dynamic>?> getPatientDataByAccessCode(String accessCode) async {
    try {
      final access = await client
          .from('shared_access')
          .select()
          .eq('access_code', accessCode)
          .eq('is_active', true)
          .maybeSingle();
      
      if (access == null) return null;
      
      // Check expiry
      if (access['expires_at'] != null) {
        final expiresAt = DateTime.parse(access['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) return null;
      }
      
      final patientId = access['patient_user_id'];
      
      // Get patient data
      final readings = await getHealthReadings(patientId);
      final medications = await getMedications(patientId);
      final profile = await getUserProfile(patientId);
      
      return {
        'access': access,
        'profile': profile,
        'readings': readings,
        'medications': medications,
      };
    } catch (e) {
      return null;
    }
  }
}
