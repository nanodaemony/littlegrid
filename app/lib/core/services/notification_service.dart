import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 初始化时区数据库
    tz_data.initializeTimeZones();

    // 设置本地时区
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    _plugin = FlutterLocalNotificationsPlugin();

    await _plugin!.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    await _createNotificationChannels();
    _initialized = true;
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'alarm_channel',
        '闹钟',
        description: '闹钟提醒通知',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'timer_channel',
        '倒计时',
        description: '倒计时结束通知',
        importance: Importance.high,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'pomodoro_channel',
        '番茄钟',
        description: '番茄钟提醒通知',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'anniversary_channel',
        '纪念日',
        description: '纪念日提醒通知',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'drink_plan_channel',
        '喝水提醒',
        description: '定时喝水提醒通知',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
  }

  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }

  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channel = 'alarm_channel',
  }) async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }
    await _plugin!.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == 'alarm_channel' ? '闹钟' :
          channel == 'timer_channel' ? '倒计时' :
          channel == 'pomodoro_channel' ? '番茄钟' :
          channel == 'anniversary_channel' ? '纪念日' : '喝水提醒',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }
    await _plugin!.cancel(id);
  }

  Future<void> cancelAll() async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }
    await _plugin!.cancelAll();
  }

  Future<void> showPomodoroNotification({
    required int id,
    required bool isWorkFinished,
    required DateTime scheduledDate,
  }) async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    final title = isWorkFinished ? '番茄钟结束' : '休息结束';
    final body = isWorkFinished ? '休息一下吧，喝杯水~' : '开始新的专注吧！';

    await _plugin!.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'pomodoro_channel',
          '番茄钟',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showAnniversaryNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    await _plugin!.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'anniversary_channel',
          '纪念日',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showDrinkPlanNotification({
    required int id,
    required DateTime scheduledDate,
  }) async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    await _plugin!.zonedSchedule(
      id,
      '喝水时间到',
      '记得补充水分哦~',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'drink_plan_channel',
          '喝水提醒',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showImmediately({
    required int id,
    required String title,
    required String body,
    String channel = 'alarm_channel',
  }) async {
    if (_plugin == null || !_initialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    await _plugin!.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == 'alarm_channel' ? '闹钟' :
          channel == 'timer_channel' ? '倒计时' :
          channel == 'pomodoro_channel' ? '番茄钟' :
          channel == 'anniversary_channel' ? '纪念日' : '喝水提醒',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }
}
