# Chaîne de préparation des données

Cette chaîne produit `modele_final.joblib`, le modèle de recommandation de
cultures utilisé par le backend (`agrismart-backend/models_ia/`). Elle n'est
pas appelée par l'application : elle s'exécute hors ligne, en amont, et son
seul livrable est le fichier de modèle.

Elle est versionnée ici pour que le modèle soit **reproductible** : sans ces
quatre étapes, personne ne peut refaire le jeu de données ni réentraîner le
modèle à partir des sources ouvertes.

---

## Ordre d'exécution

Les quatre étapes s'enchaînent par fichiers CSV. Chacune consomme la sortie de
la précédente.

| # | Script | Entrée | Sortie |
|---|--------|--------|--------|
| 1 | `collecte_senegal_v2.py` | *(aucune)* | `dataset_senegal_brut.csv` |
| 2 | `extraction_ndvi_colab.ipynb` | `dataset_senegal_brut.csv` | `dataset_senegal_brut_ndvi.csv` |
| 3 | `construire_etiquettes.py` | `dataset_senegal_brut_ndvi.csv` | `dataset_final_multiclasse.csv` |
| 4 | `entrainer_multilabel.ipynb` | `dataset_final_multiclasse.csv` | `modele_final.joblib` |

```
        échantillonnage GPS            NDVI satellitaire        règles Ecocrop
 (6 zones agroécologiques)        (Earth Engine, MODIS)     (aptitude + seuil)
             │                              │                        │
             ▼                              ▼                        ▼
   ┌─────────────────┐          ┌─────────────────────┐   ┌────────────────────┐
   │  1. collecte    │─────────▶│  2. extraction NDVI │──▶│  3. étiquetage     │
   │  SoilGrids      │  brut    │  MODIS MOD13Q1      │   │  8 cultures        │
   │  NASA POWER     │   .csv   │                     │   │  score ≥ 0.5       │
   │  iSDAsoil       │          └─────────────────────┘   └─────────┬──────────┘
   └─────────────────┘                                              │
                                                                    ▼
                                                    ┌────────────────────────────┐
                                                    │  4. entraînement           │
                                                    │  SVM / RandomForest /      │
                                                    │  XGBoost → le meilleur     │
                                                    └─────────────┬──────────────┘
                                                                  │
                                                                  ▼
                                                        modele_final.joblib
                                                   (→ agrismart-backend/models_ia/)
```

---

## Étape 1 — Collecte (`collecte_senegal_v2.py`)

Échantillonne des points GPS dans les boîtes englobantes des 6 zones
agroécologiques, puis interroge trois sources :

- **ISRIC SoilGrids** (250 m) — azote total, pH eau, texture, carbone organique
- **NASA POWER** (climatologie 2001-2020) — températures, humidité, pluviométrie
- **iSDAsoil Africa** (30 m) — phosphore et potassium extractibles, que
  SoilGrids ne fournit pas

```bash
pip install -r requirements.txt
python collecte_senegal_v2.py --points-par-zone 150 \
    --isda-user <utilisateur> --isda-pass <mot_de_passe>
```

> **Commande de référence du mémoire :** `--points-par-zone 150`, soit 900
> points. La valeur par défaut du script est 60 : l'exécuter sans argument
> produit un jeu de données plus petit et des résultats différents de ceux
> publiés.

Les identifiants iSDA se créent gratuitement sur
<https://www.isda-africa.com/api/registration/>. Ils se passent en argument, ne
les écrivez pas dans le script. Sans eux, P et K restent manquants et
l'étape 3 ne pourra pas les imputer.

Les réponses sont mises en cache dans `cache_api/` : une exécution interrompue
reprend sans réinterroger les points déjà collectés. Ce dossier peut peser
plusieurs centaines de Mo, il est ignoré par git.

## Étape 2 — NDVI (`extraction_ndvi_colab.ipynb`)

S'exécute sur **Google Colab**, car elle nécessite un compte Google Earth
Engine. Extrait deux indices de végétation par point à partir de MODIS
MOD13Q1 (2019-2024) : moyenne annuelle et moyenne d'hivernage (juin-octobre).

Le notebook contient un identifiant de projet Google Cloud en dur
(`ee.Initialize(project=...)`) : remplacez-le par le vôtre.

## Étape 3 — Étiquetage (`construire_etiquettes.py`)

Nettoie le jeu de données puis construit la variable cible.

```bash
python construire_etiquettes.py --entree dataset_senegal_brut_ndvi.csv
```

