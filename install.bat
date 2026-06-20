@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

title Landis+Gyr — Instalador do Validador XML

echo.
echo  ============================================================
echo   Landis+Gyr  ^|  Validador de Parametros XML
echo   Instalador v2.0
echo  ============================================================
echo.

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%ValidadorApp"
set "DIST_DIR=%ROOT%dist"
set "EXE_NAME=ValidadorXML.exe"
set "SHORTCUT=%USERPROFILE%\Desktop\Validador XML LG.lnk"

:: ══════════════════════════════════════════════════════════════
:: PASSO 1 — Verificar .NET SDK 10
:: ══════════════════════════════════════════════════════════════
echo  [1/5] Verificando .NET SDK...

dotnet --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO: .NET SDK nao encontrado no sistema.
    echo  Instale o .NET 10 SDK em: https://aka.ms/dotnet/download
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('dotnet --version 2^>nul') do set "DOTNET_VER=%%v"
echo       OK — .NET %DOTNET_VER% encontrado.
echo.

:: ══════════════════════════════════════════════════════════════
:: PASSO 2 — Verificar WebView2 Runtime
:: ══════════════════════════════════════════════════════════════
echo  [2/5] Verificando WebView2 Runtime (Microsoft Edge)...

set "WV2_FOUND=0"
reg query "HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
if %ERRORLEVEL% equ 0 set "WV2_FOUND=1"

reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
if %ERRORLEVEL% equ 0 set "WV2_FOUND=1"

reg query "HKCU\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
if %ERRORLEVEL% equ 0 set "WV2_FOUND=1"

if "%WV2_FOUND%"=="1" (
    echo       OK — WebView2 Runtime encontrado.
) else (
    echo.
    echo  AVISO: WebView2 Runtime nao detectado.
    echo  O programa usa o motor do Microsoft Edge para renderizar a interface.
    echo  Normalmente ja vem instalado com o Windows 10/11 e Microsoft Edge.
    echo.
    echo  Se o programa nao abrir apos a instalacao, baixe em:
    echo  https://aka.ms/webview2
    echo.
    set /p CONT="Continuar mesmo assim? (S/N): "
    if /i "!CONT!" neq "S" exit /b 0
)
echo.

:: ══════════════════════════════════════════════════════════════
:: PASSO 3 — Restaurar pacotes NuGet
:: ══════════════════════════════════════════════════════════════
echo  [3/5] Restaurando pacotes NuGet...

dotnet restore "%APP_DIR%\ValidadorApp.csproj" --verbosity quiet
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO: Falha ao restaurar os pacotes.
    echo  Verifique a conexao com a internet ou o cache NuGet.
    echo.
    pause
    exit /b 1
)
echo       OK — Pacotes restaurados.
echo.

:: ══════════════════════════════════════════════════════════════
:: PASSO 4 — Compilar e publicar
:: ══════════════════════════════════════════════════════════════
echo  [4/5] Compilando e publicando (Release / win-x64)...

if exist "%DIST_DIR%" (
    echo       Limpando pasta de saida anterior...
    rmdir /s /q "%DIST_DIR%"
)

dotnet publish "%APP_DIR%\ValidadorApp.csproj" ^
    --configuration Release ^
    --runtime win-x64 ^
    --self-contained true ^
    -p:PublishSingleFile=true ^
    -p:IncludeNativeLibrariesForSelfExtract=true ^
    --output "%DIST_DIR%" ^
    --verbosity quiet

if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO: A compilacao falhou.
    echo  Execute novamente com verbosity detalhada:
    echo  dotnet publish ValidadorApp\ValidadorApp.csproj -c Release -r win-x64
    echo.
    pause
    exit /b 1
)
echo       OK — Compilado em: %DIST_DIR%
echo.

:: ══════════════════════════════════════════════════════════════
:: PASSO 5 — Criar atalho na Area de Trabalho
:: ══════════════════════════════════════════════════════════════
echo  [5/5] Criando atalho na area de trabalho...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$s = (New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%'); ^
     $s.TargetPath      = '%DIST_DIR%\%EXE_NAME%'; ^
     $s.WorkingDirectory = '%DIST_DIR%'; ^
     $s.Description      = 'Landis+Gyr — Validador de Parametros XML'; ^
     $s.Save()"

if %ERRORLEVEL% equ 0 (
    echo       OK — Atalho criado na area de trabalho.
) else (
    echo       Aviso: Nao foi possivel criar o atalho ^(sem impacto no programa^).
)
echo.

:: ══════════════════════════════════════════════════════════════
:: CONCLUIDO
:: ══════════════════════════════════════════════════════════════
echo  ============================================================
echo   Instalacao concluida com sucesso!
echo  ============================================================
echo.
echo   Executavel : %DIST_DIR%\%EXE_NAME%
echo   Atalho     : %SHORTCUT%
echo.

set /p ABRIR="Abrir o Validador XML agora? (S/N): "
if /i "%ABRIR%"=="S" (
    start "" "%DIST_DIR%\%EXE_NAME%"
)

echo.
endlocal
