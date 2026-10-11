@echo off
echo ========================================
echo   AgriSmart Backend - Mode reseau
echo ========================================
echo.
echo Acces local       : http://localhost:8000
echo Acces reseau      : http://10.156.82.184:8000
echo Documentation API : http://10.156.82.184:8000/docs
echo.
echo Pour arreter : CTRL+C
echo ========================================
echo.
uvicorn main:app --reload --host 0.0.0.0 --port 8000
