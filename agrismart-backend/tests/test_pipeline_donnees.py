"""
Tests de la chaîne de préparation des données (`pipeline-donnees/`).

Cette chaîne n'est pas exécutée par l'application : elle produit hors ligne le
fichier `models_ia/modele_final.joblib`. Deux choses y sont vérifiées ici.

1. La **fonction d'aptitude trapézoïdale** (méthode FAO Ecocrop) qui a servi à
   étiqueter le jeu d'entraînement. C'est elle qui définit ce que « culture
   adaptée » veut dire dans tout le projet : le modèle n'a fait qu'apprendre à
   généraliser ses décisions. Une erreur ici se propagerait silencieusement
   jusqu'aux recommandations affichées à l'agriculteur.

2. Le **contrat des 16 variables** entre la chaîne d'entraînement et le
   backend. Le modèle reçoit un vecteur positionnel : si l'ordre des variables
   divergeait entre les deux, il lirait par exemple le pH dans la colonne de
   l'azote et produirait des prédictions fausses sans lever d'erreur. Ce test
   est le garde-fou contre une panne silencieuse.
"""

import importlib.util
from pathlib import Path

import pytest

from app.services import agroeco_zones

RACINE_DEPOT = Path(__file__).resolve().parents[2]
DOSSIER_PIPELINE = RACINE_DEPOT / "pipeline-donnees"


def _charger_module(nom: str, chemin: Path):
    """Importe un script de `pipeline-donnees/`, qui n'est pas un package."""
    spec = importlib.util.spec_from_file_location(nom, chemin)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture(scope="module")
def etiquetage():
    chemin = DOSSIER_PIPELINE / "construire_etiquettes.py"
    if not chemin.exists():
        pytest.fail(
            f"Script d'étiquetage introuvable : {chemin}. "
            "La chaîne de préparation des données doit être versionnée pour "
            "que le modèle soit reproductible."
        )
    return _charger_module("construire_etiquettes", chemin)


# ─── 1. Fonction d'aptitude trapézoïdale ──────────────────────────────────────

# Plage de test : optimum [20, 30], bornes absolues [10, 40].
#
#   aptitude
#      1 │        ┌───────────┐
#        │       /             \
#        │      /               \
#      0 │─────┘                 └─────
#        └──────┴───┴───────┴───┴──────  variable
#             10   20      30   40
#           abs_min opt_min opt_max abs_max
OPT_MIN, OPT_MAX, ABS_MIN, ABS_MAX = 20.0, 30.0, 10.0, 40.0


class TestAptitudeTrapezoidale:

    def _aptitude(self, etiquetage, x):
        return etiquetage.aptitude_trapezoidale(x, OPT_MIN, OPT_MAX, ABS_MIN, ABS_MAX)

    # ── Valeur 1 dans la plage optimale ──────────────────────────────────────

    @pytest.mark.parametrize("x", [20.0, 22.5, 25.0, 27.5, 30.0])
    def test_vaut_1_dans_la_plage_optimale(self, etiquetage, x):
        """Bornes de l'optimum incluses : la culture y est pleinement adaptée."""
        assert self._aptitude(etiquetage, x) == 1.0

    # ── Valeur 0 hors des bornes absolues ────────────────────────────────────

    @pytest.mark.parametrize("x", [10.0, 9.9, 0.0, -50.0, 40.0, 40.1, 100.0])
    def test_vaut_0_hors_des_bornes_absolues(self, etiquetage, x):
        """Bornes absolues incluses : au-delà, la culture est inadaptée."""
        assert self._aptitude(etiquetage, x) == 0.0

    # ── Décroissance linéaire entre les deux ─────────────────────────────────

    @pytest.mark.parametrize(
        "x,attendu",
        [
            (12.5, 0.25),   # quart du chemin entre abs_min (10) et opt_min (20)
            (15.0, 0.50),   # moitié
            (17.5, 0.75),   # trois quarts
            (19.0, 0.90),
        ],
    )
    def test_montee_lineaire_sous_l_optimum(self, etiquetage, x, attendu):
        assert self._aptitude(etiquetage, x) == pytest.approx(attendu)

    @pytest.mark.parametrize(
        "x,attendu",
        [
            (32.5, 0.75),   # trois quarts entre opt_max (30) et abs_max (40)
            (35.0, 0.50),
            (37.5, 0.25),
            (39.0, 0.10),
        ],
    )
    def test_descente_lineaire_au_dessus_de_l_optimum(self, etiquetage, x, attendu):
        assert self._aptitude(etiquetage, x) == pytest.approx(attendu)

    @pytest.mark.parametrize("depart", [10.0, 30.0])
    def test_pente_constante_sur_chaque_segment(self, etiquetage, depart):
        """
        Vérifie la linéarité elle-même, et pas seulement quelques points :
        l'écart entre deux valeurs espacées d'un pas constant doit être
        identique sur tout le segment, en montée comme en descente.
        """
        pas = 0.5
        xs = [depart + i * pas for i in range(1, 20)]
        valeurs = [self._aptitude(etiquetage, x) for x in xs]
        ecarts = [round(b - a, 10) for a, b in zip(valeurs, valeurs[1:])]
        assert len(set(ecarts)) == 1, f"pente non constante : {set(ecarts)}"

    def test_aptitude_toujours_entre_0_et_1(self, etiquetage):
        for centieme in range(0, 5001):
            x = centieme / 100.0
            assert 0.0 <= self._aptitude(etiquetage, x) <= 1.0

    def test_valeur_manquante_propage_nan(self, etiquetage):
        """Une variable absente ne doit pas être confondue avec une aptitude nulle."""
        import numpy as np

        assert np.isnan(self._aptitude(etiquetage, float("nan")))
        assert np.isnan(self._aptitude(etiquetage, None))

    def test_forme_reelle_du_mil(self, etiquetage):
        """
        Contrôle sur les vraies bornes d'une culture du dataset, pour que le
        test échoue aussi si les règles Ecocrop étaient modifiées par erreur.
        Mil — température : optimum 25-32 °C, absolues 18-38 °C.
        """
        temp = etiquetage.CULTURES["mil"]["temp"]
        assert etiquetage.aptitude_trapezoidale(28.0, *temp) == 1.0   # plein optimum
        assert etiquetage.aptitude_trapezoidale(18.0, *temp) == 0.0   # borne absolue
        assert etiquetage.aptitude_trapezoidale(38.0, *temp) == 0.0
        # 21.5 °C : à mi-chemin entre 18 et 25
        assert etiquetage.aptitude_trapezoidale(21.5, *temp) == pytest.approx(0.5)


