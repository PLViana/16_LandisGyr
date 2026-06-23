$ErrorActionPreference = 'Continue'

$ROOT     = $PSScriptRoot
$APP_DIR  = Join-Path $ROOT "ValidadorApp"
$DIST_DIR = Join-Path $env:APPDATA "ValidadorLG"
$EXE_NAME = "ValidadorXML.exe"
$EXE_PATH = Join-Path $DIST_DIR $EXE_NAME
$SHORTCUT = Join-Path $env:USERPROFILE "Desktop\Validador XML LG.lnk"

Write-Host ""
Write-Host " Landis+Gyr - Validador XML - Instalador"
Write-Host " ----------------------------------------"
Write-Host " Destino: $DIST_DIR"
Write-Host ""

# ── [1/3] .NET SDK ───────────────────────────────────────────────────────────
Write-Host " [1/3] Verificando .NET SDK..."

$dotnetVersion = & dotnet --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host " ERRO: .NET 10 SDK nao encontrado."
    Write-Host " Instale e execute este instalador novamente:"
    Write-Host " https://aka.ms/dotnet/download"
    Write-Host ""
    Start-Process "https://aka.ms/dotnet/download"
    Read-Host " Pressione Enter para fechar"
    exit 1
}

Write-Host " OK - .NET $dotnetVersion"
Write-Host ""

# ── [2/3] Compilar ───────────────────────────────────────────────────────────
Write-Host " [2/3] Compilando..."

if (Test-Path $DIST_DIR) {
    Remove-Item $DIST_DIR -Recurse -Force
}
New-Item -ItemType Directory -Path $DIST_DIR -Force | Out-Null

$csproj = Join-Path $APP_DIR "ValidadorApp.csproj"

& dotnet publish $csproj `
    --configuration Release `
    --runtime win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    --output $DIST_DIR

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host " ERRO: Compilacao falhou (codigo $LASTEXITCODE)."
    Read-Host " Pressione Enter para fechar"
    exit 1
}

if (-not (Test-Path $EXE_PATH)) {
    Write-Host ""
    Write-Host " ERRO: $EXE_NAME nao foi gerado em $DIST_DIR"
    Write-Host " Arquivos presentes:"
    Get-ChildItem $DIST_DIR | ForEach-Object { Write-Host "   $($_.Name)" }
    Read-Host " Pressione Enter para fechar"
    exit 1
}

Write-Host " OK - $EXE_NAME gerado."
Write-Host ""

# ── [3/3] Atalho ─────────────────────────────────────────────────────────────
Write-Host " [3/3] Criando atalho na area de trabalho..."

try {
    $shell = New-Object -COM WScript.Shell
    $s = $shell.CreateShortcut($SHORTCUT)
    $s.TargetPath      = $EXE_PATH
    $s.WorkingDirectory = $DIST_DIR
    $s.Description     = "Landis+Gyr - Validador XML"
    $s.Save()
    Write-Host " OK - Atalho criado."
} catch {
    Write-Host " Aviso: atalho nao criado - $($_.Exception.Message)"
}
Write-Host ""

# ── WebView2: apenas verificar ────────────────────────────────────────────────
$wv2Keys = @(
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
    "HKCU:\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
)
$wv2Found = $wv2Keys | Where-Object { Test-Path $_ }
if (-not $wv2Found) {
    Write-Host " AVISO: WebView2 nao detectado. Se o programa nao abrir,"
    Write-Host " atualize o Microsoft Edge: Configuracoes > Sobre o Microsoft Edge"
    Write-Host ""
}

# ── Concluido ─────────────────────────────────────────────────────────────────
Write-Host " ----------------------------------------"
Write-Host " Instalacao concluida!"
Write-Host " Executavel : $EXE_PATH"
Write-Host " Atalho     : $SHORTCUT"
Write-Host " ----------------------------------------"
Write-Host ""

$resp = Read-Host " Abrir o Validador XML agora? (S/N)"
if ($resp -ieq "S") {
    Start-Process $EXE_PATH
}
