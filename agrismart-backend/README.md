# AgriSmart Backend

Backend FastAPI pour l'application mobile Flutter **AgriSmart** — assistance agricole intelligente pour les agriculteurs sénégalais.

## Architecture hybride

| Service | Rôle |
|---------|------|
| **Firebase Auth** | Authentification des utilisateurs et tokens JWT |
| **Firestore** | Base de données NoSQL (utilisateurs, champs, diagnostics…) |
| **FCM** | Notifications push vers Flutter |
| **MinIO** | Stockage objet S3-compatible pour les images de plantes |
| **OpenWeatherMap** | Données climatiques en temps réel |
| **FastAPI** | API REST exposée à l'application Flutter |

```
agrismart-backend/
├── main.py                          # Point d'entrée FastAPI
├── app/
│   ├── config.py                    # Variables d'environnement (pydantic-settings)
│   ├── firebase_init.py             # Firebase Admin SDK (Auth + Firestore + FCM)
│   ├── minio_init.py                # Client MinIO singleton
│   ├── core/
│   │   ├── security.py              # Vérification tokens Firebase JWT
│   │   ├── dependencies.py          # Injection de dépendances FastAPI
│   │   └── exceptions.py            # Exceptions métier (dont MinioIndisponibleException)
│   ├── models/                      # Schémas Pydantic v2
│   ├── services/
│   │   ├── recommandation_service.py  # Module IA 1 — Random Forest
│   │   ├── detection_service.py       # Module IA 2 — EfficientNetB0 (utilise MinIO)
│   │   ├── minio_service.py           # Upload/download/delete via MinIO
│   │   ├── meteo_service.py           # OpenWeatherMap API
│   │   ├── notification_service.py    # FCM push notifications
│   │   └── firestore_service.py       # Abstraction CRUD Firestore
│   ├── routers/                     # 15 routers FastAPI
│   └── utils/                       # Logging, preprocessing, helpers
├── models_ia/                       # Fichiers modèles IA (à placer manuellement)
│   ├── random_forest_crop.pkl
│   ├── scaler_crop.pkl
│   ├── label_encoder_crop.pkl
│   ├── efficientnet_plant_disease.tflite
│   └── plant_disease_classes.json   ✅ inclus
├── docker-compose.yml               # Lance MinIO + Backend + Nginx
└── tests/                           # Tests unitaires pytest (dont test_minio.py)
```

## Prérequis

- Python 3.11+
- Docker & Docker Compose (pour MinIO)
- Projet Firebase (Firestore, Auth, FCM) — PAS Firebase Storage
- Clé API OpenWeatherMap (gratuite sur openweathermap.org)

---

## Démarrage avec MinIO

MinIO est le service de stockage d'images de plantes. Il remplace Firebase Storage.

### 1. Lancer MinIO avec Docker Compose

```bash
# Depuis le dossier agrismart-backend/
docker-compose up -d minio
```

MinIO sera accessible sur :
- **API S3** (utilisée par le backend) : `http://localhost:9000`
- **Console web** (interface graphique) : `http://localhost:9001`

Credentials par défaut :
- Login : `agrismartadmin`
- Mot de passe : `AgriSmart2026!Secret`

### 2. Vérification du démarrage MinIO

```bash
# Santé du service
curl http://localhost:9000/minio/health/live

# Ou consultez la console web :
open http://localhost:9001
```

Le bucket `agrismart-images` est **créé automatiquement** au premier démarrage du backend.

### 3. Variables d'environnement MinIO dans .env

```env
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=agrismartadmin
MINIO_SECRET_KEY=AgriSmart2026!Secret
MINIO_SECURE=false
MINIO_BUCKET_IMAGES=agrismart-images
```

### Flux d'upload d'image (MinIO)

```
Flutter                 FastAPI                  MinIO              Firestore
  |                        |                        |                   |
  |-- POST /images/upload ->|                        |                   |
  |   (multipart/form-data) |                        |                   |
  |                        |-- put_object() -------->|                   |
  |                        |                        |-- objet stocké    |
  |                        |<-- urlMinio, chemin ---|                   |
  |                        |-- creer(doc) -------------------------------->|
  |                        |   {urlMinio, nomFichierMinio, bucketMinio}  |
  |<-- {imageId, urlMinio} |                        |                   |
```

