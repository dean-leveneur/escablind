/*
 * EscaBlind - Firmware Arduino
 * 
 * Ce code gère :
 *   1. La lecture des coordonnées 3D du tag UWB Pozyx (x, y, z en cm).
 *   2. La transmission des coordonnées à l'application mobile via le module BLE (HM-10 / ESP32).
 *   3. La réception des consignes d'intensité de vibration (#VIB_INT:<0-255>) envoyées par l'app.
 *   4. La commande PWM d'un vibreur haptique connecté sur la carte Arduino.
 * 
 * Matériel :
 *   - Carte Arduino Uno / ESP32
 *   - Shield / Module UWB Pozyx
 *   - Module Bluetooth BLE (HM-10 / BLE 4.2+)
 *   - Vibreur haptique (Pin PWM 5)
 */

#include <Arduino.h>

// ============================================================
// Broches & Configuration
// ============================================================
const int PIN_VIBREUR     = 5;    // Pin PWM pour contrôle de l'intensité du vibreur
const int PIN_LED_BLE     = 13;   // Témoin LED de connexion/activité

const long BAUD_RATE      = 115200;
const int LOOP_DELAY_MS   = 200;  // Période d'échantillonnage (5 Hz)

// ============================================================
// Variables de position UWB Pozyx
// ============================================================
int positionX = 120;  // cm
int positionY = 80;   // cm
int positionZ = 50;   // cm

int vibrationIntensity = 0; // 0 à 255 (PWM)

// ============================================================
// Prototypes
// ============================================================
void lirePositionPozyxUWB();
void envoyerPositionUWB();
void traiterCommandesEntrantes();
void appliquerVibration(int intensite);

// ============================================================
// Setup
// ============================================================
void setup() {
  Serial.begin(BAUD_RATE);

  pinMode(PIN_VIBREUR, OUTPUT);
  pinMode(PIN_LED_BLE, OUTPUT);

  // Test du vibreur au démarrage (bref retour haptique)
  analogWrite(PIN_VIBREUR, 150);
  digitalWrite(PIN_LED_BLE, HIGH);
  delay(300);
  analogWrite(PIN_VIBREUR, 0);
  digitalWrite(PIN_LED_BLE, LOW);

  Serial.println("#STAT:ESCABLIND_POZYX_READY");
}

// ============================================================
// Boucle principale
// ============================================================
void loop() {
  // 1. Lecture des coordonnées 3D via les balises UWB Pozyx
  lirePositionPozyxUWB();

  // 2. Envoi de la position à l'application Flutter via BLE
  envoyerPositionUWB();

  // 3. Lecture et exécution des commandes reçues depuis l'application
  traiterCommandesEntrantes();

  // 4. Mise à jour de l'intensité du vibreur haptique
  appliquerVibration(vibrationIntensity);

  delay(LOOP_DELAY_MS);
}

// ============================================================
// Lecture de la position UWB Pozyx (Simulation/API)
// ============================================================
void lirePositionPozyxUWB() {
  /*
   * En condition réelle, on utilise la bibliothèque Pozyx :
   * Pozyx.getCoordinates(&coordinates)
   * 
   * Ici, on simule une progression progressive du grimpeur
   * le long de la voie d'escalade.
   */
  static int step = 0;
  step++;

  // Trajectoire simulée en 3D
  positionX = 100 + (int)(30 * sin(step * 0.1));
  positionY = 50 + step * 2;
  positionZ = 150 + step * 3;

  if (positionZ > 400) {
    step = 0; // Réinitialisation au départ de la voie
  }
}

// ============================================================
// Transmission de la position UWB via BLE
// ============================================================
void envoyerPositionUWB() {
  Serial.print("#POS_UWB:");
  Serial.print(positionX);
  Serial.print(",");
  Serial.print(positionY);
  Serial.print(",");
  Serial.println(positionZ);
}

// ============================================================
// Traitement des consignes envoyées par l'app Flutter
// Format : #VIB_INT:<0-255>
// ============================================================
void traiterCommandesEntrantes() {
  while (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd.startsWith("#VIB_INT:")) {
      int val = cmd.substring(9).toInt();
      vibrationIntensity = constrain(val, 0, 255);
    } else if (cmd.startsWith("#TARGET:")) {
      // Notification de nouvelle cible enregistrée
      digitalWrite(PIN_LED_BLE, HIGH);
      delay(50);
      digitalWrite(PIN_LED_BLE, LOW);
    }
  }
}

// ============================================================
// Contrôle de l'intensité PWM du vibreur haptique
// ============================================================
void appliquerVibration(int intensite) {
  analogWrite(PIN_VIBREUR, intensite);
}