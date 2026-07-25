/*
 * EscaBlind - Firmware Arduino
 * 
 * Detecte les balises BLE placees sur la voie d'escalade,
 * lit les entrees analogiques (capteurs), et transmet
 * la position au smartphone via liaison serie.
 * 
 * Materiel:
 *   - Arduino Uno / Nano BLE 33
 *   - Module BLE (HM-10 / HC-05)
 *   - Capteur ultrason (distance au mur)
 *   - Capteur de vibration (detection de chute)
 *   - LED temoin (signalisation)
 * 
 * Protocole serie (115200 bauds):
 *   #POS:<id_balise>      - Detection de balise
 *   #DIST:<cm>            - Distance au mur
 *   #VIB:<seuil>          - Vibration detectee
 *   #STAT:<msg>           - Message d'etat
 *   #ERR:<code>           - Erreur
 */

// ============================================================
// Pins
// ============================================================
const int PIN_LED          = 13;
const int PIN_DIST_TRIG    = 9;
const int PIN_DIST_ECHO    = 10;
const int PIN_VIBRATION    = A0;
const int PIN_BATTERY      = A1;

// ============================================================
// Constantes
// ============================================================
const int BAUD_RATE        = 115200;
const int LOOP_DELAY_MS    = 500;
const int VIB_THRESHOLD    = 512;   // seuil de vibration significative
const int DIST_MAX_CM      = 200;   // portee max du capteur ultrason

// ============================================================
// Simulation de balises BLE
// ============================================================

// Structure decrivant une balise sur la voie
struct Beacon {
  int id;
  const char* nom;
  int rssi_simule;       // puissance simulee (plus proche = plus fort)
};

// Tableau de balises simulees (voie fictive de 6 degres)
Beacon beacons[] = {
  {1, "PRISE_DEPART",   -45},
  {2, "PRISE_01",       -55},
  {3, "PRISE_02",       -50},
  {4, "RELAIS_01",      -60},
  {5, "PRISE_03",       -48},
  {6, "CHAINE_ARRIVEE", -42},
};

const int NB_BEACONS = sizeof(beacons) / sizeof(beacons[0]);

// Index de la balise actuellement detectee
int beacon_actif = -1;

// ============================================================
// Prototypes
// ============================================================
void simulerDetectionBalise();
void lireDistance();
void lireVibration();
void lireBatterie();
void envoyerPosition(int id);
void envoyerDistance(int cm);
void envoyerVibration(int valeur);
void envoyerEtat(const char* msg);
void envoyerErreur(int code);

// ============================================================
// Setup
// ============================================================
void setup() {
  Serial.begin(BAUD_RATE);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_DIST_TRIG, OUTPUT);
  pinMode(PIN_DIST_ECHO, INPUT);
  pinMode(PIN_VIBRATION, INPUT);
  pinMode(PIN_BATTERY, INPUT);

  digitalWrite(PIN_LED, HIGH);
  delay(300);
  digitalWrite(PIN_LED, LOW);

  envoyerEtat("ESCABLIND_INIT_OK");
  envoyerEtat("NB_BALISES:" + String(NB_BEACONS));
}

// ============================================================
// Loop principale
// ============================================================
void loop() {
  // 1. Detection des balises (simulation BLE)
  simulerDetectionBalise();

  // 2. Lecture des capteurs
  lireDistance();
  lireVibration();

  // 3. Niveau de batterie (toutes les 5 iterations)
  static int compteur = 0;
  if (++compteur >= 5) {
    compteur = 0;
    lireBatterie();
  }

  delay(LOOP_DELAY_MS);
}

// ============================================================
// Simulation de balise BLE
// ============================================================
void simulerDetectionBalise() {
  /*
   * En conditions reelles, le module BLE scannerait les balises
   * advertisees et lirait leur RSSI. Ici on simule un balayage
   * cyclique des balises pour representer le deplacement du
   * grimpeur le long de la voie.
   */
  static int index = 0;
  static unsigned long last_scan = 0;
  unsigned long now = millis();

  // Changement de balise toutes les ~3 secondes (simulation)
  if (now - last_scan > 3000) {
    last_scan = now;

    // Change de balise cycliquement
    index = (index + 1) % NB_BEACONS;

    if (beacon_actif != index) {
      beacon_actif = index;
      envoyerPosition(beacons[index].id);
      envoyerEtat(beacons[index].nom);

      // Clignotement LED pour signaler detection
      digitalWrite(PIN_LED, HIGH);
      delay(100);
      digitalWrite(PIN_LED, LOW);
    }
  }
}

// ============================================================
// Lecture capteur de distance (ultrason)
// ============================================================
void lireDistance() {
  /*
   * Envoie une impulsion sur le capteur HC-SR04 et calcule
   * la distance en cm. En simulation, renvoie une valeur
   * decroissante puis croissante (approche du mur puis
   * eloignement).
   */
  static int sim_dist = 100;
  static int dir = -1;

  // Envoi impulsion
  digitalWrite(PIN_DIST_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(PIN_DIST_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_DIST_TRIG, LOW);

  // Lecture de la duree de l'echo
  long duree = pulseIn(PIN_DIST_ECHO, HIGH, 30000); // timeout 30ms

  int distance;
  if (duree == 0) {
    // Pas d'echo (simulation)
    sim_dist += dir * 5;
    if (sim_dist < 20) dir = 1;
    if (sim_dist > 150) dir = -1;
    distance = sim_dist;
  } else {
    // Mesure reelle: vitesse du son = 343 m/s
    distance = duree * 0.034 / 2;
  }

  envoyerDistance(distance);
}

// ============================================================
// Lecture capteur de vibration
// ============================================================
void lireVibration() {
  /*
   * Detecte les vibrations (chute, impact, geste brusque).
   * En conditions reelles, on lit la pin analogique.
   */
  int valeur = analogRead(PIN_VIBRATION);

  // Simulation: valeur sinusoidale basse
  static int phase = 0;
  phase = (phase + 10) % 360;
  int sim = 300 + (int)(200 * sin(phase * 3.14159 / 180));

  if (valeur < 50) {
    // Aucun capteur branche -> utiliser la simulation
    valeur = sim;
  }

  if (valeur > VIB_THRESHOLD) {
    envoyerVibration(valeur);
    // Risque de chute detecte
    if (valeur > 700) {
      envoyerErreur(3); // Code 3 = chute probable
    }
  }
}

// ============================================================
// Lecture niveau de batterie
// ============================================================
void lireBatterie() {
  int raw = analogRead(PIN_BATTERY);
  // Conversion approximative (depend du pont diviseur)
  // 0-1023 -> 0-5V
  float tension = raw * (5.0 / 1023.0);
  int pourcentage = (int)((tension / 5.0) * 100);
  if (pourcentage > 100) pourcentage = 100;
  if (pourcentage < 0) pourcentage = 0;

  envoyerEtat("BAT:" + String(pourcentage) + "%");
}

// ============================================================
// Fonctions d'envoi serie
// ============================================================
void envoyerPosition(int id) {
  Serial.print("#POS:");
  Serial.println(id);
}

void envoyerDistance(int cm) {
  Serial.print("#DIST:");
  Serial.println(cm);
}

void envoyerVibration(int valeur) {
  Serial.print("#VIB:");
  Serial.println(valeur);
}

void envoyerEtat(const char* msg) {
  Serial.print("#STAT:");
  Serial.println(msg);
}

void envoyerEtat(const String& msg) {
  Serial.print("#STAT:");
  Serial.println(msg);
}

void envoyerErreur(int code) {
  Serial.print("#ERR:");
  Serial.println(code);
}