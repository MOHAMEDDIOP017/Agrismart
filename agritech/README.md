# AgriSmart 

Application mobile d'assistance agricole intelligente pour les agriculteurs d'Afrique subsaharienne.

## Description

AgriSmart aide les agriculteurs à :
- **Gérer leurs champs** : suivi des parcelles, cultures, données agronomiques
- **Recevoir des recommandations IA** : cultures adaptées au sol et au climat
- **Détecter les maladies** : diagnostic par photo des plants
- **Gérer les alertes** : notifications sur les maladies et risques climatiques

## Prérequis

- Flutter 3.19+ / Dart 3.3+
- Android SDK 21+ ou iOS 12+

## Installation

```bash
git clone <repo-url>
cd agritech
flutter pub get
flutter run
```

## Compte de démonstration

| Champ | Valeur |
|-------|--------|
| Email | mamadou.diallo@agrismart.sn |
| Mot de passe | demo123 |

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── app.dart                     # MaterialApp + GoRouter
├── core/
│   ├── theme/                   # Couleurs, typographie, thème
│   ├── constants/               # Constantes, URLs, assets
│   ├── utils/                   # Validateurs, formatage dates
│   └── widgets/                 # Widgets réutilisables
├── features/
│   ├── onboarding/              # Splash + Onboarding 3 pages
│   ├── auth/                    # Login + Register (Riverpod)
│   ├── dashboard/               # Tableau de bord principal
│   ├── champs/                  # Gestion des champs (CRUD)
│   ├── donnees_agro/            # Saisie NPK, pH, humidité
│   ├── recommandations/         # Recommandations IA
│   ├── alertes/                 # Alertes et notifications
│   ├── suivi/                   # Suivi état des champs
│   └── profil/                  # Profil agriculteur
├── navigation/
│   ├── app_router.dart          # GoRouter routes nommées
│   └── bottom_nav_bar.dart      # BottomNavigationBar 5 onglets
└── mock_data/                   # Données mock réalistes Sénégal
```

## Stack technique

| Catégorie | Package |
|-----------|---------|
| Navigation | go_router ^13.0 |
| État | flutter_riverpod ^2.5 |
| Animations | flutter_animate ^4.5, shimmer ^3.0 |
| Réseau | dio ^5.4, cached_network_image ^3.3 |
| GPS | geolocator ^11.0 |
| Médias | image_picker ^1.0 |
| UI | google_fonts, gap, flutter_staggered_animations |

## Design System

- **Primaire** : `#1D9E75` (vert agricole)
- **Secondaire** : `#EF9F27` (ambre)
- **Alertes** : `#D85A30` (corail), `#E53935` (rouge)
- **Typographie** : Poppins (titres) + Inter (corps)

## Données mock (contexte sénégalais)

- **Champs** : Thiès, Kaolack, Diourbel, Ziguinchor, Saint-Louis
- **Cultures** : Mil, Sorgho, Arachide, Niébé, Maïs, Sésame, Riz
- **Météo** : 7 villes du Sénégal (28–40°C)
- **Monnaie** : FCFA

## Roadmap

- [ ] Intégration API backend réelle
- [ ] Détection maladie par photo (ML Kit / TensorFlow Lite)
- [ ] Mode hors-ligne (Hive)
- [ ] Notifications push (Firebase)
- [ ] Cartographie des champs (OpenStreetMap)
- [ ] Internationalisation (Wolof, Bambara)
