import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tickeo/providers/auth_provider.dart';
import 'package:tickeo/providers/bill_provider.dart';
import 'package:tickeo/providers/app_provider.dart';
import 'package:tickeo/screens/home_screen.dart';
import 'package:tickeo/screens/welcome_screen.dart';
import 'package:tickeo/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TickeoApp());
}

class TickeoApp extends StatelessWidget {
  const TickeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => BillProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Tickeo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            home: const AppNavigator(),
          );
        },
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Setup BillProvider reference to AuthProvider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final billProvider = Provider.of<BillProvider>(context, listen: false);
          billProvider.setAuthProvider(authProvider);
        });

        // Show welcome screen if user hasn't seen it yet
        if (!authProvider.hasSeenWelcome) {
          return const WelcomeScreen();
        }

        // Show home screen for all other cases
        return const HomeScreen();
      },
    );
  }
}
