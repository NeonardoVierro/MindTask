// File: lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data
    tzdata.initializeTimeZones();
    try {
      final String tzName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      if (kDebugMode) print('Could not get local timezone: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  int _idFromString(String id, [int offset = 0]) {
    // convert string id to stable positive int for notification id
    return (id.hashCode & 0x7FFFFFFF) + offset;
  }

  Future<void> scheduleForTodo(Todo todo) async {
    await init();
    if (todo.id.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);

    // Schedule reminder 1 day before at 09:00 local time (if still in future)
    final due = tz.TZDateTime.from(todo.dueDate, tz.local);
    final preReminder = tz.TZDateTime(tz.local, due.year, due.month, due.day)
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 9));

    if (preReminder.isAfter(now)) {
      await _plugin.zonedSchedule(
        _idFromString(todo.id, 0),
        'Pengingat: ${todo.title}',
        'Deadline besok: ${todo.title}',
        preReminder,
        const NotificationDetails(
          android: AndroidNotificationDetails('todo_channel', 'Todo Reminders', channelDescription: 'Pengingat tugas'),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }

    // Schedule notification at due date at 09:00 (or the time part of dueDate)
    final dueAtNine = tz.TZDateTime(tz.local, due.year, due.month, due.day, 9);
    final dueDateTime = dueAtNine.isBefore(due) ? due : dueAtNine;

    if (dueDateTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        _idFromString(todo.id, 100000),
        'Deadline: ${todo.title}',
        'Tugas harus diselesaikan sekarang',
        dueDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails('todo_channel', 'Todo Reminders', channelDescription: 'Pengingat tugas'),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  Future<void> cancelForTodoId(String id) async {
    await init();
    await _plugin.cancel(_idFromString(id, 0));
    await _plugin.cancel(_idFromString(id, 100000));
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> showImmediateNotification(String title, String body, {int id = 0}) async {
    await init();
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'action_channel',
            'App Actions',
            channelDescription: 'Notifikasi untuk aksi CRUD / auth',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Failed to show immediate notification: $e');
    }
  }
}
