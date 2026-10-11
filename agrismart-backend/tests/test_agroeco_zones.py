"""
Tests du socle de données du Module IA — `app/services/agroeco_zones.py`.

Deux mécanismes y sont vérifiés, tous deux décrits dans le mémoire :

1. Le rattachement d'un point GPS à l'une des six zones agroécologiques du
   Sénégal, qui détermine les moyennes de référence appliquées à la parcelle.
2. Le repli sur les moyennes de zone quand une source externe (SoilGrids,
   NASA POWER) ne répond pas. C'est la garantie de disponibilité du moteur :
   une recommandation reste produite hors ligne ou en cas de panne d'API, et
   l'origine des données est tracée dans `AnalyseParcelle.sourceDonnees`.

Aucun appel réseau réel : les collecteurs sont systématiquement simulés.
"""

import pytest
from unittest.mock import patch

from app.core.exceptions import SourceDonneesIndisponibleException
from app.services import agroeco_zones


# ─── 1. Rattachement d'un point GPS à sa zone agroécologique ──────────────────

class TestZoneDe:
    """`zone_de` doit couvrir les six zones du diagramme, sans exception."""

    # Deux localités réelles par zone, pour ne pas valider la fonction sur un
    # seul point qui pourrait tomber juste par chance dans la bonne fenêtre.
    LOCALITES = [
        ("Saint-Louis", 16.0326, -16.4818, "Vallee_du_Fleuve"),
        ("Podor",       16.6500, -14.9600, "Vallee_du_Fleuve"),
        ("Thiès",       14.7900, -16.9300, "Niayes"),
        ("Mboro",       15.1400, -16.8900, "Niayes"),
        ("Kaolack",     14.1520, -16.0726, "Bassin_Arachidier"),
        ("Fatick",      14.3390, -16.4110, "Bassin_Arachidier"),
        ("Linguère",    15.3900, -15.1200, "Zone_Sylvopastorale"),
        ("Ranérou",     15.3000, -13.9700, "Zone_Sylvopastorale"),
        ("Saraya",      12.8400, -11.5700, "Senegal_Oriental"),
        ("Kédougou",    12.5605, -12.1797, "Senegal_Oriental"),
        ("Ziguinchor",  12.5665, -16.2719, "Casamance"),
        ("Kolda",       12.8833, -14.9500, "Casamance"),
    ]

    @pytest.mark.parametrize(
        "nom,latitude,longitude,zone_attendue",
        LOCALITES,
        ids=[loc[0] for loc in LOCALITES],
    )
    def test_localite_rattachee_a_sa_zone(self, nom, latitude, longitude, zone_attendue):
        assert agroeco_zones.zone_de(latitude, longitude) == zone_attendue

    def test_les_six_zones_sont_couvertes(self):
        """Le jeu de test touche bien les 6 zones, pas seulement quelques-unes."""
        zones_testees = {zone for _, _, _, zone in self.LOCALITES}
        assert zones_testees == set(agroeco_zones.ZONES_BBOX)
        assert len(zones_testees) == 6

    def test_point_hors_bornes_rattache_a_la_zone_la_plus_proche(self):
        """
        Dakar est à l'ouest de toutes les fenêtres définies : aucune ne le
        contient. Le repli « zone dont le centre est le plus proche » doit le
        rattacher aux Niayes, ce qui est agronomiquement correct (Dakar est à
        l'extrémité sud de la bande des Niayes).
        """
        assert agroeco_zones.zone_de(14.6928, -17.4467) == "Niayes"

    def test_une_zone_est_toujours_retournee(self):
        """Aucun point ne doit produire None : le moteur ne peut pas rester sans socle."""
        for latitude, longitude in [(0.0, 0.0), (90.0, 180.0), (-90.0, -180.0)]:
            assert agroeco_zones.zone_de(latitude, longitude) in agroeco_zones.ZONES_BBOX

    def test_chaque_zone_a_ses_tables_de_reference(self):
        """Une zone sans moyennes rendrait le repli impossible pour cette zone."""
        for zone in agroeco_zones.ZONES_BBOX:
            assert zone in agroeco_zones.SOL_CLIMAT_ZONE
            assert zone in agroeco_zones.PK_ZONE
            assert zone in agroeco_zones.NDVI_ZONE


# ─── 2. Repli sur les moyennes de zone ────────────────────────────────────────

KAOLACK = (14.1520, -16.0726)          # Bassin arachidier
ZONE_KAOLACK = "Bassin_Arachidier"

CLIMAT_TEMPS_REEL = {
    "temperature_moy_C": 29.1, "temperature_max_mois_C": 35.2,
    "temperature_min_mois_C": 22.8, "humidite_moy_pct": 52.0,
    "pluie_annuelle_mm": 701.4, "pluie_hivernage_mm": 688.0,
}
SOL_TEMPS_REEL = {
    "N_total_g_kg": 0.80, "pH_eau": 6.40, "clay_pct": 15.0,
    "sand_pct": 69.0, "silt_pct": 16.0, "carbone_org_g_kg": 8.2,
}


