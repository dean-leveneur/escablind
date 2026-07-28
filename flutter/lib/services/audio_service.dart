import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/beacon_data.dart';
import '../models/climbing_route.dart';

/// Service de guidage vocal oralisé (Text-To-Speech).
///
/// Calcule et énonce à l'oral les instructions de direction et de position relative (X, Y, Z)
/// entre la carte Arduino (Pozyx UWB) et la prise cible suivante.
class AudioService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final StreamController<String> _messageQueue = StreamController<String>.broadcast();
  bool _isSpeaking = false;

  // Configuration TTS
  double _volume = 1.0;
  double _rate = 0.48; // Vitesse de parole fluide pour l'escalade
  double _pitch = 1.0;
  String _language = 'fr-FR';

  AudioService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(_language);
    await _tts.setVolume(_volume);
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  /// Énonce un message vocal immédiatement ou le met en file d'attente.
  Future<void> speak(String message) async {
    if (_isSpeaking) {
      _messageQueue.add(message);
      return;
    }

    _isSpeaking = true;
    notifyListeners();
    await _tts.speak(message);
  }

  /// Calcule et annonce à l'oral la position relative de la prise suivante par rapport à l'Arduino.
  Future<void> announceRelativeTarget(PozyxPosition? currentPos, ClimbingWaypoint target) async {
    if (currentPos == null) {
      await speak('Cible sélectionnée : ${target.name}. En attente du signal Pozyx UWB.');
      return;
    }

    final dx = target.x - currentPos.x; // cm (positif = droite, négatif = gauche)
    final dy = target.y - currentPos.y; // cm (profondeur)
    final dz = target.z - currentPos.z; // cm (positif = plus haut, négatif = plus bas)
    final totalDistance = currentPos.distanceTo(target.x, target.y, target.z);

    final StringBuffer sb = StringBuffer();
    sb.write('Prochaine prise : ${target.name}. ');

    // Indication Hauteur (Axe Z)
    if (dz.abs() > 10) {
      if (dz > 0) {
        sb.write('${dz.round()} centimètres plus haut, ');
      } else {
        sb.write('${dz.abs().round()} centimètres plus bas, ');
      }
    }

    // Indication Latérale (Axe X)
    if (dx.abs() > 10) {
      if (dx > 0) {
        sb.write('${dx.round()} centimètres sur votre droite. ');
      } else {
        sb.write('${dx.abs().round()} centimètres sur votre gauche. ');
      }
    } else {
      sb.write('dans l\'axe vertical. ');
    }

    sb.write('Distance totale ${totalDistance.round()} centimètres.');

    await speak(sb.toString());
  }

  /// Énonce le succès d'arrivée au sommet de la voie.
  Future<void> announceRouteCompleted(String routeTitle) async {
    await speak('Félicitations ! Vous avez atteint le relais et terminé la voie $routeTitle.');
  }

  /// Arrête la lecture vocale.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  Stream<String> get messageStream => _messageQueue.stream;

  @override
  void dispose() {
    _messageQueue.close();
    _tts.stop();
    super.dispose();
  }
}