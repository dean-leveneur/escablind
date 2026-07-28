import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/beacon_data.dart';
import '../models/climbing_route.dart';

/// Service Bluetooth BLE EscaBlind.
///
/// Gère la réception des coordonnées UWB Pozyx depuis la carte Arduino
/// et transmet en temps réel les consignes d'intensité PWM du vibreur haptique.
class BleService extends ChangeNotifier {
  // --- État BLE ---
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  String _deviceName = '';

  // --- Pozyx UWB & Parcours ---
  PozyxPosition? _currentPosition;
  ClimbingRoute? _selectedRoute;
  int _currentWaypointIndex = 0;
  int _lastVibrationIntensity = 0;

  // Voies pré-enregistrées de démonstration
  final List<ClimbingRoute> _availableRoutes = [
    const ClimbingRoute(
      id: 'route-5a',
      title: 'Voie Bleue — Initiation (5A)',
      difficulty: '5A',
      waypoints: [
        ClimbingWaypoint(id: 1, name: 'Prise de Départ (Main G)', x: 100, y: 50, z: 100),
        ClimbingWaypoint(id: 2, name: 'Bac central droit', x: 140, y: 50, z: 160),
        ClimbingWaypoint(id: 3, name: 'Prise intermédiaire gauche', x: 90, y: 50, z: 220),
        ClimbingWaypoint(id: 4, name: 'Reglette supérieure', x: 120, y: 50, z: 290),
        ClimbingWaypoint(id: 5, name: 'Relais Sommet', x: 110, y: 50, z: 360),
      ],
    ),
    const ClimbingRoute(
      id: 'route-6b',
      title: 'Voie Rouge — Défi (6B)',
      difficulty: '6B',
      waypoints: [
        ClimbingWaypoint(id: 1, name: 'Départ assis', x: 80, y: 50, z: 80),
        ClimbingWaypoint(id: 2, name: 'Pince verticale droite', x: 160, y: 50, z: 150),
        ClimbingWaypoint(id: 3, name: 'Trousse centrale', x: 110, y: 50, z: 240),
        ClimbingWaypoint(id: 4, name: 'Jarre de sortie', x: 130, y: 50, z: 330),
      ],
    ),
  ];

  // --- Getters ---
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get deviceName => _deviceName;
  PozyxPosition? get currentPosition => _currentPosition;
  ClimbingRoute? get selectedRoute => _selectedRoute;
  List<ClimbingRoute> get availableRoutes => List.unmodifiable(_availableRoutes);
  int get currentWaypointIndex => _currentWaypointIndex;
  int get lastVibrationIntensity => _lastVibrationIntensity;

  ClimbingWaypoint? get currentTargetWaypoint {
    if (_selectedRoute == null || _selectedRoute!.waypoints.isEmpty) return null;
    if (_currentWaypointIndex >= _selectedRoute!.waypoints.length) return null;
    return _selectedRoute!.waypoints[_currentWaypointIndex];
  }

  BleService() {
    _selectedRoute = _availableRoutes.first;
  }

  void selectRoute(ClimbingRoute route) {
    _selectedRoute = route;
    _currentWaypointIndex = 0;
    notifyListeners();
  }

  void addCustomRoute(ClimbingRoute route) {
    _availableRoutes.add(route);
    _selectedRoute = route;
    _currentWaypointIndex = 0;
    notifyListeners();
  }

  void nextWaypoint() {
    if (_selectedRoute != null && _currentWaypointIndex < _selectedRoute!.waypoints.length - 1) {
      _currentWaypointIndex++;
      notifyListeners();
    }
  }

  void previousWaypoint() {
    if (_currentWaypointIndex > 0) {
      _currentWaypointIndex--;
      notifyListeners();
    }
  }

  /// Démarre le scan des périphériques BLE.
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      notifyListeners();

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.advertisementData.advName.contains('ESCABLIND')) {
            _device = r.device;
            _deviceName = r.advertisementData.advName;
            FlutterBluePlus.stopScan();
            _isScanning = false;
            notifyListeners();
            _connect();
            return;
          }
        }
      });

      await FlutterBluePlus.startScan(
        withKeywords: ['ESCABLIND'],
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Erreur scan BLE: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Connexion et écoute des notifications BLE.
  Future<void> _connect() async {
    if (_device == null) return;

    try {
      await _device!.connect();
      _isConnected = true;
      notifyListeners();

      List<BluetoothService> services = await _device!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            _dataSubscription = characteristic.onValueReceived.listen(_onDataReceived);
            await characteristic.setNotifyValue(true);
          }
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur connexion BLE: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Traite la position UWB reçue de l'Arduino et met à jour l'intensité du vibreur haptique.
  void _onDataReceived(List<int> data) {
    final String message = String.fromCharCodes(data);
    final parsed = ArduinoMessage.parse(message);

    if (parsed.type == ArduinoMessageType.pozyxPosition) {
      _currentPosition = PozyxPosition.fromSerial(parsed.value);
      _updateHapticProximityFeedback();
      notifyListeners();
    }
  }

  /// Calcule la proximité par rapport à la prise cible et envoie l'intensité PWM (0-255) à l'Arduino.
  void _updateHapticProximityFeedback() {
    final target = currentTargetWaypoint;
    final pos = _currentPosition;
    if (target == null || pos == null) return;

    final distCm = pos.distanceTo(target.x, target.y, target.z);

    // Calcul de l'intensité PWM :
    // - Si dist > 150 cm : vibration nulle (0)
    // - Si dist < 150 cm : intensité croissante jusqu'à 255 quand dist -> 5 cm
    int intensity = 0;
    if (distCm < 150) {
      double ratio = (150.0 - distCm) / 145.0;
      ratio = max(0.0, min(1.0, ratio));
      intensity = (ratio * 255).round();
    }

    _lastVibrationIntensity = intensity;
    _sendVibrationCommand(intensity);
  }

  /// Transmet la trame `#VIB_INT:<0-255>` à la carte Arduino via BLE.
  Future<void> _sendVibrationCommand(int pwmIntensity) async {
    if (_writeCharacteristic != null && _isConnected) {
      try {
        final payload = '#VIB_INT:$pwmIntensity\n';
        await _writeCharacteristic!.write(payload.codeUnits, withoutResponse: true);
      } catch (e) {
        debugPrint('Erreur écriture BLE: $e');
      }
    }
  }

  /// Déconnexion BLE.
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _device?.disconnect();
    _isConnected = false;
    _device = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}