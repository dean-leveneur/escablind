import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/audio_service.dart';

/// Écran de guidage en temps réel pendant l'ascension.
///
/// Affiche :
///   1. Les coordonnées UWB Pozyx temps réel de l'Arduino.
///   2. La prise cible active et l'écart relatif (dx, dy, dz).
///   3. L'intensité du vibreur haptique PWM (0-255).
///   4. Boutons pour réécouter la consigne vocale orale.
class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key});

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  @override
  void initState() {
    super.initState();
    // Énoncé vocal au démarrage du guidage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleService>();
      final audio = context.read<AudioService>();
      if (ble.selectedRoute != null) {
        audio.speak('Début du guidage pour la voie ${ble.selectedRoute!.title}.');
        if (ble.currentTargetWaypoint != null) {
          audio.announceRelativeTarget(ble.currentPosition, ble.currentTargetWaypoint!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Guidage Temps Réel'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
            tooltip: 'Annoncer la position orale',
            onPressed: () {
              final ble = context.read<BleService>();
              final audio = context.read<AudioService>();
              if (ble.currentTargetWaypoint != null) {
                audio.announceRelativeTarget(ble.currentPosition, ble.currentTargetWaypoint!);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<BleService, AudioService>(
          builder: (context, ble, audio, _) {
            final route = ble.selectedRoute;
            final target = ble.currentTargetWaypoint;
            final pos = ble.currentPosition;
            final pwm = ble.lastVibrationIntensity;

            if (route == null || target == null) {
              return const Center(
                child: Text('Aucun parcours sélectionné.', style: TextStyle(color: Colors.white)),
              );
            }

            final distCm = pos != null ? pos.distanceTo(target.x, target.y, target.z) : 0.0;
            final dx = pos != null ? target.x - pos.x : 0.0;
            final dz = pos != null ? target.z - pos.z : 0.0;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Carte Prise Cible
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Prise ${ble.currentWaypointIndex + 1} / ${route.count}',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          target.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MetricItem(label: 'Distance Cible', value: '${distCm.round()} cm'),
                            _MetricItem(label: 'Décalage Ht (Z)', value: '${dz.round()} cm'),
                            _MetricItem(label: 'Décalage Lat (X)', value: '${dx.round()} cm'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Jauge Vibreur Haptique (PWM)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.vibration, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Intensité Vibreur Arduino', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text('PWM $pwm / 255', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pwm / 255.0,
                            minHeight: 12,
                            backgroundColor: Colors.white10,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Position Pozyx UWB actuelle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radar, color: Colors.greenAccent),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Position Arduino Pozyx UWB :', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              pos != null
                                  ? 'X: ${pos.x.round()} cm, Y: ${pos.y.round()} cm, Z: ${pos.z.round()} cm'
                                  : 'En attente des trames Pozyx...',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Navigation Prises
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: ble.currentWaypointIndex > 0 ? () => ble.previousWaypoint() : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Prise préc.'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (ble.currentWaypointIndex < route.count - 1) {
                              ble.nextWaypoint();
                              audio.announceRelativeTarget(ble.currentPosition, ble.currentTargetWaypoint!);
                            } else {
                              audio.announceRouteCompleted(route.title);
                            }
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(ble.currentWaypointIndex < route.count - 1 ? 'Prise suiv.' : 'Terminer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}