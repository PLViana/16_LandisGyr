@echo off
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%ValidadorApp"
set "DIST_DIR=%APPDATA%\ValidadorLG"
set "EXE_NAME=ValidadorXML.exe"
set "SHORTCUT=%USERPROFILE%\Desktop\Validador XML LG.lnk"
set "DOTNET_DIR=%LOCALAPPDATA%\Microsoft\dotnet"

echo.
echo  Landis+Gyr - Validador XML - Instalador
echo  ----------------------------------------
echo  Destino: %DIST_DIR%
echo.

:: Inclui dotnet instalado localmente nesta sessao
set "PATH=%DOTNET_DIR%;%PATH%"

:: ────────────────────────────────────────────────────────────────────
:: [1/3] Verificar / instalar .NET SDK
:: ────────────────────────────────────────────────────────────────────
echo  [1/3] Verificando .NET SDK...
dotnet --version >nul 2>&1
if %ERRORLEVEL% equ 0 goto :sdk_ok

echo  .NET SDK nao encontrado. Instalando... (pode demorar alguns minutos)
echo  Nao requer permissao de administrador.
echo.

:: Baixa o script oficial via WebClient (mais rapido que Invoke-WebRequest)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "(New-Object System.Net.WebClient).DownloadFile('https://dot.net/v1/dotnet-install.ps1','%TEMP%\dotnet-install.ps1')"

if not exist "%TEMP%\dotnet-install.ps1" (
    echo  ERRO: Sem internet ou falha no download do instalador.
    echo  Instale o .NET 10 SDK manualmente e execute este bat novamente:
    echo  https://aka.ms/dotnet/download
    goto :fim_erro
)

powershell -NoProfile -ExecutionPolicy Bypass ^
    -File "%TEMP%\dotnet-install.ps1" -Channel 10.0 -InstallDir "%DOTNET_DIR%"
del "%TEMP%\dotnet-install.ps1" >nul 2>&1

dotnet --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERRO: Instalacao do .NET SDK falhou.
    echo  Instale manualmente: https://aka.ms/dotnet/download
    goto :fim_erro
)

:sdk_ok
for /f "tokens=*" %%v in ('dotnet --version 2^>nul') do set "DOTNET_VER=%%v"
echo  OK - .NET !DOTNET_VER!
echo.

:: ────────────────────────────────────────────────────────────────────
:: [2/3] Compilar e publicar
:: ────────────────────────────────────────────────────────────────────
echo  [2/3] Compilando...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
md "%DIST_DIR%"

dotnet publish "%APP_DIR%\ValidadorApp.csproj" ^
    --configuration Release ^
    --runtime win-x64 ^
    --self-contained true ^
    -p:PublishSingleFile=true ^
    -p:IncludeNativeLibrariesForSelfExtract=true ^
    --output "%DIST_DIR%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO: Compilacao falhou (codigo %ERRORLEVEL%).
    goto :fim_erro
)
if not exist "%DIST_DIR%\%EXE_NAME%" (
    echo.
    echo  ERRO: %EXE_NAME% nao foi gerado. Arquivos presentes:
    dir /b "%DIST_DIR%" 2>nul
    goto :fim_erro
)
echo  OK - %EXE_NAME% gerado.
echo.

:: ────────────────────────────────────────────────────────────────────
:: [3/3] Atalho na Area de Trabalho
:: ────────────────────────────────────────────────────────────────────
echo  [3/3] Criando atalho na area de trabalho...
set "PS1=%TEMP%\lg_atalho.ps1"
echo $s = (New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%')  > "%PS1%"
echo $s.TargetPath = '%DIST_DIR%\%EXE_NAME%'                           >> "%PS1%"
echo $s.WorkingDirectory = '%DIST_DIR%'                                 >> "%PS1%"
echo $s.Description = 'Landis+Gyr - Validador XML'                     >> "%PS1%"
echo $s.Save()                                                          >> "%PS1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
del "%PS1%" >nul 2>&1
if exist "%SHORTCUT%" (echo  OK - Atalho criado.) else (echo  Aviso: atalho nao criado.)
echo.

:: ────────────────────────────────────────────────────────────────────
:: WebView2: apenas verificar, nao instalar
:: (instalacao requer admin - use o proprio Edge para atualizar)
:: ────────────────────────────────────────────────────────────────────
set "WV2_OK=0"
reg query "HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
if !ERRORLEVEL! equ 0 set "WV2_OK=1"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
if !ERRORLEVEL! equ 0 set "WV2_OK=1"
reg query "HKCU\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
if !ERRORLEVEL! equ 0 set "WV2_OK=1"

if "!WV2_OK!"=="0" (
    echo  AVISO: Microsoft Edge WebView2 nao detectado neste computador.
    echo  Se o programa nao abrir, atualize o Microsoft Edge:
    echo  Abra o Edge ^> Configuracoes ^> Sobre o Microsoft Edge
    echo.
)

:: ────────────────────────────────────────────────────────────────────
:: Concluido
:: ────────────────────────────────────────────────────────────────────
echo  ----------------------------------------
echo  Instalacao concluida!
echo  Executavel : %DIST_DIR%\%EXE_NAME%
echo  Atalho     : %SHORTCUT%
echo  ----------------------------------------
echo.
set /p ABRIR="Abrir o Validador XML agora? (S/N): "
if /i "!ABRIR!"=="S" start "" "%DIST_DIR%\%EXE_NAME%"
goto :fim

:fim_erro
echo.
echo  ----------------------------------------
echo  Instalacao nao concluida. Veja erros acima.
echo  ----------------------------------------

:fim
echo.
echo  Pressione qualquer tecla para fechar.
pause >nul
endlocal
