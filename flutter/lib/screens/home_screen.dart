import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';

/// Ecran d'accueil.
///
/// Affiche l'etat de la connexion BLE, le nom du peripherique,
/// et le bouton de lancement du guidage.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color(0xFF01579B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / icone
                  const Icon(
                    Icons.terrain,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'EscaBlind',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Escalade guidée pour personnes malvoyantes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Etat Bluetooth
                  _BluetoothStatusCard(),
                  const SizedBox(height: 24),

                  // Bouton demarrer
                  Consumer<BleService>(
                    builder: (context, ble, _) {
                      if (!ble.isConnected) {
                        return SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: () => ble.startScan(),
                            icon: const Icon(Icons.bluetooth_searching),
                            label: Text(
                              ble.isScanning
                                  ? 'Recherche...'
                                  : 'Connecter l\'Arduino',
                              style: const TextStyle(fontSize: 20),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A237E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/guidance');
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text(
                            'Commencer l\'ascension',
                            style: TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte d'etat Bluetooth.
class _BluetoothStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        return Card(
          color: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ble.isConnected
                      ? Icons.bluetooth_connected
                      : ble.isScanning
                          ? Icons.bluetooth_searching
                          : Icons.bluetooth_disabled,
                  color: ble.isConnected
                      ? Colors.greenAccent
                      : Colors.white54,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ble.isConnected
                          ? 'Connecté'
                          : ble.isScanning
                              ? 'Scan en cours...'
                              : 'Déconnecté',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    if (ble.isConnected && ble.deviceName.isNotEmpty)
                      Text(
                        ble.deviceName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}