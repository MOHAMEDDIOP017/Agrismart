# AgriSmart Backend

Backend FastAPI pour l'application mobile Flutter **AgriSmart** — assistance agricole intelligente pour les agriculteurs sénégalais.

## Architecture hybride

| Service | Rôle |
|---------|------|
| **Firebase Auth** | Authentification des utilisateurs et tokens JWT |
| **Firestore** | Base de données NoSQL (utilisateurs, champs, diagnostics…) |
| **FCM** | Notifications push vers Flutter |
| **MinIO** | Stockage objet S3-compatible pour les images de plantes |
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

Identifiants : ceux que vous avez définis dans `.env`
(`MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY`). `docker-compose.yml` les lit depuis
ce même fichier — aucun identifiant n'est écrit en dur dans le dépôt.

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
# À remplacer par vos propres identifiants (voir .env.example) :
MINIO_ACCESS_KEY=votre_access_key
MINIO_SECRET_KEY=votre_secret_key_longue_et_aleatoire
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
# Éditez .env avec vos credentials Firebase et MinIO
```

### 3. Placer le Service Account Firebase

Téléchargez depuis Firebase Console → Paramètres → Comptes de service.

```bash
# Ne jamais commiter ce fichier !
cp ~/Downloads/agrismart-jf-f1879-firebase-adminsdk-xxxx.json ./firebase_service_account.json
```

### 4. Démarrer MinIO (Docker)

```bash
docker-compose up -d minio
```

### 5. Placer le modèle IA

```
models_ia/
└── modele_final.joblib              # Recommandation de cultures (multi-label)
```

Le fichier contient `{pipeline, binarizer, features}` : StandardScaler →
OneVsRestClassifier(RandomForest), les 8 cultures, et les 16 variables d'entrée
dans leur ordre significatif.

> **Reproduire le modèle :** il est produit hors ligne par la chaîne de
> préparation des données versionnée dans [`../pipeline-donnees/`](../pipeline-donnees/README.md)
> (collecte SoilGrids / NASA POWER / iSDA, extraction NDVI, étiquetage par
> aptitude trapézoïdale FAO Ecocrop, entraînement comparatif).
>
> L'ordre des 16 variables est un contrat entre cette chaîne et
> `app/services/agroeco_zones.py` : une divergence fausserait les prédictions
> sans lever d'erreur. Elle est verrouillée par `tests/test_pipeline_donnees.py`.

> **Sans le modèle**, `/recommandations/v2/generer/{champId}` répond 503 ; le
> reste de l'API (authentification, champs, conseils, suivi) reste disponible.

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

## Module IA — Recommandation de cultures

**Endpoint :** `POST /recommandations/v2/generer/{champId}`

**Workflow :**
1. Géolocalise le champ et détermine sa zone agroécologique (parmi les 6 zones du Sénégal)
2. Collecte automatiquement les 16 variables sol/climat/NDVI (SoilGrids, NASA POWER,
   moyennes de zone en repli si une API externe est indisponible)
3. Persiste ces variables comme `AnalyseParcelle` (remplace la saisie manuelle)
4. Normalise avec `StandardScaler`
5. Prédit avec `OneVsRestClassifier(RandomForestClassifier).predict_proba()` — une
   probabilité d'aptitude indépendante par culture (classifieur multi-étiquettes)
6. Retourne le **top-3** avec probabilité d'aptitude, rang, périodes, conseils
7. Sauvegarde en Firestore, chaque recommandation avec son propre statut de validation expert

**Features d'entrée (16, ordre du modèle) :** azote, phosphore, potassium, pH, argile,
sable, limon, carbone organique, température moyenne/max/min, humidité, pluviométrie
annuelle/hivernage, NDVI moyen annuel/hivernage.

**Cultures cibles (8, avec nom wolof) :** arachide (gerte), maïs (mbóq), manioc (ñambi),
mil (dugub), niébé (ñebbe), riz (ceeb), sorgho (bàkka), tomate (tamaate).

Un premier moteur (SVM, 7 variables, 1 seule classe prédite) avait été prévu pour
comparaison dans le mémoire, mais ses artefacts n'ont jamais été présents dans ce
dépôt — il a été retiré. Seules ses fiches techniques par culture ont été conservées,
dans `app/services/fiches_cultures.py`.

## Agent conversationnel IA

**Endpoint :** `POST /agent/chat`

Chat bilingue français/wolof (Qwen via OpenRouter, clé dans `OPENROUTER_API_KEY`).
L'agent décide seul, par function calling, d'appeler l'outil de recommandation de
cultures (à partir du nom d'une localité) ou de répondre directement (maladies,
techniques culturales…). Chaque échange est persisté comme `MessageChat`, regroupé
par `conversationId`.

---

## Endpoints principaux

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/auth/verify-token` | Vérification token Firebase |
| GET | `/auth/me` | Profil utilisateur courant |
| GET | `/champs/agriculteur/{id}` | Champs d'un agriculteur |
| POST | `/champs` | Créer un champ |
| **POST** | **`/recommandations/v2/generer/{champId}`** | **Lancer le module IA de recommandation** |
| GET | `/recommandations/v2/champ/{champId}` | Historique des recommandations d'un champ |
| **POST** | **`/agent/chat`** | **Discuter avec l'agent conversationnel** |
| GET | `/recommandations/{id}` | Détail d'une recommandation |
| GET | `/admin/statistiques-globales` | Statistiques admin |

Documentation complète : http://localhost:8000/docs

---

## Collections Firestore

| Collection | Description |
|-----------|-------------|
| `users` | Profils utilisateurs (agriculteurs, experts, admins) |
| `champs` | Champs agricoles (rattachés à une zone agroécologique) |
| `zonesAgroecologiques` | Référentiel des 6 zones agroécologiques du Sénégal |
| `analysesParcelles` | 16 variables sol/climat/NDVI collectées pour un champ |
| `cultures` | Catalogue des cultures (avec nom wolof) |
| `recommandationsCulture` | Résultats du module IA de recommandation |
| `messagesChat` | Historique de l'agent conversationnel |
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
| `FIREBASE_PROJECT_ID` | ID du projet Firebase | `agrismart-jf-f1879` |
| `MINIO_ENDPOINT` | Endpoint MinIO | `localhost:9000` |
| `MINIO_ACCESS_KEY` | Clé d'accès MinIO | _(aucune — à définir dans `.env`)_ |
| `MINIO_SECRET_KEY` | Secret MinIO | _(aucun — à définir dans `.env`)_ |
| `MINIO_SECURE` | HTTPS pour MinIO | `false` |
| `MINIO_BUCKET_IMAGES` | Nom du bucket images | `agrismart-images` |
| `API_SECRET_KEY` | Secret JWT interne | `changeme` |
| `ENV` | Environnement | `development` |
| `SEUIL_CONFIANCE_DETECTION` | Seuil auto-confirmation | `0.7` |
| `TOP_K_RECOMMANDATIONS` | Nb recommandations | `3` |

---

## Mode développement sans Firebase ni MinIO

L'application démarre avec des fallbacks :
- **MinIO absent** : erreur 503 à l'upload (MinIO doit être actif pour les images)
- **Modèles IA** : prédictions heuristiques si les `.pkl`/`.tflite` sont absents
- **Firebase** : avertissement au démarrage, API accessible

```bash
# Démarrer uniquement MinIO (minimum requis pour les images)
docker-compose up -d minio
uvicorn main:app --reload
```

## Licence

Projet AgriSmart — Développé pour les agriculteurs sénégalais.