# ─── 2. Moyenne géométrique : un critère nul annule le score global ───────────

class TestScoreCultureMoyenneGeometrique:
    """
    `score_culture` combine les aptitudes température / pluie / pH par une
    moyenne géométrique. Le choix est délibéré : contrairement à une moyenne
    arithmétique, elle s'annule dès qu'un seul critère est nul. Une parcelle
    dont le pH est rédhibitoire ne doit jamais être recommandée, même si la
    température et la pluviométrie sont idéales.
    """

    REGLES_MIL = {
        "temp": (25, 32, 18, 38),
        "pluie": (400, 750, 250, 1200),
        "ph": (5.5, 7.5, 4.5, 8.3),
        "irrigable": False,
    }

    def _ligne(self, temperature, pluie, ph):
        return {
            "temperature_moy_C": temperature,
            "pluie_annuelle_mm": pluie,
            "pH_eau": ph,
        }

    def test_conditions_optimales_donnent_1(self, etiquetage):
        ligne = self._ligne(temperature=28.0, pluie=600.0, ph=6.5)
        assert etiquetage.score_culture(ligne, self.REGLES_MIL, False) == pytest.approx(1.0)

    @pytest.mark.parametrize(
        "nom_critere,ligne_args",
        [
            ("température", dict(temperature=45.0, pluie=600.0, ph=6.5)),
            ("pluviométrie", dict(temperature=28.0, pluie=1500.0, ph=6.5)),
            ("pH", dict(temperature=28.0, pluie=600.0, ph=9.0)),
        ],
    )
    def test_un_seul_critere_nul_annule_le_score(self, etiquetage, nom_critere, ligne_args):
        """Les deux autres critères sont pourtant à leur optimum."""
        ligne = self._ligne(**ligne_args)
        score = etiquetage.score_culture(ligne, self.REGLES_MIL, False)
        assert score == 0.0, f"{nom_critere} rédhibitoire mais score = {score}"

    def test_moyenne_geometrique_et_non_arithmetique(self, etiquetage):
        """
        Un critère nul et deux parfaits : la moyenne arithmétique donnerait
        0.67, largement au-dessus du seuil de 0.5 qui retient une culture
        comme étiquette. La moyenne géométrique donne 0.
        """
        ligne = self._ligne(temperature=28.0, pluie=600.0, ph=9.0)
        score = etiquetage.score_culture(ligne, self.REGLES_MIL, False)

        assert score == 0.0
        assert score < etiquetage.SEUIL_APTITUDE
        assert score != pytest.approx(2 / 3)   # ce qu'aurait donné la moyenne arithmétique

    def test_penalise_plus_qu_une_moyenne_arithmetique(self, etiquetage):
        """
        Sur des valeurs intermédiaires (sans zéro), la moyenne géométrique doit
        rester inférieure ou égale à la moyenne arithmétique : c'est la
        propriété qui rend le critère plus exigeant.
        """
        # 21.5 °C -> 0.5 ; 325 mm -> 0.5 ; 6.5 -> 1.0
        ligne = self._ligne(temperature=21.5, pluie=325.0, ph=6.5)
        score = etiquetage.score_culture(ligne, self.REGLES_MIL, False)

        assert score == pytest.approx((0.5 * 0.5 * 1.0) ** (1 / 3))
        assert score < (0.5 + 0.5 + 1.0) / 3

    def test_irrigation_leve_la_contrainte_de_pluie(self, etiquetage):
        """
        En zone irriguée, une culture irrigable ne doit pas être écartée pour
        cause de pluviométrie insuffisante — sinon le riz de la Vallée du
        Fleuve, cultivé en périmètre irrigué SAED, serait jamais recommandé.
        """
        regles_riz = etiquetage.CULTURES["riz"]
        ligne = self._ligne(temperature=28.0, pluie=200.0, ph=6.0)  # 200 mm : bien trop sec

        assert etiquetage.score_culture(ligne, regles_riz, zone_irriguee=False) == 0.0
        assert etiquetage.score_culture(ligne, regles_riz, zone_irriguee=True) == pytest.approx(1.0)

    def test_irrigation_sans_effet_sur_une_culture_pluviale(self, etiquetage):
        """Le mil n'est pas irrigable : la contrainte de pluie reste appliquée."""
        ligne = self._ligne(temperature=28.0, pluie=100.0, ph=6.5)
        assert etiquetage.score_culture(ligne, self.REGLES_MIL, zone_irriguee=True) == 0.0

    def test_variable_manquante_propage_nan(self, etiquetage):
        """Un score inconnu ne doit pas passer pour un score nul, ni pour un score valide."""
        import numpy as np

        ligne = self._ligne(temperature=28.0, pluie=float("nan"), ph=6.5)
        assert np.isnan(etiquetage.score_culture(ligne, self.REGLES_MIL, False))