### Flux de diagnostic IA (MinIO → Inférence)

```
Flutter                 FastAPI              Firestore            MinIO        TFLite
  |                        |                    |                   |              |
  |-- POST /diagnostics/analyser/{imageId} -->  |                   |              |
  |                        |-- lire(imageId) -->|                   |              |
  |                        |<-- {nomFichierMinio}|                  |              |
  |                        |-- get_object() ----------------------->|              |
  |                        |<-- bytes image ----|-------------------|              |
  |                        |-- invoke() ------------------------------------------------>|
  |                        |<-- probabilités ---|-------------------|--------------|
  |                        |-- creer(diagnostic) ->|               |              |
  |<-- {diagnosticId, maladie, score} ---------|   |               |              |
```

---

## Installation complète

### 1. Cloner et configurer l'environnement Python

```bash
cd agrismart-backend
python -m venv venv
source venv/bin/activate  # Windows : venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
# Éditez .env avec vos credentials Firebase et OpenWeatherMap
```

### 3. Placer le Service Account Firebase

Téléchargez depuis Firebase Console → Paramètres → Comptes de service.

```bash
# Ne jamais commiter ce fichier !
cp ~/Downloads/agrismart-firebase-adminsdk-xxxx.json ./firebase_service_account.json
```

### 4. Démarrer MinIO (Docker)

```bash
docker-compose up -d minio
```

### 5. Placer les modèles IA

```
models_ia/
├── random_forest_crop.pkl           # Modèle Random Forest
├── scaler_crop.pkl                  # StandardScaler
├── label_encoder_crop.pkl           # LabelEncoder
└── efficientnet_plant_disease.tflite  # EfficientNetB0
```

> **Sans les modèles**, l'application démarre en **mode MOCK** : prédictions simulées. Idéal pour le développement.

### 6. Démarrer le backend FastAPI

```bash
# Développement (rechargement automatique)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Ou
python main.py
```

API : http://localhost:8000  
Swagger : http://localhost:8000/docs  
ReDoc : http://localhost:8000/redoc

---

## Déploiement Docker complet (MinIO + Backend)

```bash
# Lance MinIO + Backend ensemble
docker-compose up -d

# Logs
docker-compose logs -f agrismart-backend
docker-compose logs -f minio
```

En production, le backend accède à MinIO via le réseau Docker : `MINIO_ENDPOINT=minio:9000`.

---

## Authentification

Toutes les routes (sauf `/auth/*`) nécessitent un **idToken Firebase** :

```
Authorization: Bearer <firebase_id_token>
```

Obtenu côté Flutter : `await user.getIdToken()`

---

## Modules IA

### Module 1 — Recommandation de cultures

**Endpoint :** `POST /recommandations/generer/{champId}`

**Workflow :**
1. Récupère les données agronomiques (pH, N, P, K, humidité)
2. Appelle OpenWeatherMap pour la météo GPS du champ
3. Normalise avec `StandardScaler`
4. Prédit avec `RandomForestClassifier.predict_proba()`
5. Retourne le **top-3** avec scores, périodes, conseils
6. Sauvegarde en Firestore

**Features d'entrée (ordre) :** N, P, K, température, humidité_atmo, pH, pluviométrie

**Cultures cibles :** mil, sorgho, arachide, niébé, maïs, sésame, tomate, oignon, riz, coton

### Module 2 — Détection de maladies

**Endpoint :** `POST /diagnostics/analyser/{imageId}`

**Workflow :**
1. Lit les métadonnées Firestore de l'image (dont `nomFichierMinio`)
2. **Télécharge l'image depuis MinIO** via `MinioService.telecharger_image()`
3. Redimensionne à 224×224, normalise [0, 1]
4. Inférence TFLite (EfficientNetB0)
5. Retourne **top-3 prédictions** avec scores
6. Si score < seuil (0.7) → statut `EN_ATTENTE` (validation expert requise)
7. Si score ≥ seuil → `AUTO_CONFIRME`
8. Si gravité ELEVE/CRITIQUE → alerte push FCM

