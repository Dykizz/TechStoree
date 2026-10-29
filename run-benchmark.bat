@echo off
chcp 65001 >nul
title K6 Benchmark - Cache Comparison
echo =========================================================================
echo       DANG CHAY STRESS TEST K6: KHONG CACHE vs CO IN-MEMORY CACHE
echo =========================================================================
echo.

where k6 >nul 2>nul
if %errorlevel% equ 0 (
    k6 run "%~dp0k6-tests\benchmark.js"
) else if exist "C:\Program Files\k6\k6.exe" (
    "C:\Program Files\k6\k6.exe" run "%~dp0k6-tests\benchmark.js"
) else (
    echo [LOI] Chua cai dat k6 tren may!
    echo Ban co the cai dat k6 bang lenh: winget install k6 --source winget
    echo Hoac tai tai: https://k6.io/docs/get-started/installation/
    echo.
    pause
    exit /b 1
)

echo.
pause
