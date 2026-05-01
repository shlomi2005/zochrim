import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/omer_days.dart';
import '../models/zman_type.dart';
import 'chizuk_service.dart';
import 'daily_study_service.dart';
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

  static const String _channelZmanim = 'zmanim_daily';
  static const String _channelZmanimName = 'זמני היום';
  static const String _channelZmanimDesc =
      'תזכורות לפני זמני היום (סוף ק"ש, מנחה, הדלקת נרות וכו\')';

  static const String _channelDafYomi = 'daf_yomi_daily';
  static const String _channelDafYomiName = 'דף יומי';
  static const String _channelDafYomiDesc =
      'תזכורת יומית ללימוד דף יומי בבלי';

  /// ערוץ "תזכורת אישית" — שם ניטרלי בכוונה כדי לשמור על פרטיות המשתמש
  /// בהגדרות אנדרואיד. רק הוא יודע במה מדובר.
  static const String _channelChizuk = 'personal_reminder';
  static const String _channelChizukName = 'תזכורת אישית';
  static const String _channelChizukDesc = 'תזכורת שהמשתמש הגדיר בעצמו';

  // טווחי מזהים - למנוע התנגשות בין סוגים
  // 1..49      = ימי עומר
  // 100..114   = 14 ימי תפילין קדימה
  // 200..499   = זמני היום (עד 20 סוגים × 14 ימים, פיזית 15 × 14 = 210)
  // 500..513   = 14 ימי דף יומי קדימה
  // 600..613   = 14 ימי "תזכורת אישית" (חיזוק)
  static const int _tefillinIdBase = 100;
  static const int _tefillinDaysAhead = 14;
  static const int _zmanimIdBase = 200;
  static const int _zmanimDaysAhead = 14;
  static const int _dafYomiIdBase = 500;
  static const int _dafYomiDaysAhead = 14;
  static const int _chizukIdBase = 600;
  static const int _chizukDaysAhead = 14;

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

    // אחרי הבקשה — בודקים אם המשתמש דחה. אם כן, מכבים את כל המתגים
    // אוטומטית כדי שמסך ההגדרות לא יהיה עם מתגים דלוקים שלא עושים כלום.
    await syncWithSystemPermission();
  }

  /// בודק אם הרשאת ההתראות הופעלה במערכת.
  static Future<bool> areNotificationsEnabled() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      final ok = await androidImpl?.areNotificationsEnabled();
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// אם ההרשאה כבויה במערכת — מכבה את כל המתגים בשמירת העדפות
  /// ומבטל כל התראה שמתוזמנת. אם ההרשאה דלוקה — לא נוגע במצב המשתמש.
  static Future<void> syncWithSystemPermission() async {
    if (await areNotificationsEnabled()) return;

    await PreferencesService.setTefillinEnabled(false);
    await PreferencesService.setOmerEnabled(false);
    await PreferencesService.setDafYomiEnabled(false);
    for (final cfg in zmanimConfigs) {
      await PreferencesService.setZmanEnabled(cfg.type, false);
    }
    await ChizukService.setReminderEnabled(false);
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// פותח את עמוד ההגדרות של ההתראות באנדרואיד עבור האפליקציה.
  static Future<void> openSystemNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {
      // fallback — עמוד הגדרות אפליקציה כללי
      try {
        await AppSettings.openAppSettings();
      } catch (_) {}
    }
  }

  /// מתזמן את כל ההתראות - תפילין, עומר, וזמני היום (14 ימים קדימה).
  /// נקרא בשינוי הגדרות, התחלת אפליקציה, וסימון של יום.
  static Future<void> scheduleAllReminders() async {
    await _plugin.cancelAll();
    await scheduleAllOmerReminders(skipCancel: true);
    await scheduleAllTefillinReminders(skipCancel: true);
    await scheduleAllZmanimReminders(skipCancel: true);
    await scheduleAllDafYomiReminders(skipCancel: true);
    await scheduleAllChizukReminders(skipCancel: true);
  }

  // ------------------ עומר ------------------

  static Future<void> scheduleAllOmerReminders({bool skipCancel = false}) async {
    if (!skipCancel) {
      // מבטל רק את ערוץ העומר (1..49)
      for (int i = 1; i <= 49; i++) {
        await _plugin.cancel(i);
      }
    }

    // אם המשתמש כיבה את התראות העומר - יוצאים אחרי הביטול
    if (!await PreferencesService.isOmerEnabled()) return;

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

    if (!await PreferencesService.isTefillinEnabled()) return;

    final city = await ProfileService.getCity();
    final tefillinHour = await PreferencesService.getTefillinHour();
    final tefillinMinute = await PreferencesService.getTefillinMinute();
    final userName = await ProfileService.getName();
    final personal = (userName != null && userName.isNotEmpty) ? "$userName, " : "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final alreadyDoneToday = await PreferencesService.hasDoneTefillinToday();

    for (int offset = 0; offset < _tefillinDaysAhead; offset++) {
      // אם המשתמש כבר סימן היום — אין טעם לשלוח את התזכורת של היום.
      if (offset == 0 && alreadyDoneToday) continue;

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

  // ------------------ זמני היום ------------------

  static Future<void> scheduleAllZmanimReminders(
      {bool skipCancel = false}) async {
    if (!skipCancel) {
      final total = zmanimConfigs.length * _zmanimDaysAhead;
      for (int i = 0; i < total; i++) {
        await _plugin.cancel(_zmanimIdBase + i);
      }
    }

    final city = await ProfileService.getCity();
    final userName = await ProfileService.getName();
    final personal =
        (userName != null && userName.isNotEmpty) ? "$userName, " : "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int zIdx = 0; zIdx < zmanimConfigs.length; zIdx++) {
      final cfg = zmanimConfigs[zIdx];
      if (!await PreferencesService.isZmanEnabled(cfg.type)) continue;
      final leadMinutes =
          await PreferencesService.getZmanLeadMinutes(cfg.type);

      for (int offset = 0; offset < _zmanimDaysAhead; offset++) {
        final targetDate = today.add(Duration(days: offset));
        final jd = JewishDayService(city: city, date: targetDate);

        if (cfg.silenceOnAssurBemelacha && jd.isAssurBemelacha) continue;

        final zmanTime = cfg.compute(jd);
        if (zmanTime == null) continue;

        final alertTime =
            zmanTime.subtract(Duration(minutes: leadMinutes));
        final scheduled = tz.TZDateTime(
          tz.local,
          alertTime.year,
          alertTime.month,
          alertTime.day,
          alertTime.hour,
          alertTime.minute,
        );
        if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

        final zmanClockStr =
            "${zmanTime.hour.toString().padLeft(2, '0')}:"
            "${zmanTime.minute.toString().padLeft(2, '0')}";
        final body = "$personal${cfg.shortLabel} בעוד $leadMinutes דק' "
            "($zmanClockStr).";

        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            _channelZmanim,
            _channelZmanimName,
            channelDescription: _channelZmanimDesc,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        );

        await _safeSchedule(
          id: _zmanimIdBase + zIdx * _zmanimDaysAhead + offset,
          title: cfg.notificationTitle,
          body: body,
          when: scheduled,
          details: details,
          payload: 'zman_${cfg.type.name}_${targetDate.toIso8601String()}',
        );
      }
    }
  }

  // ------------------ דף יומי ------------------

  static Future<void> scheduleAllDafYomiReminders(
      {bool skipCancel = false}) async {
    if (!skipCancel) {
      for (int i = 0; i < _dafYomiDaysAhead; i++) {
        await _plugin.cancel(_dafYomiIdBase + i);
      }
    }

    if (!await PreferencesService.isDafYomiEnabled()) return;

    final hour = await PreferencesService.getDafYomiHour();
    final minute = await PreferencesService.getDafYomiMinute();
    final userName = await ProfileService.getName();
    final personal =
        (userName != null && userName.isNotEmpty) ? "$userName, " : "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int offset = 0; offset < _dafYomiDaysAhead; offset++) {
      final targetDate = today.add(Duration(days: offset));
      final scheduled = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final dafText = DailyStudyService.getDafYomiBavli(targetDate);
      final body = "${personal}היום: $dafText";

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelDafYomi,
          _channelDafYomiName,
          channelDescription: _channelDafYomiDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

      await _safeSchedule(
        id: _dafYomiIdBase + offset,
        title: "דף יומי",
        body: body,
        when: scheduled,
        details: details,
        payload: 'daf_yomi_${targetDate.toIso8601String()}',
      );
    }
  }

  // ------------------ חיזוק (תזכורת אישית) ------------------

  /// מתזמן את התזכורת היומית של פיצ'ר החיזוק.
  /// כותרת = הטקסט המותאם של המשתמש (ברירת מחדל: "תזכורת").
  /// ה-payload ריק במכוון — לחיצה על ההתראה רק פותחת את האפליקציה
  /// למסך הבית, לא למסך החיזוק. שמירת פרטיות.
  static Future<void> scheduleAllChizukReminders(
      {bool skipCancel = false}) async {
    if (!skipCancel) {
      for (int i = 0; i < _chizukDaysAhead; i++) {
        await _plugin.cancel(_chizukIdBase + i);
      }
    }

    if (!await ChizukService.isReminderEnabled()) return;

    final reminderHour = await ChizukService.getReminderHour();
    final reminderMinute = await ChizukService.getReminderMinute();
    final dayEndHour = await ChizukService.getDayEndHour();
    final dayEndMinute = await ChizukService.getDayEndMinute();
    final text = await ChizukService.getReminderText();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int offset = 0; offset < _chizukDaysAhead; offset++) {
      final targetDate = today.add(Duration(days: offset));
      final scheduled = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        reminderHour,
        reminderMinute,
      );

      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

      // היום הלוגי שאליו תתייחס לחיצת המשתמש כשההתראה תופיע:
      // אם שעת התזכורת אחרי סוף-היום של המשתמש — היום הלוגי = targetDate.
      // אחרת — היום הלוגי = יום לפני targetDate.
      final reminderMinutes = reminderHour * 60 + reminderMinute;
      final dayEndMinutes = dayEndHour * 60 + dayEndMinute;
      final logicalDate = reminderMinutes >= dayEndMinutes
          ? targetDate
          : targetDate.subtract(const Duration(days: 1));

      // אם היום הלוגי כבר סומן (התגברות/קושי) — מדלגים.
      final status = await ChizukService.getStatus(logicalDate);
      if (status != null) continue;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelChizuk,
          _channelChizukName,
          channelDescription: _channelChizukDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      await _safeSchedule(
        id: _chizukIdBase + offset,
        title: text,
        body: '',
        when: scheduled,
        details: details,
        // payload ריק בכוונה — אין ניתוב למסך מיוחד.
        payload: '',
      );
    }
  }

  /// מבטל את התזכורת של "היום" (offset=0) — אחרי שהמשתמש סימן בידיים.
  static Future<void> cancelChizukToday() async {
    await _plugin.cancel(_chizukIdBase);
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
