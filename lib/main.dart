import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sahana/core/theme/app_colors.dart';

import 'package:sahana/l10n/app_localizations.dart';
import 'package:sahana/core/providers/locale_provider.dart';
import 'package:sahana/core/services/notification_service.dart';
import 'package:sahana/features/calls/widgets/call_listener_wrapper.dart';
import 'package:sahana/features/splash/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LocaleProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryGreen,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
          ),
          locale: localeProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return CallListenerWrapper(child: child!);
          },
          home: Builder(
            builder: (context) {
              // Set context for notification service
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NotificationService.setContext(context);
              });
              return const SplashScreen();
            },
          ),
        );
      },
    );
  }
}
