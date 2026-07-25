import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service de guidage audio.
///
/// Utilise la synthese vocale (TTS) pour guider le grimpeur
/// le long de la voie. Les messages sont priorises et files
/// pour eviter les chevauchements.
class AudioService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final StreamController<String> _messageQueue = StreamController<String>.broadcast();
  bool _isSpeaking = false;

  // --- Configuration TTS ---
  double _volume = 1.0;
  double _rate = 0.45;  // vitesse de parole (0.0 - 1.0)
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

  /// Joue un message vocal immediatement.
  Future<void> speak(String message) async {
    if (_isSpeaking) {
      // File le message pour eviter les chevauchements
      _messageQueue.add(message);
      return;
    }

    _isSpeaking = true;
    notifyListeners();
    await _tts.speak(message);
  }

  /// Guide le grimpeur vers une prise specifique.
  Future<void> announceBeacon(int id, String nom) async {
    String message;
    switch (id) {
      case 1:
        message = 'Prise de départ. Placez votre main gauche.';
        break;
      case 6:
        message = 'Arrivée. Vous avez atteint le sommet.';
        break;
      default:
        message = 'Prochaine prise, numéro $id. $nom.';
    }
    await speak(message);
  }

  /// Indique la distance au mur.
  Future<void> announceDistance(int cm) async {
    if (cm < 30) {
      await speak('Attention, mur proche à $cm centimètres.');
    } else if (cm > 150) {
      await speak('Distance correcte.');
    }
  }

  /// Alerte en cas de vibration/chute.
  Future<void> announceVibration(int valeur) async {
    if (valeur > 700) {
      await speak('Alerte, chute détectée. Restez calme.');
    } else {
      await speak('Mouvement brusque détecté.');
    }
  }

  /// Lit un message d'erreur.
  Future<void> announceError(int code) async {
    switch (code) {
      case 1:
        await speak('Erreur de communication avec la carte.');
        break;
      case 2:
        await speak('Batterie faible.');
        break;
      case 3:
        await speak('Alerte, chute probable. Demandez de l\'aide.');
        break;
      default:
        await speak('Erreur $code. Consultez l\'application.');
    }
  }

  /// Arrete la lecture en cours.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Ecoute la file d'attente (appele en continu).
  Stream<String> get messageStream => _messageQueue.stream;

  @override
  void dispose() {
    _messageQueue.close();
    _tts.stop();
    super.dispose();
  }
}