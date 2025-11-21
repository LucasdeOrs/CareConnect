import 'package:careconnect_app/core/constants/app_colors.dart';
import 'package:careconnect_app/screens/auth/complete_profile/complete_caregiver_profile_screen.dart';
import 'package:careconnect_app/screens/auth/complete_profile/complete_profile_screen.dart';
import 'package:careconnect_app/screens/auth/reset_password/update_password_screen.dart';
import 'package:careconnect_app/screens/main_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'core/constants/constants.dart';
import 'screens/auth/login/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', '');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect',
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      localeResolutionCallback: (locale, supported) => const Locale('pt', 'BR'),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data?.session != null) {
            final authEvent = snapshot.data!.event;

            if (authEvent == AuthChangeEvent.passwordRecovery) {
              return const UpdatePasswordScreen();
            }

            final user = snapshot.data!.session!.user;
            final metadata = user.userMetadata;
            final profileCompleted = metadata?['profile_completed'] ?? false;

            if (profileCompleted) {
              return const MainScreen();
            } else {
              final userType = metadata?['tipo'] ?? 'familiar';

              if (userType == 'cuidador') {
                return const CompleteCaregiverProfileScreen();
              } else {
                return const CompleteProfileScreen();
              }
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
