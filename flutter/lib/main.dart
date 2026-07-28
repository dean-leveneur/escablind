import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/route_creation_screen.dart';
import 'screens/route_selection_screen.dart';
import 'screens/guidance_screen.dart';
import 'services/ble_service.dart';
import 'services/audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EscaBlindApp());
}

/// Application EscaBlind - Guidage Haptique et Vocal pour L'Escalade Inclusive.
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
            seedColor: const Color(0xFF0F172A),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/create-route': (context) => const RouteCreationScreen(),
          '/select-route': (context) => const RouteSelectionScreen(),
          '/guidance': (context) => const GuidanceScreen(),
        },
      ),
    );
  }
}