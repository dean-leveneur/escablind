import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/guidance_screen.dart';
import 'services/ble_service.dart';
import 'services/audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EscaBlindApp());
}

/// Application EscaBlind - Guidage audio pour l'escalade
///
/// Point d'entree de l'application Flutter. Fournit les services
/// BLE et Audio via Provider, et configure le routage entre les
/// ecrans.
class EscaBlindApp extends StatelessWidget {
  const EscaBlindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BleService>(
          create: (_) => BleService(),
        ),
        ChangeNotifierProvider<AudioService>(
          create: (_) => AudioService(),
        ),
      ],
      child: MaterialApp(
        title: 'EscaBlind',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          // Large typography pour accessibilite
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 22),
            bodyMedium: TextStyle(fontSize: 18),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/guidance': (context) => const GuidanceScreen(),
        },
      ),
    );
  }
}