class TestRepliSurMoyennesDeZone:
    """
    `assembler_variables` part toujours des moyennes de zone, puis les remplace
    par des mesures temps réel quand les sources répondent. L'indisponibilité
    d'une source ne doit jamais empêcher la production des 16 variables.
    """

    def test_soilgrids_indisponible_repli_sur_la_moyenne_de_zone(self):
        """SoilGrids en panne : les variables sol viennent de la zone, et c'est tracé."""
        with patch.object(
            agroeco_zones, "collecter_sol_soilgrids",
            side_effect=Exception("SoilGrids injoignable"),
        ), patch.object(
            agroeco_zones, "collecter_climat_nasa_power", return_value=CLIMAT_TEMPS_REEL,
        ):
            variables, zone, sources = agroeco_zones.assembler_variables(*KAOLACK)

        assert zone == ZONE_KAOLACK
        assert sources["sol"] == "moyenne de zone"
        # Le climat, lui, a bien été mesuré : le repli est par bloc, pas global.
        assert sources["climat"] == "NASA POWER (temps réel)"

        moyennes = agroeco_zones.SOL_CLIMAT_ZONE[ZONE_KAOLACK]
        for cle in ("N_total_g_kg", "pH_eau", "clay_pct", "sand_pct",
                    "silt_pct", "carbone_org_g_kg"):
            assert variables[cle] == moyennes[cle]

    def test_nasa_power_indisponible_repli_sur_la_moyenne_de_zone(self):
        with patch.object(
            agroeco_zones, "collecter_sol_soilgrids", return_value=SOL_TEMPS_REEL,
        ), patch.object(
            agroeco_zones, "collecter_climat_nasa_power",
            side_effect=SourceDonneesIndisponibleException("NASA POWER ne répond pas"),
        ):
            variables, _, sources = agroeco_zones.assembler_variables(*KAOLACK)

        assert sources["climat"] == "moyenne de zone"
        assert sources["sol"] == "SoilGrids (temps réel)"

        moyennes = agroeco_zones.SOL_CLIMAT_ZONE[ZONE_KAOLACK]
        assert variables["temperature_moy_C"] == moyennes["temperature_moy_C"]
        assert variables["pluie_annuelle_mm"] == moyennes["pluie_annuelle_mm"]

    def test_toutes_les_sources_indisponibles_les_16_variables_restent_disponibles(self):
        """
        Cas extrême (hors ligne) : aucune source externe ne répond. Les 16
        variables attendues par le modèle doivent tout de même être produites,
        sinon la recommandation échouerait au lieu de se replier.
        """
        with patch.object(
            agroeco_zones, "collecter_sol_soilgrids",
            side_effect=Exception("hors ligne"),
        ), patch.object(
            agroeco_zones, "collecter_climat_nasa_power",
            side_effect=SourceDonneesIndisponibleException("hors ligne"),
        ):
            variables, zone, sources = agroeco_zones.assembler_variables(*KAOLACK)

        assert set(variables) == set(agroeco_zones.CLE_ML_VERS_ANALYSE_PARCELLE)
        assert len(variables) == 16
        assert all(origine == "moyenne de zone" for origine in sources.values())

    def test_soilgrids_partiel_non_retenu(self):
        """
        Une réponse SoilGrids trop incomplète (moins de 4 variables sur 6) n'est
        pas fiable : on garde la moyenne de zone plutôt que de mélanger deux
        origines dans le même bloc sans pouvoir le tracer.
        """
        with patch.object(
            agroeco_zones, "collecter_sol_soilgrids",
            return_value={"pH_eau": 5.1, "clay_pct": 30.0},
        ), patch.object(
            agroeco_zones, "collecter_climat_nasa_power", return_value=CLIMAT_TEMPS_REEL,
        ):
            variables, _, sources = agroeco_zones.assembler_variables(*KAOLACK)

        assert sources["sol"] == "moyenne de zone"
        assert variables["pH_eau"] == agroeco_zones.SOL_CLIMAT_ZONE[ZONE_KAOLACK]["pH_eau"]

    def test_phosphore_potassium_et_ndvi_toujours_moyenne_de_zone(self):
        """
        Aucune source temps réel n'est exploitée pour P, K et le NDVI : ces
        blocs doivent être déclarés « moyenne de zone » même quand tout
        fonctionne, sans quoi la traçabilité affichée serait fausse.
        """
        with patch.object(
            agroeco_zones, "collecter_sol_soilgrids", return_value=SOL_TEMPS_REEL,
        ), patch.object(
            agroeco_zones, "collecter_climat_nasa_power", return_value=CLIMAT_TEMPS_REEL,
        ):
            _, _, sources = agroeco_zones.assembler_variables(*KAOLACK)

        assert sources["phosphore_potassium"] == "moyenne de zone"
        assert sources["ndvi"] == "moyenne de zone"

    def test_resume_des_sources_lisible_pour_analyse_parcelle(self):
        """`resumer_sources` produit la chaîne persistée dans AnalyseParcelle."""
        resume = agroeco_zones.resumer_sources(
            {"sol": "moyenne de zone", "climat": "NASA POWER (temps réel)"}
        )
        assert resume == "sol=moyenne de zone, climat=NASA POWER (temps réel)"
