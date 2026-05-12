@echo off
echo Verification de la connexion ADB...
adb devices
echo.
echo Configuration du tunnel USB (localhost:8000)...
adb reverse tcp:8000 tcp:8000
echo.
echo TUNNEL ACTIF — le telephone peut maintenant atteindre le backend via localhost:8000
echo.
pause