Le nettoyage supprime les points sans données de sol (tombés en mer ou dans le
fleuve) et impute P/K manquants par la moyenne de leur zone.

L'étiquetage applique une **fonction d'aptitude trapézoïdale** inspirée de la
méthode FAO Ecocrop. Pour chaque culture et chaque variable contrainte
(température, pluviométrie, pH), le score vaut 1 dans la plage optimale,
décroît linéairement jusqu'à 0 aux bornes absolues, et reste nul au-delà. Le
score global d'une culture est la **moyenne géométrique** des trois : une seule
variable rédhibitoire suffit à annuler le score, ce qu'une moyenne arithmétique
ne permettrait pas.

Dans les zones à agriculture irriguée (Vallée du Fleuve, Niayes), la contrainte
de pluviométrie est levée pour les cultures irrigables (riz, tomate), conforme
à la réalité des périmètres SAED et du maraîchage des Niayes.

Une culture devient une étiquette du point dès que son score atteint 0.5.

## Étape 4 — Entraînement (`entrainer_multilabel.ipynb`)

Compare trois modèles en validation croisée 5 blocs, puis sérialise le
meilleur. Le notebook est conservé **avec ses sorties** : ce sont les résultats
publiés dans le mémoire.

Résultats de l'exécution de référence (824 parcelles, 659 entraînement /
165 test) :

| Modèle | F1 (validation croisée) | F1-micro (test) | F1-macro (test) | Précision@3 |
|--------|------------------------|-----------------|-----------------|-------------|
| **Random Forest** | **0.9927** | **0.9917** | **0.9906** | **1.000** |
| XGBoost | 0.9916 | 0.9889 | 0.9875 | 1.000 |
| SVM (RBF, C=10) | 0.9893 | 0.9885 | 0.9876 | 0.998 |

Le modèle retenu est sérialisé sous la forme d'un dictionnaire à trois clés :

```python
{"pipeline": Pipeline(StandardScaler → OneVsRestClassifier(RandomForest)),
 "binarizer": MultiLabelBinarizer,   # 8 cultures
 "features": [...]}                  # 16 variables, ordre significatif
```

Copiez ensuite le fichier produit vers `agrismart-backend/models_ia/`.

---

## Le contrat des 16 variables

`features` est un **contrat** entre cette chaîne et le backend. Au moment de la
prédiction, `agrismart-backend/app/services/agroeco_zones.py` assemble un
vecteur dans cet ordre exact. Si les deux listes divergeaient — un nom changé,
deux variables permutées — le modèle recevrait des valeurs dans les mauvaises
colonnes et produirait des prédictions fausses **sans lever la moindre erreur**.

Trois définitions doivent donc rester identiques :

| Où | Quoi |
|----|------|
| `construire_etiquettes.py` | `VARIABLES_MODELE` |
| `entrainer_multilabel.ipynb` | `FEATURES` |
| `agrismart-backend/app/services/agroeco_zones.py` | clés de `CLE_ML_VERS_ANALYSE_PARCELLE` |

Un test automatique verrouille ce contrat :

```bash
cd ../agrismart-backend
python -m pytest tests/test_pipeline_donnees.py -v
```

---

## Divergence connue

La boîte englobante de la **Vallée du Fleuve** n'est pas identique des deux
côtés :

| | latitude | longitude |
|---|---|---|
| chaîne (`collecte_senegal_v2.py`) | 15.50 – 16.65 | -16.50 – -13.30 |
| backend (`agroeco_zones.py`) | 15.50 – **16.70** | **-16.60** – -13.30 |

Le backend rattache donc à cette zone une mince bande qui n'a jamais été
échantillonnée à l'entraînement. Les cinq autres zones sont identiques. La
conséquence est limitée — le modèle généralise, il ne consulte pas une table —
mais la divergence est réelle et mérite d'être signalée plutôt que corrigée à
l'aveugle : aligner les deux changerait soit le périmètre de collecte, soit le
comportement du backend en production.

---

## Ce que la chaîne ne fait pas

Les étiquettes sont dérivées de **règles agronomiques**, pas de rendements
observés. Le modèle apprend donc à généraliser le cadre FAO Ecocrop sous une
forme continue et déployable : c'est un *modèle de substitution*. Les scores
très élevés du tableau ci-dessus mesurent la cohérence de ce cadre, pas la
justesse agronomique des recommandations sur le terrain. Le NDVI est la seule
variable d'entrée indépendante des règles d'étiquetage, ce qui rend son
importance dans le modèle final intéressante à commenter.
