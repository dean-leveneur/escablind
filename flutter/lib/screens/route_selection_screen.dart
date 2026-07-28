import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';

/// Écran « Sélection du parcours ».
///
/// Propose un menu de sélection parmi les voies d'escalade enregistrées.
class RouteSelectionScreen extends StatelessWidget {
  const RouteSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Sélection du parcours'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<BleService>(
            builder: (context, ble, _) {
              final routes = ble.availableRoutes;
              final selectedId = ble.selectedRoute?.id;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choisissez votre voie d\'escalade :',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final isSelected = route.id == selectedId;

                        return Card(
                          color: isSelected
                              ? const Color(0xFF0D9488).withOpacity(0.3)
                              : Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0D9488) : Colors.white12,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () {
                              ble.selectRoute(route);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Parcours « ${route.title} » sélectionné')),
                              );
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      route.difficulty,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          route.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${route.count} prises enregistrées',
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 28),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
