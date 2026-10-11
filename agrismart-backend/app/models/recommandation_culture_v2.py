"""
Modèles Pydantic pour `RecommandationCulture` (v2, multi-label, diagramme UML).

Différence structurante avec le modèle v1 (SVM, retiré) : le
modèle `modele_final.joblib` est un classifieur MULTI-ÉTIQUETTES (une
probabilité d'aptitude indépendante par culture, pas une classification
exclusive à 1 seule classe). `probabiliteAptitude` (0-1) est donc
indépendante par culture — plusieurs cultures peuvent avoir une aptitude
élevée en même temps sur un même sol — et `rang` (1 à 3) indique sa place
dans le top-k retourné pour une même `AnalyseParcelle`.

Chaque recommandation porte aussi son propre cycle de validation par un
expert (`statutValidation`), conforme au diagramme.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.models.enums import StatutValidation


class RecommandationCultureV2Base(BaseModel):
    """Une des 1 à 3 recommandations issues d'une même AnalyseParcelle."""
    cultureNom: str = Field(..., description="Nom affiché en français (ex : Manioc)")
    cultureCode: str = Field(..., description="Code de classe du modèle (ex : manioc)")
    cultureId: Optional[str] = None

    analyseParcelleId: str = Field(..., description="FK vers l'AnalyseParcelle source")
    # Dénormalisé depuis AnalyseParcelle.champId pour permettre
    # GET /recommandations/v2/champ/{champ_id} sans jointure.
    champId: str

    probabiliteAptitude: float = Field(..., ge=0, le=1, description="Probabilité d'aptitude (0-1)")
    rang: int = Field(..., ge=1, le=3, description="Place dans le top-k (1 = culture la plus adaptée)")

    periodePlantation: str
    rendementEstime: float = Field(..., ge=0)
    conseil: str
    besoinEauMm: int = Field(default=400, description="Besoin en eau (mm/saison)")
    prixMarcheEstime: int = Field(default=200, description="Prix marché estimé (FCFA/kg)")
    engraisConseilles: list[str] = Field(default_factory=list)
    maladiesFrequentes: list[str] = Field(default_factory=list)

    date: datetime

    # Cycle de validation par un expert (validerParExpert() du diagramme)
    statutValidation: StatutValidation = StatutValidation.EN_ATTENTE
    commentaireExpert: Optional[str] = None
    dateValidation: Optional[datetime] = None
    validateurId: Optional[str] = None


class RecommandationCultureV2Response(RecommandationCultureV2Base):
    id: str

    class Config:
        from_attributes = True


class ValiderRecommandationRequest(BaseModel):
    """Corps de POST /recommandations/v2/{id}/valider."""
    commentaire: Optional[str] = Field(None, max_length=1000)


class CorrigerRecommandationRequest(BaseModel):
    """Corps de POST /recommandations/v2/{id}/corriger — l'expert propose une autre culture."""
    commentaire: str = Field(..., min_length=1, max_length=1000)
    cultureCorrigeeNom: Optional[str] = Field(
        None, description="Nom de la culture proposée par l'expert à la place"
    )


class RejeterRecommandationRequest(BaseModel):
    """Corps de POST /recommandations/v2/{id}/rejeter."""
    motif: str = Field(..., min_length=1, max_length=1000)


class ResultatRecommandationV2(BaseModel):
    """Résultat complet renvoyé après exécution du moteur IA multi-label."""
    champId: str
    analyseParcelleId: str
    zoneAgroecologique: str
    topRecommandations: list[RecommandationCultureV2Response]
    modeleVersion: str
    dateAnalyse: datetime

    # ── Traçabilité des données ─────────────────────────────────
    # Origine de chaque bloc de variables : mesure temps réel (SoilGrids,
    # NASA POWER) ou moyenne de la zone agroécologique. C'est le mécanisme de
    # repli du moteur : la recommandation reste produite même quand une source
    # externe ne répond pas, mais l'utilisateur doit pouvoir le savoir.
    #
    # `sourceDonnees` est la chaîne exacte persistée dans
    # `AnalyseParcelle.sourceDonnees` (traçabilité en base) ; `sourcesDonnees`
    # en est la forme structurée, bloc par bloc, pour l'affichage client.
    sourceDonnees: str = ""
    sourcesDonnees: dict[str, str] = Field(default_factory=dict)
