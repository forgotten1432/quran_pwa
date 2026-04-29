import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/preferences_service.dart';
import 'screens/quran_reader_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS: Transparent status bar for standalone PWA look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark, // iOS: light content on dark bg
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  final prefsService = PreferencesService();
  await prefsService.init();

  runApp(QuranApp(prefsService: prefsService));
}

class QuranApp extends StatefulWidget {
  final PreferencesService prefsService;

  const QuranApp({super.key, required this.prefsService});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefsService.getDarkMode();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      widget.prefsService.saveDarkMode(_isDarkMode);

      // Update status bar style based on theme
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'القرآن الكريم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('ar'),
      // iOS: Prevent text scaling from affecting layout
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
      home: QuranReaderScreen(
        prefsService: widget.prefsService,
        onToggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}
