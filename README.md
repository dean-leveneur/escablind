# EscaBlind — Guidage Haptique et Vocal pour Escalade Inclusive

**Système d'assistance à l'escalade pour personnes malvoyantes basé sur la géolocalisation UWB Pozyx, le retour haptique par vibreur et la synthèse vocale.**

---

## 📌 Concept & Architecture

EscaBlind permet à un grimpeur malvoyant ou non-voyant de progresser en toute autonomie sur un mur d'escalade. Le système combine une géolocalisation ultra-précise en intérieur (UWB Pozyx), un module embarqué Arduino muni d'un vibreur haptique à intensité variable, et une application mobile Flutter connectée en BLE.

```
       [Ancres UWB Pozyx] (Fixées sur le mur)
               │
               ▼ (Ultra-Wideband 4GHz)
   ┌─────────────────────────────────────────┐
   │  Carte Arduino + Tag Pozyx UWB          │
   │  + Vibreur Haptique (PWM Proximité)    │
   └────────────────────┬────────────────────┘
                        │ Bluetooth Low Energy (BLE)
                        ▼
   ┌─────────────────────────────────────────┐
   │  Application Mobile Flutter             │
   │  - Enregistrement / Sélection parcours  │
   │  - Guidance vocale relative (X/Y/Z)     │
   │  - Calcul d'intensité haptique PWM      │
   └─────────────────────────────────────────┘
```

---

## 🛠️ Composition du Système

### 1. Positionnement UWB Pozyx & Carte Arduino (Module Embarqué)
- **Tag UWB Pozyx** : Mesure la position 3D exacte `(x, y, z)` du grimpeur/Arduino avec une précision centimétrique via des ancres UWB.
- **Carte Arduino** : Récupère la position du tag Pozyx, reçoit la consigne de proximité par BLE et régule le moteur haptique.
- **Vibreur Haptique** : Vibreur connecté en PWM sur l'Arduino. Son intensité et sa fréquence de vibration augmentent à mesure que le grimpeur s'approche de la prise cible.

### 2. Application Mobile Flutter
- **Bouton « Créer un parcours »** : Permet à un ouvreur ou accompagnateur d'enregistrer une suite de positions successives (coordonnées des prises cibles) sur le mur.
- **Bouton « Sélection du parcours »** : Menu déroulant permettant de choisir un parcours enregistré selon le niveau de difficulté.
- **Guidage Vocal Oralisé (TTS)** : Donne en temps réel des indications orales sur la position relative de la prochaine cible par rapport à la position actuelle de la carte Arduino (ex. *« Prochaine prise à 35 cm sur votre droite et 40 cm plus haut »*).

---

## 📂 Structure du Dépôt

```
escablind/
├── arduino/
│   └── escablind_beacon/
│       └── escablind_beacon.ino   # Firmware Arduino (UWB Pozyx, BLE & Vibreur PWM)
│
├── flutter/
│   ├── lib/
│   │   ├── main.dart              # Point d'entrée de l'application
│   │   ├── models/
│   │   │   ├── beacon_data.dart   # Trame UWB & statut Arduino
│   │   │   └── climbing_route.dart# Modèle de parcours et prises cibles
│   │   ├── screens/
│   │   │   ├── home_screen.dart   # Accueil (BLE, Créer parcours, Sélection parcours)
│   │   │   ├── route_creation_screen.dart # Création de parcours
│   │   │   ├── route_selection_screen.dart# Sélection de parcours
│   │   │   └── guidance_screen.dart       # Guidage vocal & haptique temps réel
│   │   └── services/
│   │       ├── ble_service.dart   # Communication BLE & transmission de l'intensité PWM
│   │       └── audio_service.dart # Guidance vocale relative (X, Y, Z)
│   └── pubspec.yaml               # Dépendances Flutter (flutter_blue_plus, flutter_tts)
│
├── .gitignore
└── README.md
```

---

## 📡 Protocole de Communication BLE

| Direction | Trame | Description |
|-----------|-------|-------------|
| Arduino ➔ App | `#POS_UWB:<x>,<y>,<z>` | Coordonnées 3D actuelles du grimpeur (cm) |
| Arduino ➔ App | `#STAT:<msg>` | Message d'état (Init Pozyx, Batterie) |
| App ➔ Arduino | `#VIB_INT:<0-255>` | Intensité PWM du vibreur haptique selon la distance |
| App ➔ Arduino | `#TARGET:<x>,<y>,<z>` | Coordonnées de la prochaine prise cible |

---

## 🚀 Utilisation

1. **Lancement Arduino** : Allumer la carte équipée du tag Pozyx et du vibreur.
2. **Connexion App** : Ouvrir l'application Flutter et appuyer sur *« Connecter l'Arduino »* via BLE.
3. **Créer ou Sélectionner** :
   - Appuyer sur **« Créer un parcours »** pour enregistrer une série de prises sur le mur.
   - Appuyer sur **« Sélection du parcours »** pour choisir une voie enregistrée.
4. **Ascension** : Lancer le guidage. L'application donne des instructions orales relatives et fait vibrer la carte Arduino avec une intensité proportionnelle à la proximité de chaque prise.

---

*Projet réalisé par Dean LEVENEUR*