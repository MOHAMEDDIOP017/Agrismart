"""Modèles Pydantic pour les zones agroécologiques du Sénégal (diagramme UML)."""

from pydantic import BaseModel, Field


class ZoneAgroecologiqueBase(BaseModel):
    """Une des 6 zones agroécologiques du Sénégal (référentiel, données de seed)."""
    nom: str = Field(..., description="Nom affiché (ex : Bassin arachidier)")
    latMin: float = Field(..., ge=-90, le=90)
    latMax: float = Field(..., ge=-90, le=90)
    lonMin: float = Field(..., ge=-180, le=180)
    lonMax: float = Field(..., ge=-180, le=180)
    ndviMoyenAnnuel: float = Field(..., ge=-1, le=1)
    ndviHivernage: float = Field(..., ge=-1, le=1)

    def contient(self, latitude: float, longitude: float) -> bool:
        """Vrai si le point (latitude, longitude) tombe dans la bounding-box de la zone."""
        return (
            self.latMin <= latitude <= self.latMax
            and self.lonMin <= longitude <= self.lonMax
        )


class ZoneAgroecologiqueResponse(ZoneAgroecologiqueBase):
    """Réponse complète d'une zone agroécologique (id = code interne, ex : Bassin_Arachidier)."""
    id: str

    class Config:
        from_attributes = True
