import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/beacon_data.dart';

/// Service Bluetooth BLE.
///
/// Gere la connexion avec la carte Arduino et le parsing
/// des trames serie recues. Expose un flux de donnees
/// structurees (balises detectees, distance, etat).
class BleService extends ChangeNotifier {
  // --- Etat ---
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _dataSubscription;
  final List<BeaconData> _beaconsDetected = [];
  String _lastMessage = '';
  String _deviceName = '';

  // --- Getters ---
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get deviceName => _deviceName;
  List<BeaconData> get beaconsDetected => List.unmodifiable(_beaconsDetected);
  String get lastMessage => _lastMessage;

  /// Demarre le scan des peripheriques BLE.
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      notifyListeners();

      // Verification que le Bluetooth est active
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

  /// Connecte le peripherique Arduino et ecoute les donnees.
  Future<void> _connect() async {
    if (_device == null) return;

    try {
      await _device!.connect();
      _isConnected = true;
      notifyListeners();

      // Decouverte des services
      List<BluetoothService> services = await _device!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            // Ecoute la caracteristique UART/Serial
            _dataSubscription = characteristic.onValueReceived.listen(
              _onDataReceived,
              onError: (error) {
                debugPrint('Erreur reception BLE: $error');
              },
            );
            await characteristic.setNotifyValue(true);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur connexion BLE: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Traite les donnees recues de l'Arduino.
  void _onDataReceived(List<int> data) {
    final String message = String.fromCharCodes(data);
    _lastMessage = message;
    debugPrint('BLE recu: $message');

    final parsed = ArduinoMessage.parse(message);

    switch (parsed.type) {
      case ArduinoMessageType.position:
        final beacon = BeaconData.fromSerial(parsed.value);
        _beaconsDetected.add(beacon);
        debugPrint('Balise detectee: $beacon');
        break;

      case ArduinoMessageType.distance:
        debugPrint('Distance: ${parsed.value} cm');
        break;

      case ArduinoMessageType.vibration:
        debugPrint('Vibration detectee: ${parsed.value}');
        break;

      case ArduinoMessageType.error:
        debugPrint('Erreur Arduino: code ${parsed.value}');
        break;

      case ArduinoMessageType.status:
      case ArduinoMessageType.unknown:
        break;
    }

    notifyListeners();
  }

  /// Deconnecte le peripherique.
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _device?.disconnect();
    _isConnected = false;
    _device = null;
    _beaconsDetected.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}