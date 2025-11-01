@echo off
REM Script para suprimir logs de gralloc do logcat

echo Limpando logcat...
adb logcat --clear

echo.
echo Rodando logcat com filtro (suprimindo gralloc4, gralloc e outros logs chatos)...
echo Pressione Ctrl+C para parar.
echo.

REM Suprimir: gralloc4, gralloc, BpBinder, Parcel, etc
adb logcat -v threadtime *:V gralloc4:S gralloc:S BpBinder:S Parcel:S hwc:S
