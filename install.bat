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

:: Adiciona dotnet instalado localmente ao PATH desta sessao
set "PATH=%DOTNET_DIR%;%PATH%"

:: ────────────────────────────────────────────────────────────────────
:: [0] Verificar conectividade com a internet
:: ────────────────────────────────────────────────────────────────────
set "INTERNET=0"
ping -n 1 -w 3000 8.8.8.8 >nul 2>&1
if %ERRORLEVEL% equ 0 set "INTERNET=1"
if "!INTERNET!"=="0" (
    ping -n 1 -w 3000 microsoft.com >nul 2>&1
    if !ERRORLEVEL! equ 0 set "INTERNET=1"
)
if "!INTERNET!"=="1" (
    echo  Conexao com a internet: OK
) else (
    echo  Conexao com a internet: nao disponivel
    echo  Downloads serao ignorados - usando apenas o que ja esta instalado.
)
echo.

:: ────────────────────────────────────────────────────────────────────
:: [1/4] Verificar / instalar .NET SDK
:: ────────────────────────────────────────────────────────────────────
echo  [1/4] Verificando .NET SDK...
dotnet --version >nul 2>&1
if %ERRORLEVEL% equ 0 goto :sdk_ok

:: SDK nao encontrado
if "!INTERNET!"=="0" (
    echo  ERRO: .NET SDK nao encontrado e sem internet para instalar.
    echo  Instale manualmente e execute este bat novamente:
    echo  https://aka.ms/dotnet/download
    goto :fim_erro
)

echo  .NET SDK nao encontrado. Instalando automaticamente...
echo  (instalacao local, sem necessidade de administrador)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile '%TEMP%\dotnet-install.ps1' -UseBasicParsing"

if not exist "%TEMP%\dotnet-install.ps1" (
    echo  ERRO: Falha ao baixar o instalador do .NET SDK.
    echo  Instale manualmente: https://aka.ms/dotnet/download
    goto :fim_erro
)

powershell -NoProfile -ExecutionPolicy Bypass ^
    -File "%TEMP%\dotnet-install.ps1" -Channel 10.0 -InstallDir "%DOTNET_DIR%"
del "%TEMP%\dotnet-install.ps1" >nul 2>&1

dotnet --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERRO: Falha na instalacao do .NET SDK.
    echo  Instale manualmente: https://aka.ms/dotnet/download
    goto :fim_erro
)

:sdk_ok
for /f "tokens=*" %%v in ('dotnet --version 2^>nul') do set "DOTNET_VER=%%v"
echo  OK - .NET !DOTNET_VER!
echo.

:: ────────────────────────────────────────────────────────────────────
:: [2/4] Verificar / atualizar WebView2 Runtime
:: ────────────────────────────────────────────────────────────────────
echo  [2/4] Verificando WebView2 Runtime (Microsoft Edge)...

if "!INTERNET!"=="1" (
    echo  Atualizando WebView2 Runtime...
    set "WV2=%TEMP%\WebView2Setup.exe"
    powershell -NoProfile -Command ^
        "Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile '!WV2!' -UseBasicParsing"
    if exist "!WV2!" (
        "!WV2!" /silent /install
        del "!WV2!" >nul 2>&1
        echo  OK - WebView2 Runtime atualizado.
    ) else (
        echo  Aviso: nao foi possivel baixar o WebView2 Runtime.
        echo  O programa pode nao funcionar em PCs com Edge desatualizado.
    )
) else (
    :: Sem internet: verifica se ja esta instalado
    set "WV2_OK=0"
    reg query "HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
    if !ERRORLEVEL! equ 0 set "WV2_OK=1"
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
    if !ERRORLEVEL! equ 0 set "WV2_OK=1"
    reg query "HKCU\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >nul 2>&1
    if !ERRORLEVEL! equ 0 set "WV2_OK=1"
    if "!WV2_OK!"=="1" (
        echo  OK - WebView2 Runtime encontrado.
    ) else (
        echo  AVISO: WebView2 Runtime nao encontrado.
        echo  O programa pode nao abrir. Quando houver internet, reinstale
        echo  ou atualize o Microsoft Edge neste computador.
    )
)
echo.

:: ────────────────────────────────────────────────────────────────────
:: [3/4] Compilar e publicar
:: ────────────────────────────────────────────────────────────────────
echo  [3/4] Compilando...
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
    echo  ERRO: %EXE_NAME% nao foi gerado em %DIST_DIR%
    echo  Arquivos presentes:
    dir /b "%DIST_DIR%" 2>nul
    goto :fim_erro
)
echo  OK - %EXE_NAME% gerado com sucesso.
echo.

:: ────────────────────────────────────────────────────────────────────
:: [4/4] Criar atalho na Area de Trabalho
:: ────────────────────────────────────────────────────────────────────
echo  [4/4] Criando atalho na area de trabalho...
set "PS1=%TEMP%\lg_atalho.ps1"
echo $s = (New-Object -COM WScript.Shell).CreateShortcut('%SHORTCUT%')  > "%PS1%"
echo $s.TargetPath = '%DIST_DIR%\%EXE_NAME%'                           >> "%PS1%"
echo $s.WorkingDirectory = '%DIST_DIR%'                                 >> "%PS1%"
echo $s.Description = 'Landis+Gyr - Validador XML'                     >> "%PS1%"
echo $s.Save()                                                          >> "%PS1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
del "%PS1%" >nul 2>&1
if exist "%SHORTCUT%" (
    echo  OK - Atalho criado na area de trabalho.
) else (
    echo  Aviso: atalho nao foi criado (sem impacto no funcionamento).
)
echo.

:: ────────────────────────────────────────────────────────────────────
:: Concluido
:: ────────────────────────────────────────────────────────────────────
echo  ----------------------------------------
echo  Instalacao concluida com sucesso!
echo  Executavel : %DIST_DIR%\%EXE_NAME%
echo  Atalho     : %SHORTCUT%
echo  ----------------------------------------
echo.
set /p ABRIR="Abrir o Validador XML agora? (S/N): "
if /i "!ABRIR!"=="S" start "" "%DIST_DIR%\%EXE_NAME%"
goto :fim

:: ────────────────────────────────────────────────────────────────────
:: Erros
:: ────────────────────────────────────────────────────────────────────
:fim_erro
echo.
echo  ----------------------------------------
echo  Instalacao nao foi concluida.
echo  Leia as mensagens acima para mais detalhes.
echo  ----------------------------------------

:fim
echo.
echo  Pressione qualquer tecla para fechar.
pause >nul
endlocal