# ─── 3. Contrat des 16 variables entre la chaîne et le backend ────────────────

class TestContratVariablesModele:
    """
    Le modèle consomme un vecteur POSITIONNEL. Ni scikit-learn ni le backend ne
    vérifient les noms au moment de la prédiction : une permutation passerait
    inaperçue et fausserait toutes les recommandations. Ce test verrouille
    l'accord entre les trois définitions de la liste.
    """

    @pytest.fixture(scope="class")
    def variables_backend(self):
        """Ordre dans lequel le backend assemble le vecteur de prédiction."""
        return list(agroeco_zones.CLE_ML_VERS_ANALYSE_PARCELLE)

    def test_chaine_et_backend_declarent_les_memes_variables(self, etiquetage, variables_backend):
        assert etiquetage.VARIABLES_MODELE == variables_backend, (
            "La liste de variables de la chaîne d'entraînement a divergé de celle "
            "du backend. Le modèle lirait les valeurs dans les mauvaises colonnes."
        )

    def test_le_modele_serialise_attend_ces_memes_variables(self, variables_backend):
        """
        Vérifie le contrat sur l'artefact réellement déployé, et pas seulement
        sur le code : c'est `modele_final.joblib` qui décide de l'ordre attendu.
        """
        import joblib

        from app.config import settings

        chemin = Path(settings.modele_final_path)
        if not chemin.is_absolute():
            chemin = Path(__file__).resolve().parents[1] / chemin
        if not chemin.exists():
            pytest.skip(f"Modèle absent du dépôt : {chemin}")

        artefact = joblib.load(chemin)
        assert list(artefact["features"]) == variables_backend, (
            "modele_final.joblib attend des variables différentes de celles "
            "assemblées par agroeco_zones : prédictions faussées silencieusement."
        )

    def test_assembler_variables_produit_exactement_ces_cles(self, variables_backend):
        """
        Le contrat porte sur ce que produit réellement `assembler_variables`,
        pas seulement sur la table de correspondance. Test exécuté sur le repli
        complet (aucune source externe), qui est le socle toujours disponible.
        """
        from unittest.mock import patch

        from app.core.exceptions import SourceDonneesIndisponibleException

        with patch.object(agroeco_zones, "collecter_sol_soilgrids",
                          side_effect=Exception("hors ligne")), \
             patch.object(agroeco_zones, "collecter_climat_nasa_power",
                          side_effect=SourceDonneesIndisponibleException("hors ligne")):
            variables, _, _ = agroeco_zones.assembler_variables(14.1520, -16.0726)

        assert sorted(variables) == sorted(variables_backend)

    def test_les_cultures_du_modele_sont_celles_de_la_chaine(self, etiquetage):
        """Les 8 classes sérialisées doivent correspondre aux règles Ecocrop."""
        import joblib

        from app.config import settings
        from app.services.recommandation_service_v2 import NOM_AFFICHAGE_PAR_CODE

        chemin = Path(settings.modele_final_path)
        if not chemin.is_absolute():
            chemin = Path(__file__).resolve().parents[1] / chemin
        if not chemin.exists():
            pytest.skip(f"Modèle absent du dépôt : {chemin}")

        classes = set(joblib.load(chemin)["binarizer"].classes_)
        assert classes == set(etiquetage.CULTURES)
        # Chaque classe doit avoir un nom affichable côté application.
        assert classes == set(NOM_AFFICHAGE_PAR_CODE)

    def test_zones_de_la_chaine_connues_du_backend(self, etiquetage):
        """Les zones irriguées citées par l'étiquetage doivent exister côté backend."""
        assert etiquetage.ZONES_IRRIGUEES <= set(agroeco_zones.ZONES_BBOX)
