import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // בלי להוריד פונטים ברקע (הימנעות מבעיות רשת ו-render חסום)
  GoogleFonts.config.allowRuntimeFetching = false;

  // במקום "מסך לבן אטום" ב-release כשהיתה שגיאה - הראה כרטיס שגיאה ברור
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: AppColors.bgDeep,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        "שגיאה:\n${details.exceptionAsString()}",
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
            color: Color(0xFFF8F4E3), fontSize: 15, height: 1.6),
      ),
    );
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgLight,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // מפעיל את ה-UI מיד, לא מחכים להתראות ולהרשאות
  runApp(const OmerApp());

  // אתחול התראות ברקע - לא חוסם UI
  _bootstrapBackground();
}

Future<void> _bootstrapBackground() async {
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e) {
    debugPrint("orientation err: $e");
  }
  try {
    await NotificationService.init();
    await NotificationService.scheduleAllReminders();
  } catch (e) {
    debugPrint("notif init err: $e");
  }
  try {
    if (await PreferencesService.isFirstLaunch()) {
      await PreferencesService.markFirstLaunchDone();
    }
  } catch (e) {
    debugPrint("prefs err: $e");
  }
}

class OmerApp extends StatelessWidget {
  const OmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'זוכרים',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: const Locale('he', 'IL'),
      supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
