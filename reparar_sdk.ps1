$sdkRoot = "C:\Users\mae12\AppData\Local\Android\sdk"
$toolsDir = "$sdkRoot\cmdline-tools"
$latestDir = "$toolsDir\latest"
$zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zipPath = "$env:TEMP\cmd-tools_latest.zip"
$extractTemp = "$env:TEMP\cmd-tools_extract"

Write-Host "--- Android SDK Repair - Initializing ---" -ForegroundColor Cyan

# 1. Download Tools
if (-Not (Test-Path $zipPath)) {
    Write-Host "[1/4] Downloading cmdline-tools from Google..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
} else {
    Write-Host "[1/4] Zip already exists in TEMP, skipping download." -ForegroundColor Green
}

# 2. Extract and Organize
Write-Host "[2/4] Extracting and organizing folders..."
if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
New-Item -ItemType Directory -Path $extractTemp -Force
Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force

# Google's zip has a nested 'cmdline-tools' folder
# Expected structure: sdkRoot\cmdline-tools\latest\bin...
if (-Not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force }
if (Test-Path $latestDir) { Remove-Item $latestDir -Recurse -Force }

# Move the 'cmdline-tools' folder from zip to 'latest'
Move-Item -Path "$extractTemp\cmdline-tools" -Destination $latestDir -Force
Remove-Item $extractTemp -Recurse -Force

Write-Host " [OK] Tools installed/organized to $latestDir" -ForegroundColor Green

# 3. Accept Licenses
Write-Host "[3/4] Accepting Android Licenses (sdkmanager --licenses)..."
# We need to use the absolute path to sdkmanager.bat
$sdkManager = "$latestDir\bin\sdkmanager.bat"
if (Test-Path $sdkManager) {
    # Pipe "y" to accept all
    $yesArray = @("y") * 20
    $yesArray | & $sdkManager --sdk_root=$sdkRoot --licenses
    Write-Host " [OK] Licenses accepted." -ForegroundColor Green
} else {
    Write-Host "[ERRO] sdkmanager not found at $sdkManager" -ForegroundColor Red
}

# 4. Final Flutter Doctor Check
Write-Host "[4/4] Final check with flutter doctor..."
flutter doctor --android-licenses # Double check if any left
flutter doctor

Write-Host "`n--- REPAIR COMPLETED! ---" -ForegroundColor Cyan
Write-Host "Now try building your app again."