---

## Endpoints principaux

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/auth/verify-token` | Vérification token Firebase |
| GET | `/auth/me` | Profil utilisateur courant |
| GET | `/champs/agriculteur/{id}` | Champs d'un agriculteur |
| POST | `/champs` | Créer un champ |
| POST | `/donnees-agronomiques` | Saisir mesures agronomiques |
| **POST** | **`/recommandations/generer/{champId}`** | **Lancer Module IA 1** |
| POST | `/images/upload` | Upload image plante → MinIO |
| **POST** | **`/diagnostics/analyser/{imageId}`** | **Lancer Module IA 2** |
| POST | `/diagnostics/{id}/valider` | Validation expert |
| GET | `/meteo/actuelle/{champId}` | Météo actuelle du champ |
| GET | `/admin/statistiques-globales` | Statistiques admin |

Documentation complète : http://localhost:8000/docs

---

## Collections Firestore

| Collection | Description |
|-----------|-------------|
| `users` | Profils utilisateurs (agriculteurs, experts, admins) |
| `champs` | Champs agricoles |
| `donneesAgronomiques` | Mesures pH, NPK, humidité |
| `cultures` | Catalogue des cultures |
| `recommandationsCulture` | Résultats Module IA 1 |
| `imagesPlantes` | Métadonnées MinIO (urlMinio, nomFichierMinio, bucketMinio) |
| `diagnosticsMaladie` | Résultats Module IA 2 |
| `maladies` | Catalogue des maladies |
| `traitementsRecommandes` | Traitements par maladie |
| `interventions` | Interventions d'experts |
| `conseils` | Conseils experts → agriculteurs |
| `notifications` | Historique notifications push FCM |
| `historiqueActivites` | Journal des actions |

---

## Tests

```bash
# Tous les tests
pytest tests/ -v

# Avec couverture
pytest tests/ --cov=app --cov-report=html

# Tests MinIO uniquement (avec mocks, ne nécessite pas MinIO actif)
pytest tests/test_minio.py -v

# Tests IA
pytest tests/test_detection.py tests/test_recommandation.py -v
```

---

## Variables d'environnement complètes

| Variable | Description | Défaut |
|----------|-------------|--------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Chemin JSON Firebase | `./firebase_service_account.json` |
| `FIREBASE_PROJECT_ID` | ID du projet Firebase | `agrismart-final` |
| `MINIO_ENDPOINT` | Endpoint MinIO | `localhost:9000` |
| `MINIO_ACCESS_KEY` | Clé d'accès MinIO | `agrismartadmin` |
| `MINIO_SECRET_KEY` | Secret MinIO | `AgriSmart2026!Secret` |
| `MINIO_SECURE` | HTTPS pour MinIO | `false` |
| `MINIO_BUCKET_IMAGES` | Nom du bucket images | `agrismart-images` |
| `OPENWEATHER_API_KEY` | Clé API OpenWeatherMap | — |
| `API_SECRET_KEY` | Secret JWT interne | `changeme` |
| `ENV` | Environnement | `development` |
| `SEUIL_CONFIANCE_DETECTION` | Seuil auto-confirmation | `0.7` |
| `TOP_K_RECOMMANDATIONS` | Nb recommandations | `3` |

---

## Mode développement sans Firebase ni MinIO

L'application démarre avec des fallbacks :
- **MinIO absent** : erreur 503 à l'upload (MinIO doit être actif pour les images)
- **Météo** : données fictives si `OPENWEATHER_API_KEY` est vide
- **Modèles IA** : prédictions heuristiques si les `.pkl`/`.tflite` sont absents
- **Firebase** : avertissement au démarrage, API accessible

```bash
# Démarrer uniquement MinIO (minimum requis pour les images)
docker-compose up -d minio
uvicorn main:app --reload
```

## Licence

Projet AgriSmart — Développé pour les agriculteurs sénégalais.
