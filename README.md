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
