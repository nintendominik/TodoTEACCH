import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/pages/all_plans_page.dart';
import 'package:todoapp/pages/create_plan_page.dart';
import 'package:todoapp/pages/home_page.dart';
import 'package:todoapp/pages/task_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:todoapp/provider/speech_control_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';  // Import the generated localization file

void main() {
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SpeechControlProvider()),
        ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('de');

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEACCH Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/tasks': (context) => const TaskPage(),
        '/create_plan': (context) => const CreatePlanPage(filePath: ""),
        '/all_plans': (context) => const AllPlansPage()
      },
      locale: _locale,
      supportedLocales: const [
        Locale('de'),
        Locale('uk'),
        Locale('hr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Handle locale resolution based on supported locales
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Default to the first supported locale
      },
    );
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
}
