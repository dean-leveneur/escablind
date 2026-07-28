import 'dart:math';

/// Position 3D transmise par le Tag Pozyx UWB via l'Arduino.
class PozyxPosition {
  final double x; // cm
  final double y; // cm
  final double z; // cm (hauteur)
  final DateTime timestamp;

  const PozyxPosition({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// Calcule la distance 3D euclidienne (en cm) vers un point cible.
  double distanceTo(double targetX, double targetY, double targetZ) {
    final dx = targetX - x;
    final dy = targetY - y;
    final dz = targetZ - z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Constructeur depuis la trame série BLE `#POS_UWB:120,80,150`
  factory PozyxPosition.fromSerial(String line) {
    final cleaned = line.replaceAll('#POS_UWB:', '').trim();
    final parts = cleaned.split(',');
    if (parts.length >= 3) {
      final px = double.tryParse(parts[0]) ?? 0.0;
      final py = double.tryParse(parts[1]) ?? 0.0;
      final pz = double.tryParse(parts[2]) ?? 0.0;
      return PozyxPosition(
        x: px,
        y: py,
        z: pz,
        timestamp: DateTime.now(),
      );
    }
    return PozyxPosition(x: 0, y: 0, z: 0, timestamp: DateTime.now());
  }

  @override
  String toString() => 'PozyxPosition(x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)}, z: ${z.toStringAsFixed(1)})';
}

/// Types de messages de communication entre l'Arduino et l'application.
enum ArduinoMessageType {
  pozyxPosition, // #POS_UWB:<x>,<y>,<z>
  vibrationAck,  // #VIB:<valeur>
  status,        // #STAT:<msg>
  error,         // #ERR:<code>
  unknown,
}

/// Structure d'un message brut reçu de l'Arduino.
class ArduinoMessage {
  final ArduinoMessageType type;
  final String raw;
  final String value;

  const ArduinoMessage({
    required this.type,
    required this.raw,
    required this.value,
  });

  factory ArduinoMessage.parse(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#POS_UWB:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.pozyxPosition,
        raw: trimmed,
        value: trimmed.substring(9),
      );
    } else if (trimmed.startsWith('#VIB:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.vibrationAck,
        raw: trimmed,
        value: trimmed.substring(5),
      );
    } else if (trimmed.startsWith('#STAT:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.status,
        raw: trimmed,
        value: trimmed.substring(6),
      );
    } else if (trimmed.startsWith('#ERR:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.error,
        raw: trimmed,
        value: trimmed.substring(5),
      );
    }
    return ArduinoMessage(
      type: ArduinoMessageType.unknown,
      raw: trimmed,
      value: trimmed,
    );
  }
}