import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:xiaohei_auto_save/data/app_config.dart';
import 'package:xiaohei_auto_save/services/preferences_manager.dart';
import 'package:xiaohei_auto_save/ui/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    title: '${AppConfig.appName} v${AppConfig.version}',
    size: Size(600, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  final savedThemeColor = await PreferencesManager.getThemeColor();

  runApp(
      MyApp(savedThemeMode: savedThemeMode, savedThemeColor: savedThemeColor));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final Color? savedThemeColor;

  const MyApp({super.key, this.savedThemeMode, this.savedThemeColor});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: savedThemeColor ?? Colors.deepPurple,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: savedThemeColor ?? Colors.deepPurple,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      debugShowFloatingThemeButton: true,
      builder: (theme, darkTheme) => MaterialApp(
        title: AppConfig.appName,
        theme: theme,
        darkTheme: darkTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
        ],
        home: const MyHomePage(),
      ),
    );
  }
}
