# KoobalaTech Backend — Script de démarrage réseau
# Usage : .\run_backend.ps1

# Détection automatique de l'IP Wi-Fi (fallback sur l'IP hardcodée si introuvable)
$ip = $null
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi" -ErrorAction Stop).IPAddress
} catch {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 |
           Where-Object { $_.IPAddress -match "^10\." -or $_.IPAddress -match "^192\.168\." } |
           Select-Object -First 1).IPAddress
}
if (-not $ip) { $ip = "10.156.89.118" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   KoobalaTech Backend - Mode reseau" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Acces local       : " -NoNewline; Write-Host "http://localhost:8000" -ForegroundColor Green
Write-Host "  Acces reseau      : " -NoNewline; Write-Host "http://${ip}:8000" -ForegroundColor Green
Write-Host "  Documentation API : " -NoNewline; Write-Host "http://${ip}:8000/docs" -ForegroundColor Green
Write-Host ""

# Avertir si l'IP détectée diffère de celle configurée dans Flutter
$configuredIp = "10.156.89.118"
if ($ip -ne $configuredIp) {
    Write-Host "  ⚠️  IP détectée ($ip) différente de celle dans api_config.dart ($configuredIp)" -ForegroundColor Yellow
    Write-Host "      Mettre à jour _wifiPcIp dans lib/core/config/api_config.dart" -ForegroundColor Yellow
    Write-Host "      et network_security_config.xml" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "  Pour arreter : CTRL+C" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

uvicorn main:app --reload --host 0.0.0.0 --port 8000
