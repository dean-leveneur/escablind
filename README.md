# EscaBlind

**Aide a l'escalade pour personnes malvoyantes**

EscaBlind est un dispositif de guidage audio qui permet a une personne malvoyante de grimper en autonomie sur une voie d'escalade equipee de balises.

## Concept

Le systeme repose sur trois composants principaux :

- **Balises de localisation** placees en amont sur la voie (GPS-like)
- **Carte Arduino** qui detecte les balises et transmet la position
- **Application mobile Flutter** qui recoit les donnees via BLE et guide le grimpeur par retour audio

Le grimpeur porte la carte Arduino. Quand il se deplace le long de la voie, l'Arduino detecte les balises, identifie sa position et envoie l'information a l'application mobile. L'application genere alors des instructions audio (direction, distance, prise suivante).

## Architecture

```
Balises GPS-like (sur la voie)
        |
        v
   Carte Arduino (portee par le grimpeur)
        |  Bluetooth BLE
        v
   App mobile Flutter
        |
        v
   Retour audio (guidage)
```

## Structure du projet

```
escablind/
├── arduino/                           # Firmware Arduino
│   └── escablind_beacon/
│       └── escablind_beacon.ino       # Sketch principal
│
├── flutter/                           # Application mobile Flutter
│   ├── lib/
│   │   ├── main.dart                  # Point d'entree
│   │   ├── models/
│   │   │   └── beacon_data.dart       # Modeles: balise, message Arduino
│   │   ├── screens/
│   │   │   ├── home_screen.dart       # Ecran d'accueil + connexion BLE
│   │   │   └── guidance_screen.dart   # Ecran de guidage en temps reel
│   │   └── services/
│   │       ├── ble_service.dart       # Service Bluetooth BLE
│   │       └── audio_service.dart     # Service de synthese vocale
│   └── pubspec.yaml                   # Dependances Flutter
│
├── .gitignore
└── README.md
```

## Fonctionnalites implementees

### Arduino
- **Detection de balises** : Simule le balayage cyclique de 6 balises BLE placees sur la voie
- **Capteur de distance** : Lecture ultrason (HC-SR04) pour mesurer l'eloignement au mur
- **Capteur de vibration** : Detection de chocs/chutes via entree analogique
- **Niveau batterie** : Surveillance de la tension d'alimentation
- **Protocole serie** : Trames structurees `#POS:`, `#DIST:`, `#VIB:`, `#STAT:`, `#ERR:`

### Flutter
- **Connexion BLE** : Scan et connexion a l'Arduino via `flutter_blue_plus`
- **Parsing de trames** : Decodage des messages serie en objets structures
- **Guidage vocal** : Synthese vocale en francais (`flutter_tts`) avec file d'attente
- **Interface accessible** : Large typographie, contrastes eleves, design sombre
- **Historique des balises** : Affichage en temps reel des prises franchies

## Protocole de communication (Arduino -> Flutter)

| Trame | Format | Description |
|-------|--------|-------------|
| Position | `#POS:<id>` | Detection d'une balise (id de 1 a 6) |
| Distance | `#DIST:<cm>` | Distance au mur en centimetres |
| Vibration | `#VIB:<valeur>` | Choc ou vibration detectee |
| Statut | `#STAT:<msg>` | Message d'etat (init, batterie, nom balise) |
| Erreur | `#ERR:<code>` | Code d'erreur (1=com, 2=batterie, 3=chute) |

## Technologies

- **Application mobile** : Flutter / Dart
- **Embarque** : Arduino, composants electroniques
- **Communication** : Bluetooth BLE
- **Localisation** : Balises GPS-like
- **Interaction** : Guidage audio temps reel

## Contexte

Projet de groupe en enseignement de **Sciences de l'Ingenieur (SI)** en classe de **Terminale** au lycee. Le code source d'origine n'est plus disponible, mais l'architecture et le concept sont documentes ici.

---

*Dean LEVENEUR — Projet personnel*