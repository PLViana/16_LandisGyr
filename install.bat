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

:: ── [1/4] Verificar ou instalar .NET SDK ─────────────────────
echo  [1/4] Verificando .NET SDK...

:: Adiciona o caminho local de instalacao ao PATH da sessao
set "PATH=%DOTNET_DIR%;%PATH%"

dotnet --version >nul 2>&1
if %ERRORLEVEL% equ 0 goto :sdk_ok

echo  SDK nao encontrado. Instalando .NET 10 automaticamente...
echo  (nao requer permissao de administrador)
echo.

:: Baixa o script oficial de instalacao da Microsoft
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile '%TEMP%\dotnet-install.ps1'"
if %ERRORLEVEL% neq 0 (
    echo  ERRO: Nao foi possivel baixar o instalador.
    echo  Verifique a conexao com a internet.
    echo  Ou instale manualmente em: https://aka.ms/dotnet/download
    pause
    exit /b 1
)

:: Instala o .NET 10 SDK no diretorio do usuario
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\dotnet-install.ps1" -Channel 10.0 -InstallDir "%DOTNET_DIR%"
del "%TEMP%\dotnet-install.ps1" >nul 2>&1

dotnet --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERRO: Falha na instalacao do .NET SDK.
    echo  Instale manualmente em: https://aka.ms/dotnet/download
    pause
    exit /b 1
)

:sdk_ok
for /f "tokens=*" %%v in ('dotnet --version 2^>nul') do set "DOTNET_VER=%%v"
echo  OK - .NET !DOTNET_VER!
echo.

:: ── [2/4] Compilar ───────────────────────────────────────────
echo  [2/4] Compilando...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
md "%DIST_DIR%"

dotnet publish "%APP_DIR%\ValidadorApp.csproj" --configuration Release --runtime win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true --output "%DIST_DIR%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO: Compilacao falhou.
    pause
    exit /b 1
)
if not exist "%DIST_DIR%\%EXE_NAME%" (
    echo.
    echo  ERRO: Executavel nao foi gerado em %DIST_DIR%
    dir /b "%DIST_DIR%" 2>nul
    pause
    exit /b 1
)
echo  OK - %EXE_NAME% gerado.
echo.

:: ── [3/4] Criar atalho ───────────────────────────────────────
echo  [3/4] Criando atalho na area de trabalho...
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

:: ── [4/4] Concluido ──────────────────────────────────────────
echo  [4/4] Instalacao concluida!
echo  ----------------------------------------
echo  Executavel : %DIST_DIR%\%EXE_NAME%
echo  Atalho     : %SHORTCUT%
echo.

set /p ABRIR="Abrir o Validador XML agora? (S/N): "
if /i "!ABRIR!"=="S" start "" "%DIST_DIR%\%EXE_NAME%"

echo.
echo  Pressione qualquer tecla para fechar.
pause >nul
endlocal
