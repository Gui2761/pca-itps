@echo off
title PCA ITPS - Iniciando...
echo ============================================
echo    PCA - Plano de Contratacoes Anual ITPS
echo ============================================
echo.
echo Iniciando servidor backend...
start "" /B "%~dp0backend\backend.exe"
echo Aguardando servidor ficar pronto...
timeout /t 3 /nobreak >nul
echo.
echo Abrindo aplicativo PCA...
start "" "%~dp0app.exe"
echo.
echo Sistema PCA iniciado com sucesso!
echo Nao feche esta janela enquanto estiver usando o app.
echo.
pause
