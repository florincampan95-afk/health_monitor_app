import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    
    // Set local timezone
    tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // Request notification permission
      final notifGranted = await android.requestNotificationsPermission();
      debugPrint('Notification permission granted: $notifGranted');
      
      // Check if exact alarms are permitted
      final canScheduleExact = await android.canScheduleExactNotifications();
      debugPrint('Can schedule exact alarms: $canScheduleExact');
      
      return (notifGranted ?? false);
    }
    return true;
  }
  
  Future<bool> canScheduleExactAlarms() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.canScheduleExactNotifications() ?? false;
    }
    return true;
  }
  
  Future<void> openAlarmSettings() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
    List<int>? days, // 0=Sunday, 1=Monday, etc. null means every day
  }) async {
    final now = DateTime.now();
    
    // If specific days are set, schedule for each day
    if (days != null && days.isNotEmpty) {
      for (int i = 0; i < days.length; i++) {
        final dayOfWeek = days[i];
        var scheduledDate = _getNextDateForDay(dayOfWeek, time);
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
        final notifId = id * 10 + i; // Unique ID per day
        
        debugPrint('Scheduling medication for day $dayOfWeek at $time (ID: $notifId)');
        
        try {
          await _notifications.zonedSchedule(
            notifId,
            '💊 Ora medicamentului',
            '$medicationName - $dosage',
            tzScheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'medication_reminders',
                'Reminder Medicamente',
                channelDescription: 'Notificări pentru administrarea medicamentelor',
                importance: Importance.max,
                priority: Priority.max,
                icon: '@mipmap/ic_launcher',
                playSound: true,
                enableVibration: true,
                fullScreenIntent: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: medicationName,
          );
        } catch (e) {
          debugPrint('Error scheduling notification: $e');
        }
      }
    } else {
      // Schedule daily (every day)
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      debugPrint('Scheduling daily notification for: $tzScheduledDate (ID: $id)');

      try {
        await _notifications.zonedSchedule(
          id,
          '💊 Ora medicamentului',
          '$medicationName - $dosage',
          tzScheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_reminders',
              'Reminder Medicamente',
              channelDescription: 'Notificări pentru administrarea medicamentelor',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: medicationName,
        );
        debugPrint('Notification scheduled successfully!');
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
  }
  
  DateTime _getNextDateForDay(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // Find next occurrence of this day
    while (date.weekday % 7 != dayOfWeek || date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  Future<void> cancelMedicationReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // Schedule all reminders for a medication
  Future<void> scheduleAllRemindersForMedication({
    required String medicationId,
    required String name,
    required String dosage,
    required List<String> times,
    List<int>? days, // 0=Sunday, 1=Monday, etc. null means every day
  }) async {
    for (int i = 0; i < times.length; i++) {
      final timeParts = times[i].split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        
        // Create unique ID from medication ID hash + time index
        final notificationId = medicationId.hashCode + i;
        
        await scheduleMedicationReminder(
          id: notificationId,
          medicationName: name,
          dosage: dosage,
          time: TimeOfDay(hour: hour, minute: minute),
          days: days,
        );
      }
    }
  }
  
  // Cancel all reminders for a specific medication
  Future<void> cancelRemindersForMedication(String medicationId, int timesCount, {List<int>? days}) async {
    for (int i = 0; i < timesCount; i++) {
      final notificationId = medicationId.hashCode + i;
      await cancelMedicationReminder(notificationId);
      // Also cancel day-specific notifications
      if (days != null) {
        for (int j = 0; j < days.length; j++) {
          await cancelMedicationReminder(notificationId * 10 + j);
        }
      } else {
        // Cancel potential day-specific ones (0-6)
        for (int j = 0; j < 7; j++) {
          await cancelMedicationReminder(notificationId * 10 + j);
        }
      }
    }
  }

  // Schedule reading reminder (glucose or blood pressure)
  Future<void> scheduleReadingReminder({
    required int id,
    required String type, // 'glucose' or 'bp'
    required TimeOfDay time,
    List<int>? days, // 0=Sunday, 1=Monday, etc. null means every day
  }) async {
    final now = DateTime.now();
    
    final title = type == 'glucose' 
        ? '📊 Măsurați glicemia' 
        : '❤️ Măsurați tensiunea';
    final body = type == 'glucose'
        ? 'Este timpul să vă măsurați glicemia pe nemâncate'
        : 'Este timpul să vă măsurați tensiunea arterială';

    // If specific days are set, schedule for each day
    if (days != null && days.isNotEmpty) {
      for (int i = 0; i < days.length; i++) {
        final dayOfWeek = days[i];
        var scheduledDate = _getNextDateForDay(dayOfWeek, time);
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
        final notifId = id * 10 + i;
        
        try {
          await _notifications.zonedSchedule(
            notifId,
            title,
            body,
            tzScheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'reading_reminders',
                'Reminder Măsurători',
                channelDescription: 'Notificări pentru măsurători zilnice',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                playSound: true,
                enableVibration: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: type,
          );
          debugPrint('Reading reminder scheduled for $type on day $dayOfWeek at $time');
        } catch (e) {
          debugPrint('Error scheduling reading reminder: $e');
        }
      }
    } else {
      // Schedule daily
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'reading_reminders',
              'Reminder Măsurători',
              channelDescription: 'Notificări pentru măsurători zilnice',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: type,
        );
        debugPrint('Reading reminder scheduled for $type at $time (daily)');
      } catch (e) {
        debugPrint('Error scheduling reading reminder: $e');
      }
    }
  }

  Future<void> cancelReadingReminder(int id, {List<int>? days}) async {
    await _notifications.cancel(id);
    // Also cancel day-specific notifications
    for (int i = 0; i < 7; i++) {
      await _notifications.cancel(id * 10 + i);
    }
  }
}
