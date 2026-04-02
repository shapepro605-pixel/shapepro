param(
    [string]$JavaHomePath = ""
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   ShapePro - Diagnóstico e Preparação para Google Play  " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$frontendDir = "frontend"
if (-Not (Test-Path $frontendDir)) {
    Write-Host "[ERRO] Pasta 'frontend' não encontrada. Execute este script na raiz do projeto (shapepro)." -ForegroundColor Red
    exit 1
}

Write-Host "`n[1] Verificando Ambiente (JDK & Flutter)..."

# Tentar encontrar o JDK se não for fornecido
if ($JavaHomePath -eq "") {
    $commonJavaPaths = @(
        "C:\Program Files\Android\Android Studio\jbr",
        "C:\Program Files\Java\jdk-17",
        "$env:LOCALAPPDATA\Android\Sdk\jbr"
    )
    foreach ($path in $commonJavaPaths) {
        if (Test-Path "$path\bin\java.exe") {
            $JavaHomePath = $path
            break
        }
    }
}

if ($JavaHomePath -ne "" -and (Test-Path $JavaHomePath)) {
    $env:JAVA_HOME = $JavaHomePath
    $env:Path = "$JavaHomePath\bin;" + $env:Path
    Write-Host " [OK] JDK encontrado em: $JavaHomePath" -ForegroundColor Green
    & java -version
} else {
    Write-Host " [AVISO] JDK não encontrado automaticamente. O build pode falhar se o JAVA_HOME não estiver setado." -ForegroundColor Yellow
}

Write-Host "`n[2] Analisando dependências e aplicando correções nativas..."

$gradleProps = "$frontendDir\android\gradle.properties"
$localProps = "$frontendDir\android\local.properties"
$pubspecFile = "$frontendDir\pubspec.yaml"

# Correção: Desativar Strip
if (Test-Path $gradleProps) {
    $content = Get-Content $gradleProps
    if ($content -notmatch "android.strip_native_libs=false") {
        Add-Content $gradleProps "`nandroid.strip_native_libs=false"
        Add-Content $gradleProps "android.enableLowLevelStrip=false"
        Write-Host " [OK] Regras de desativação do Strip adicionadas." -ForegroundColor Green
    }
}

# Correção: Versão no local.properties
if (Test-Path $localProps) {
    $content = Get-Content $localProps
    $newContent = $content -replace "flutter.versionCode=\d+", "flutter.versionCode=11"
    Set-Content -Path $localProps -Value $newContent
    Write-Host " [OK] Versão no local.properties setada para 11." -ForegroundColor Green
}

# Verificação: Versão no pubspec.yaml
if (Test-Path $pubspecFile) {
    $content = Get-Content $pubspecFile
    if ($content -match "version: 1.0.1\+11") {
        Write-Host " [OK] Versão no pubspec.yaml validada: 1.0.1+11" -ForegroundColor Green
    } else {
        $newContent = $content -replace "version: .*", "version: 1.0.1+11"
        Set-Content -Path $pubspecFile -Value $newContent
        Write-Host " [OK] Versão no pubspec.yaml atualizada para 1.0.1+11" -ForegroundColor Green
    }
}

Write-Host "`n[3] Limpando cache e preparando build..."
Set-Location -Path $frontendDir
$env:FLUTTER_SUPPRESS_ANALYTICS = "true"
flutter clean
flutter pub get

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "   AMBIENTE PRONTO PARA PRODUÇÃO!                        " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

Write-Host "`n🚀 COMANDO PARA GERAR O BUNDLE (AAB):"
Write-Host "flutter build appbundle --release --dart-define=API_URL=https://shapepro-production.up.railway.app" -ForegroundColor Yellow

Write-Host "`n☁️ COMANDO PARA SUBIR AS CORREÇÕES (GIT):"
Write-Host "git add . ; git commit -m 'Finalizing production build and compliance' ; git push origin main" -ForegroundColor Cyan

Write-Host "`nExecute o comando em AMARELO para gerar o arquivo para o Google Play.`n"
