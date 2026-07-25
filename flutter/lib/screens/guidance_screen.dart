import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beacon_data.dart';
import '../services/ble_service.dart';
import '../services/audio_service.dart';

/// Ecran de guidage pendant l'ascension.
///
/// Affiche en temps reel la balise detectee, la distance
/// au mur, et les alertes. Le guidage vocal est declenche
/// automatiquement a chaque detection de balise.
class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key});

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  StreamSubscription<String>? _audioSubscription;

  @override
  void initState() {
    super.initState();
    // Ecoute la file audio pour les messages en attente
    _audioSubscription = context
        .read<AudioService>()
        .messageStream
        .listen((message) {
      context.read<AudioService>().speak(message);
    });
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Barre d'etat
            _StatusBar(),
            Expanded(
              child: Center(
                child: Consumer2<BleService, AudioService>(
                  builder: (context, ble, audio, _) {
                    final beacons = ble.beaconsDetected;
                    final lastBeacon = beacons.isNotEmpty
                        ? beacons.last
                        : null;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Balise courante
                        if (lastBeacon != null)
                          _BeaconIndicator(beacon: lastBeacon)
                        else
                          const Text(
                            'En attente de balise...',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 24,
                            ),
                          ),

                        const SizedBox(height: 48),

                        // Commandes vocales
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlButton(
                              icon: Icons.hearing,
                              label: 'Répéter',
                              onTap: () {
                                if (lastBeacon != null) {
                                  audio.announceBeacon(
                                    lastBeacon.id,
                                    lastBeacon.nom,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            _ControlButton(
                              icon: Icons.mic,
                              label: 'Infos voie',
                              onTap: () {
                                audio.speak(
                                  'Voie équipée de 6 points d\'ancrage. '
                                  'Départ au niveau 1, arrivée au niveau 6.',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Historique des balises
            _BeaconHistory(),
          ],
        ),
      ),
    );
  }
}

/// Barre d'etat superieure.
class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black26,
          child: Row(
            children: [
              Icon(
                Icons.bluetooth_connected,
                color: ble.isConnected ? Colors.greenAccent : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white70),
                tooltip: 'Arrêter guidage',
                onPressed: () {
                  context.read<AudioService>().speak('Guidage terminé.');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Indicateur visuel de la balise courante.
class _BeaconIndicator extends StatelessWidget {
  final BeaconData beacon;

  const _BeaconIndicator({required this.beacon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.greenAccent,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'Prise n°${beacon.id}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          beacon.nom,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RSSI: ${beacon.rssi} dBm',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

/// Bouton de controle.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Historique des balises detectees.
class _BeaconHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        final beacons = ble.beaconsDetected;
        if (beacons.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border(
              top: BorderSide(color: Colors.white12),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: beacons.length,
            itemBuilder: (context, index) {
              final b = beacons[index];
              final isLast = index == beacons.length - 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLast ? Colors.greenAccent.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${b.id}',
                      style: TextStyle(
                        color: isLast ? Colors.greenAccent : Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${b.rssi} dBm',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}