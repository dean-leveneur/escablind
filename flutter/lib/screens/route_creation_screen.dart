import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/climbing_route.dart';
import '../services/ble_service.dart';

/// Écran « Créer un parcours ».
///
/// Permet l'enregistrement d'une suite de positions successives (coordonnées UWB Pozyx)
/// pour composer une nouvelle voie d'escalade.
class RouteCreationScreen extends StatefulWidget {
  const RouteCreationScreen({super.key});

  @override
  State<RouteCreationScreen> createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  final _titleController = TextEditingController(text: 'Nouvelle Voie Perso');
  final _difficultyController = TextEditingController(text: '5C');
  final List<ClimbingWaypoint> _recordedWaypoints = [];

  void _recordCurrentPosition(BleService ble) {
    final pos = ble.currentPosition;
    final id = _recordedWaypoints.length + 1;
    final name = id == 1 ? 'Prise de Départ' : 'Prise n°$id';

    // Capture des coordonnées UWB (ou position simulée si non disponible)
    final double x = pos?.x ?? (100.0 + _recordedWaypoints.length * 15);
    final double y = pos?.y ?? 50.0;
    final double z = pos?.z ?? (80.0 + _recordedWaypoints.length * 60);

    setState(() {
      _recordedWaypoints.add(ClimbingWaypoint(
        id: id,
        name: name,
        x: x,
        y: y,
        z: z,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Position n°$id enregistrée (X:${x.round()}, Y:${y.round()}, Z:${z.round()})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveRoute(BleService ble) {
    if (_recordedWaypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez enregistrer au moins une prise cible.')),
      );
      return;
    }

    final newRoute = ClimbingRoute(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      difficulty: _difficultyController.text,
      waypoints: List.from(_recordedWaypoints),
    );

    ble.addCustomRoute(newRoute);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Parcours « ${newRoute.title} » créé avec succès !')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Créer un parcours'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations voie
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom de la voie',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _difficultyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Cotation / Niveau (ex: 5C, 6A)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton Enregistrer Position Courante
              Consumer<BleService>(
                builder: (context, ble, _) {
                  return ElevatedButton.icon(
                    onPressed: () => _recordCurrentPosition(ble),
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      'Enregistrer position n°${_recordedWaypoints.length + 1}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Prises successives enregistrées :',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Liste des positions capturées
              Expanded(
                child: _recordedWaypoints.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune position enregistrée pour le moment.\nAppuyez sur le bouton ci-dessus devant chaque prise.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _recordedWaypoints.length,
                        itemBuilder: (context, index) {
                          final wp = _recordedWaypoints[index];
                          return Card(
                            color: Colors.white10,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text('#${wp.id}', style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(wp.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'X: ${wp.x.round()} cm, Y: ${wp.y.round()} cm, Z: ${wp.z.round()} cm',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _recordedWaypoints.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bouton Valider
              Consumer<BleService>(
                builder: (context, ble, _) {
                  return ElevatedButton(
                    onPressed: () => _saveRoute(ble),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enregistrer le parcours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
