/// Modèle représentant une prise / cible sur le mur d'escalade.
class ClimbingWaypoint {
  final int id;
  final String name;
  final double x; // Coordonnée X Pozyx UWB (cm)
  final double y; // Coordonnée Y Pozyx UWB (cm)
  final double z; // Coordonnée Z / Hauteur Pozyx UWB (cm)

  const ClimbingWaypoint({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.z,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'z': z,
      };

  factory ClimbingWaypoint.fromJson(Map<String, dynamic> json) =>
      ClimbingWaypoint(
        id: json['id'] as int,
        name: json['name'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        z: (json['z'] as num).toDouble(),
      );
}

/// Modèle d'un parcours / voie d'escalade enregistrée.
class ClimbingRoute {
  final String id;
  final String title;
  final String difficulty;
  final List<ClimbingWaypoint> waypoints;

  const ClimbingRoute({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.waypoints,
  });

  int get count => waypoints.length;
}
