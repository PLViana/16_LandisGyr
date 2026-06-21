@echo off
setlocal

set "LOG=%TEMP%\validador_install.log"
set "ROOT=%~dp0"
set "APP_DIR=%ROOT%ValidadorApp"
set "DIST_DIR=%APPDATA%\ValidadorLG"
set "EXE_NAME=ValidadorXML.exe"
set "DOTNET_DIR=%LOCALAPPDATA%\Microsoft\dotnet"
set "SHORTCUT=%USERPROFILE%\Desktop\Validador XML LG.lnk"

:: Inicializa log
echo ============================================ > "%LOG%"
echo  Landis+Gyr - Validador XML - Instalador >> "%LOG%"
echo  %DATE% %TIME% >> "%LOG%"
echo ============================================ >> "%LOG%"
echo  ROOT      : %ROOT% >> "%LOG%"
echo  APP_DIR   : %APP_DIR% >> "%LOG%"
echo  DIST_DIR  : %DIST_DIR% >> "%LOG%"
echo  DOTNET_DIR: %DOTNET_DIR% >> "%LOG%"
echo  LOG       : %LOG% >> "%LOG%"
echo. >> "%LOG%"

echo.
echo  Landis+Gyr - Validador XML - Instalador
echo  Log: %LOG%
echo.

:: Inclui dotnet local no PATH
set "PATH=%DOTNET_DIR%;%PATH%"

:: ─── [1/3] .NET SDK ──────────────────────────────────────────────────────────
echo  [1/3] >> "%LOG%"
echo  [1/3] Verificando .NET SDK...
echo  [1/3] Verificando .NET SDK... >> "%LOG%"

where dotnet >> "%LOG%" 2>&1
dotnet --version >> "%LOG%" 2>&1
if %ERRORLEVEL% equ 0 goto :sdk_ok

echo  SDK nao encontrado. Instalando .NET 10... >> "%LOG%"
echo  SDK nao encontrado. Instalando .NET 10...
echo  (pode demorar alguns minutos)

:: Grava script PS1 de instalacao no disco
set "SDK_PS1=%TEMP%\lg_sdk_install.ps1"
echo $destino = '%DOTNET_DIR%' > "%SDK_PS1%"
echo $script  = '%TEMP%\dotnet-install.ps1' >> "%SDK_PS1%"
echo Write-Host 'Baixando dotnet-install.ps1...' >> "%SDK_PS1%"
echo (New-Object System.Net.WebClient).DownloadFile('https://dot.net/v1/dotnet-install.ps1', $script) >> "%SDK_PS1%"
echo Write-Host 'Instalando .NET 10 SDK...' >> "%SDK_PS1%"
echo ^& $script -Channel 10.0 -InstallDir $destino >> "%SDK_PS1%"
echo Remove-Item $script -Force -ErrorAction SilentlyContinue >> "%SDK_PS1%"
echo Write-Host 'Instalacao SDK concluida.' >> "%SDK_PS1%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SDK_PS1%" >> "%LOG%" 2>&1
echo  Saida do instalador SDK: %ERRORLEVEL% >> "%LOG%"
del "%SDK_PS1%" >nul 2>&1

dotnet --version >> "%LOG%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERRO: .NET SDK ainda nao encontrado apos instalacao. >> "%LOG%"
    echo  Instale manualmente: https://aka.ms/dotnet/download >> "%LOG%"
    echo.
    echo  ERRO: Falha ao instalar .NET SDK.
    echo  Instale manualmente: https://aka.ms/dotnet/download
    echo  Veja detalhes em: %LOG%
    goto :fim_erro
)

:sdk_ok
for /f "tokens=*" %%v in ('dotnet --version 2^>nul') do set "DOTNET_VER=%%v"
echo  OK - .NET %DOTNET_VER% >> "%LOG%"
echo  OK - .NET %DOTNET_VER%
echo. >> "%LOG%"
echo.

:: ─── [2/3] Compilar ──────────────────────────────────────────────────────────
echo  [2/3] >> "%LOG%"
echo  [2/3] Compilando...
echo  [2/3] Compilando... >> "%LOG%"

if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
echo  rmdir: %ERRORLEVEL% >> "%LOG%"
md "%DIST_DIR%"
echo  mkdir: %ERRORLEVEL% >> "%LOG%"

echo  Executando dotnet publish... >> "%LOG%"
dotnet publish "%APP_DIR%\ValidadorApp.csproj" --configuration Release --runtime win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true --output "%DIST_DIR%" >> "%LOG%" 2>&1
echo  dotnet publish saiu com: %ERRORLEVEL% >> "%LOG%"

if %ERRORLEVEL% neq 0 (
    echo  ERRO: dotnet publish falhou com codigo %ERRORLEVEL% >> "%LOG%"
    echo.
    echo  ERRO: Compilacao falhou. Veja o log:
    echo  %LOG%
    goto :fim_erro
)
if not exist "%DIST_DIR%\%EXE_NAME%" (
    echo  ERRO: %EXE_NAME% nao encontrado em %DIST_DIR% >> "%LOG%"
    dir "%DIST_DIR%" >> "%LOG%" 2>&1
    echo.
    echo  ERRO: Executavel nao gerado. Veja o log:
    echo  %LOG%
    goto :fim_erro
)
echo  OK - %EXE_NAME% gerado >> "%LOG%"
echo  OK - %EXE_NAME% gerado.
echo. >> "%LOG%"
echo.

:: ─── [3/3] Atalho ────────────────────────────────────────────────────────────
echo  [3/3] >> "%LOG%"
echo  [3/3] Criando atalho...
echo  [3/3] Criando atalho... >> "%LOG%"

set "PS1=%TEMP%\lg_atalho.ps1"
echo $s = (New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%') > "%PS1%"
echo $s.TargetPath = '%DIST_DIR%\%EXE_NAME%' >> "%PS1%"
echo $s.WorkingDirectory = '%DIST_DIR%' >> "%PS1%"
echo $s.Description = 'Landis+Gyr - Validador XML' >> "%PS1%"
echo $s.Save() >> "%PS1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" >> "%LOG%" 2>&1
echo  atalho powershell saiu com: %ERRORLEVEL% >> "%LOG%"
del "%PS1%" >nul 2>&1

if exist "%SHORTCUT%" (
    echo  OK - Atalho criado >> "%LOG%"
    echo  OK - Atalho criado.
) else (
    echo  Aviso: atalho nao criado >> "%LOG%"
    echo  Aviso: atalho nao criado.
)
echo. >> "%LOG%"
echo.

:: ─── Concluido ───────────────────────────────────────────────────────────────
echo  INSTALACAO CONCLUIDA >> "%LOG%"
echo  ----------------------------------------
echo  Instalacao concluida!
echo  Executavel : %DIST_DIR%\%EXE_NAME%
echo  Atalho     : %SHORTCUT%
echo  Log        : %LOG%
echo  ----------------------------------------
echo.
set /p ABRIR="Abrir o Validador XML agora? (S/N): "
if /i "%ABRIR%"=="S" start "" "%DIST_DIR%\%EXE_NAME%"
goto :fim

:fim_erro
echo  FIM COM ERRO >> "%LOG%"
echo.
echo  Instalacao nao concluida.
echo  Abra o log para ver o que falhou:
echo  %LOG%

:fim
echo.
echo  Pressione qualquer tecla para fechar.
pause >nul
endlocal
