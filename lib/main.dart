import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'ui/login_page.dart';
import 'ui/splash_screen.dart';
import 'cubit/location_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  await NotificationService().initialize();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationCubit(),
      child: MaterialApp(
        title: 'PresensiPlus',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: 'Sans-Serif',
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),
        routes: {'/login': (context) => const LoginScreen()},
        home: const SplashScreen(),
      ),
    );
  }
}
