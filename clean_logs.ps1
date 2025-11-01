#!/usr/bin/env pwsh
# Script para suprimir logs de gralloc do logcat

Write-Host "Limpando logcat..." -ForegroundColor Green
adb logcat --clear

Write-Host ""
Write-Host "Rodando logcat com filtro (suprimindo gralloc4, gralloc e outros logs chatos)..." -ForegroundColor Yellow
Write-Host "Pressione Ctrl+C para parar." -ForegroundColor Cyan
Write-Host ""

# Suprimir: gralloc4, gralloc, BpBinder, Parcel, hwc, etc
# *:V = Mostrar TODOS os níveis de log
# gralloc4:S = Suppress gralloc4
adb logcat -v threadtime "*:V" gralloc4:S gralloc:S BpBinder:S Parcel:S hwc:S
