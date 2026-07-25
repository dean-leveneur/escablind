/// Donnees d'une balise BLE detectee sur la voie.
///
/// Chaque balise est placee a une prise ou un point cle
/// (depart, relais, chaine d'arrivee). Le RSSI indique
/// la proximite: plus il est eleve (proche de 0), plus
/// le grimpeur est pres de la prise.
class BeaconData {
  final int id;
  final String nom;
  final int rssi;
  final DateTime detectedAt;

  const BeaconData({
    required this.id,
    required this.nom,
    required this.rssi,
    required this.detectedAt,
  });

  /// Distance estimee en metres a partir du RSSI.
  /// Formule simplifiee: d = 10^((TxPower - RSSI) / (20 + n))
  /// avec TxPower = -59 dBm et n = 2 (facteur d'atténuation).
  double get estimatedDistance {
    const txPower = -59;
    const n = 2.0;
    return 10.0 * ((txPower - rssi) / (20.0 + n));
  }

  /// Constructeur depuis une trame serie Arduino.
  /// Format attendu: "#POS:3" ou "3"
  factory BeaconData.fromSerial(String line) {
    final cleaned = line.replaceAll('#POS:', '').trim();
    final id = int.tryParse(cleaned) ?? 0;
    return BeaconData(
      id: id,
      nom: 'Prise $id',
      rssi: -50 - (id * 5), // RSSI simule
      detectedAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'BeaconData(id: $id, nom: $nom, rssi: $rssi)';
}

/// Enumeration des types de messages provenant de l'Arduino.
enum ArduinoMessageType {
  position,     // #POS:<id>
  distance,     // #DIST:<cm>
  vibration,    // #VIB:<valeur>
  status,       // #STAT:<msg>
  error,        // #ERR:<code>
  unknown,
}

/// Message brut provenant de l'Arduino via la liaison serie.
class ArduinoMessage {
  final ArduinoMessageType type;
  final String raw;
  final String value;

  const ArduinoMessage({
    required this.type,
    required this.raw,
    required this.value,
  });

  /// Parse une ligne serie en un message structure.
  factory ArduinoMessage.parse(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#POS:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.position,
        raw: trimmed,
        value: trimmed.substring(5),
      );
    } else if (trimmed.startsWith('#DIST:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.distance,
        raw: trimmed,
        value: trimmed.substring(6),
      );
    } else if (trimmed.startsWith('#VIB:')) {
      return ArduinoMessage(
        type: ArduinoMessageType.vibration,
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