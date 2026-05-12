"""Test rapide du service météo OpenWeatherMap."""
import asyncio
import os
import sys

# Ajouter le répertoire courant au PYTHONPATH
sys.path.insert(0, os.path.dirname(__file__))

from dotenv import load_dotenv
load_dotenv()


async def test():
    api_key = os.getenv("OPENWEATHER_API_KEY")
    if not api_key:
        print("❌ OPENWEATHER_API_KEY absente du .env")
        return
    print(f"✅ Clé API trouvée : {api_key[:10]}...")

    from app.services.meteo_service import meteo_service

    print("\n📍 Test 1 : Dakar (14.7167, -17.4677)")
    try:
        data = await meteo_service.get_donnees_actuelles(14.7167, -17.4677)
        source = data.get("source", "?")
        if source == "mock":
            print(f"  ⚠️  Données fictives retournées (source=mock)")
            print(f"     → Vérifier que la clé API est bien activée (attendre 30 min après création)")
        else:
            print(f"  ✅ Source       : {source}")
        print(f"  ✅ Température  : {data['temperature']}°C")
        print(f"  ✅ Humidité     : {data['humidite']}%")
        print(f"  ✅ Pluviométrie : {data.get('pluviometrie', 0)} mm/h")
        print(f"  ✅ Ville        : {data.get('ville', '—')}")
        print(f"  ✅ Description  : {data.get('description', '—')}")
    except Exception as e:
        print(f"  ❌ Erreur : {e}")

    print("\n📍 Test 2 : Thiès (14.7910, -16.9359)")
    try:
        data = await meteo_service.get_donnees_actuelles(14.7910, -16.9359)
        source = data.get("source", "?")
        print(f"  ✅ Source      : {source}")
        print(f"  ✅ Température : {data['temperature']}°C")
        print(f"  ✅ Humidité    : {data['humidite']}%")
    except Exception as e:
        print(f"  ❌ Erreur : {e}")


if __name__ == "__main__":
    asyncio.run(test())
