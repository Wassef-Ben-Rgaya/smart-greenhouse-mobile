import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/kpi_service.dart';
import 'screens/Dashboard_screen.dart';
import 'screens/measurements_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'models/user.dart';
import 'screens/home_screen.dart';
import 'screens/profile_management_screen.dart';
import 'screens/plants_screen.dart';
import 'screens/my_cultures_screen.dart';
import 'screens/environments_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('Création de KPIService');
            return KPIService();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Serre Intelligente',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color.fromARGB(255, 57, 157, 61),
            foregroundColor: Colors.white,
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CustomPageTransitionBuilder(),
              TargetPlatform.iOS: CustomPageTransitionBuilder(),
            },
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile-management': (context) => const ProfileManagementScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/plants': (context) => const PlantsScreen(),
          '/my-cultures': (context) => const MyCulturesScreen(),
          '/environments': (context) => const MyEnvironnementsScreen(),
          '/measurements': (context) => const MeasurementsScreen(),
          '/alerts': (context) => const AlertsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/history': (context) => const HistoryScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            final args = settings.arguments;
            if (args is UserModel) {
              return MaterialPageRoute(
                builder: (context) => HomeWrapper(user: args),
              );
            } else {
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == '/login') {
      return FadeTransition(opacity: animation, child: child);
    }

    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(position: offsetAnimation, child: child);
  }
}
