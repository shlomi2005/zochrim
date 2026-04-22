import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/omer_days.dart';
import 'jewish_day_service.dart';
import 'omer_service.dart';
import 'preferences_service.dart';
import 'profile_service.dart';
import 'tefillin_service.dart';

/// שירות התראות - תפילין בבוקר כל השנה, ספירת העומר בערב בזמן העונה.
/// משתיק אוטומטית בשבת ויו"ט לפי ההלכה.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ערוצים שונים למסרים שונים - אנדרואיד מציג אותם כהעדפות נפרדות
  static const String _channelOmer = 'omer_daily';
  static const String _channelOmerName = 'ספירת העומר';
  static const String _channelOmerDesc = 'תזכורת ערב בזמן ספירת העומר';

  static const String _channelTefillin = 'tefillin_daily';
  static const String _channelTefillinName = 'תפילין';
  static const String _channelTefillinDesc = 'תזכורת בוקר להניח תפילין';

  // טווחי מזהים - למנוע התנגשות בין סוגים
  // 1..49   = ימי עומר
  // 100..114 = 14 ימי תפילין קדימה
  static const int _tefillinIdBase = 100;
  static const int _tefillinDaysAhead = 14;

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  /// מתזמן את כל ההתראות - תפילין (14 ימים) ועומר (49 ימים בזמן הספירה).
  /// נקרא בשינוי הגדרות, התחלת אפליקציה, וסימון של יום.
  static Future<void> scheduleAllReminders() async {
    await _plugin.cancelAll();
    await scheduleAllOmerReminders(skipCancel: true);
    await scheduleAllTefillinReminders(skipCancel: true);
  }

  // ------------------ עומר ------------------

  static Future<void> scheduleAllOmerReminders({bool skipCancel = false}) async {
    if (!skipCancel) {
      // מבטל רק את ערוץ העומר (1..49)
      for (int i = 1; i <= 49; i++) {
        await _plugin.cancel(i);
      }
    }

    final hour = await PreferencesService.getReminderHour();
    final minute = await PreferencesService.getReminderMinute();
    final lastCounted = await PreferencesService.getLastCountedDayNumber() ?? 0;
    final userName = await ProfileService.getName();
    final city = await ProfileService.getCity();

    for (int day = 1; day <= 49; day++) {
      if (day <= lastCounted) continue;

      final calDate = OmerService.dateForDay(day);
      final scheduled = tz.TZDateTime(
        tz.local,
        calDate.year,
        calDate.month,
        calDate.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

      // השתקה בשבת/יו"ט: אם הערב של הספירה חל בשבת או ביו"ט (אסור במלאכה),
      // אין שולחים התראה - המשתמש יספור ממילא במוצאי שבת/יו"ט.
      final jd = JewishDayService(
        city: city,
        date: DateTime(calDate.year, calDate.month, calDate.day, hour, minute),
      );
      if (jd.isAssurBemelacha) continue;

      final personal = (userName != null && userName.isNotEmpty)
          ? "$userName, אל תשכח"
          : "אל תשכח לספור";
      final body =
          "הערב — יום $day לעומר 💫 $personal\n${omerCounts[day - 1]}";

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelOmer,
          _channelOmerName,
          channelDescription: _channelOmerDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

      await _safeSchedule(
        id: day,
        title: "🌟 זמן לספור ספירת העומר",
        body: body,
        when: scheduled,
        details: details,
        payload: 'omer_day_$day',
      );
    }
  }

  // ------------------ תפילין ------------------

  static Future<void> scheduleAllTefillinReminders(
      {bool skipCancel = false}) async {
    if (!skipCancel) {
      for (int i = 0; i < _tefillinDaysAhead + 2; i++) {
        await _plugin.cancel(_tefillinIdBase + i);
      }
    }

    final city = await ProfileService.getCity();
    final tefillinHour = await PreferencesService.getTefillinHour();
    final tefillinMinute = await PreferencesService.getTefillinMinute();
    final userName = await ProfileService.getName();
    final personal = (userName != null && userName.isNotEmpty) ? "$userName, " : "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int offset = 0; offset < _tefillinDaysAhead; offset++) {
      final targetDate = today.add(Duration(days: offset));
      final decision = TefillinService.decide(city: city, date: targetDate);

      if (!decision.shouldWearToday) continue;

      int hour, minute;
      String title;
      String body;

      if (decision.status == TefillinStatus.wearTishaBavMincha) {
        // תשעה באב - מתזמן למנחה גדולה
        final jd = JewishDayService(city: city, date: targetDate);
        final mg = jd.minchaGedola;
        if (mg == null) continue;
        hour = mg.hour;
        minute = mg.minute;
        title = "🔥 מנחת תשעה באב";
        body =
            "${personal}עכשיו מניחים תפילין ומתפללים מנחה. התענית כמעט בסיומה.";
      } else if (decision.status == TefillinStatus.wearRoshChodesh) {
        hour = tefillinHour;
        minute = tefillinMinute;
        title = "✡️ ראש חודש - תפילין";
        body = "${personal}ראש חודש היום. הנח תפילין - וזכור להוריד לפני מוסף.";
      } else {
        hour = tefillinHour;
        minute = tefillinMinute;
        title = "📿 בוקר טוב - תפילין";
        body = "${personal}זמן להניח תפילין ולהתפלל שחרית.";
      }

      final scheduled = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTefillin,
          _channelTefillinName,
          channelDescription: _channelTefillinDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

      await _safeSchedule(
        id: _tefillinIdBase + offset,
        title: title,
        body: body,
        when: scheduled,
        details: details,
        payload: 'tefillin_${targetDate.toIso8601String()}',
      );
    }
  }

  // ------------------ עזר ------------------

  /// נסה exact, אם נכשל (אין הרשאה ב-Android 12+) - fall back ל-inexact.
  static Future<void> _safeSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  /// מבטל את ההתראה של יום עומר ספציפי
  static Future<void> cancelDay(int day) async {
    await _plugin.cancel(day);
  }

  /// מבטל את התזכורת של תפילין של היום (אחרי סימון "הנחתי")
  static Future<void> cancelTefillinToday() async {
    await _plugin.cancel(_tefillinIdBase);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ------------------ אבחון ------------------

  static Future<void> showTestNow() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelTefillin,
        _channelTefillinName,
        channelDescription: _channelTefillinDesc,
        importance: Importance.max,
        priority: Priority.max,
      ),
    );
    await _plugin.show(
      9999,
      "🔔 התראת בדיקה",
      "אם אתה רואה את זה - ההתראות באפליקציה עובדות.",
      details,
    );
  }

  static Future<DateTime> scheduleTestInMinute() async {
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelTefillin,
        _channelTefillinName,
        channelDescription: _channelTefillinDesc,
        importance: Importance.max,
        priority: Priority.max,
      ),
    );
    await _safeSchedule(
      id: 9998,
      title: "⏰ התראת תזמון",
      body: "אם אתה רואה את זה דקה אחרי הלחיצה - גם התזמון עובד.",
      when: when,
      details: details,
      payload: 'test',
    );
    return DateTime(
        when.year, when.month, when.day, when.hour, when.minute, when.second);
  }

  static Future<void> requestPermissionsAgain() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  static Future<NotificationDiagnostic> diagnose() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    bool? enabled;
    bool? canExact;
    try {
      enabled = await androidImpl?.areNotificationsEnabled();
    } catch (_) {}
    try {
      canExact = await androidImpl?.canScheduleExactNotifications();
    } catch (_) {}
    List<PendingNotificationRequest> pending = const [];
    try {
      pending = await _plugin.pendingNotificationRequests();
    } catch (_) {}
    final ids = pending.map((p) => p.id).toList()..sort();
    return NotificationDiagnostic(
      notificationsEnabled: enabled,
      canScheduleExactAlarms: canExact,
      pendingCount: pending.length,
      pendingIds: ids,
    );
  }
}

class NotificationDiagnostic {
  final bool? notificationsEnabled;
  final bool? canScheduleExactAlarms;
  final int pendingCount;
  final List<int> pendingIds;
  const NotificationDiagnostic({
    required this.notificationsEnabled,
    required this.canScheduleExactAlarms,
    required this.pendingCount,
    required this.pendingIds,
  });
}
