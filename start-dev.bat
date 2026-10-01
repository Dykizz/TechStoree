@echo off
title TechStoree Launcher
echo ===================================================
echo     DANG KHOI DONG TECHSTOREE (BACKEND + CLIENT)
echo ===================================================
start "TechStoree Backend API" cmd /k "cd /d %~dp0api && dotnet run"
start "TechStoree Frontend Web" cmd /k "cd /d %~dp0client && npm run dev"
echo.
echo Da khoi dong ca 2 ung dung trong 2 cua so rieng!
echo - Backend Swagger API: http://localhost:5000/swagger
echo - Frontend Website:    http://localhost:3000
echo ===================================================
