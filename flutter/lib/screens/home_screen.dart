import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';

/// Écran d'accueil EscaBlind.
///
/// Propose les fonctionnalités principales :
///   1. Bouton « Créer un parcours » (Enregistrement de positions successives UWB)
///   2. Bouton « Sélection du parcours » (Menu de sélection de la voie)
///   3. Connexion Bluetooth BLE et démarrage du guidage.
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
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête / Logo
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.terrain, size: 48, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'EscaBlind',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Guidage Haptique & Vocal (UWB Pozyx)',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Carte statut Bluetooth BLE
                const _BluetoothStatusCard(),
                const SizedBox(height: 24),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bouton 1 : CREER UN PARCOURS
                      _MenuActionButton(
                        icon: Icons.add_location_alt_rounded,
                        title: 'Créer un parcours',
                        subtitle: 'Enregistrer une suite de prises cibles (Pozyx UWB)',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.pushNamed(context, '/create-route');
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bouton 2 : SELECTION DU PARCOURS
                      _MenuActionButton(
                        icon: Icons.format_list_bulleted_rounded,
                        title: 'Sélection du parcours',
                        subtitle: 'Choisir parmi les voies d\'escalade enregistrées',
                        color: const Color(0xFF0D9488),
                        onTap: () {
                          Navigator.pushNamed(context, '/select-route');
                        },
                      ),
                      const SizedBox(height: 16),

                      // Bouton 3 : LANCER LE GUIDAGE
                      Consumer<BleService>(
                        builder: (context, ble, _) {
                          final isReady = ble.isConnected && ble.selectedRoute != null;
                          return _MenuActionButton(
                            icon: Icons.navigation_rounded,
                            title: 'Démarrer le guidage',
                            subtitle: ble.selectedRoute != null
                                ? 'Voie active : ${ble.selectedRoute!.title}'
                                : 'Veuillez sélectionner un parcours',
                            color: isReady ? const Color(0xFF16A34A) : Colors.grey.shade700,
                            onTap: isReady
                                ? () => Navigator.pushNamed(context, '/guidance')
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget bouton d'action du menu principal.
class _MenuActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _MenuActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: enabled ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: enabled ? color : Colors.white24,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled ? color : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.white : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: enabled ? Colors.white70 : Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de statut Bluetooth BLE.
class _BluetoothStatusCard extends StatelessWidget {
  const _BluetoothStatusCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ble.isConnected ? Colors.greenAccent : Colors.amber,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                ble.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                color: ble.isConnected ? Colors.greenAccent : Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ble.isConnected
                          ? 'Arduino Connecté (${ble.deviceName})'
                          : ble.isScanning
                              ? 'Recherche BLE en cours...'
                              : 'Carte Arduino déconnectée',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      ble.isConnected
                          ? 'Signal UWB Pozyx & Vibreur prêts'
                          : 'Appuyez pour appairer le module BLE',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (!ble.isConnected)
                ElevatedButton(
                  onPressed: () => ble.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(ble.isScanning ? 'Scan...' : 'Connecter'),
                ),
            ],
          ),
        );
      },
    );
  }
}