"""Fonctions utilitaires générales pour KoobalaTech."""

from datetime import datetime, timezone
from typing import Any, Optional


def maintenant_utc() -> datetime:
    """Retourne la date/heure actuelle en UTC."""
    return datetime.now(timezone.utc)


def nettoyer_dict(d: dict) -> dict:
    """Supprime les clés avec valeur None d'un dictionnaire."""
    return {k: v for k, v in d.items() if v is not None}


def paginer(items: list[Any], page: int = 1, par_page: int = 20) -> dict:
    """
    Applique une pagination simple à une liste.

    Returns:
        dict avec 'items', 'total', 'page', 'par_page', 'pages'.
    """
    total = len(items)
    debut = (page - 1) * par_page
    fin = debut + par_page
    return {
        "items": items[debut:fin],
        "total": total,
        "page": page,
        "par_page": par_page,
        "pages": (total + par_page - 1) // par_page,
    }


def calculer_score_sante_champ(
    nb_maladies_recentes: int,
    nb_diagnostics_confirmes: int,
    nb_recommandations_actives: int,
) -> tuple[float, str]:
    """
    Calcule un score de santé de 0 à 100 pour un champ.

    Returns:
        Tuple (score, interprétation).
    """
    score = 100.0

    # Déductions selon les problèmes détectés
    score -= nb_maladies_recentes * 15
    score -= nb_diagnostics_confirmes * 10
    score -= max(0, nb_recommandations_actives - 1) * 5

    score = max(0.0, min(100.0, score))

    if score >= 80:
        interpretation = "Très bon état — Aucune action urgente requise"
    elif score >= 60:
        interpretation = "Bon état — Surveillance recommandée"
    elif score >= 40:
        interpretation = "État moyen — Des actions correctives sont nécessaires"
    elif score >= 20:
        interpretation = "Mauvais état — Intervention urgente recommandée"
    else:
        interpretation = "État critique — Contactez un expert immédiatement"

    return score, interpretation
