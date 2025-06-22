# Register-Ubuntu2204.ps1
# Windows StoreのUbuntu 22.04をWSLに登録するスクリプト

Write-Host "Ubuntu 22.04 WSL Registration Helper" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Warning: Running without administrator privileges" -ForegroundColor Yellow
    Write-Host "Some operations may require admin rights" -ForegroundColor Yellow
    Write-Host ""
}

# 1. 現在のWSLディストリビューション確認
Write-Host "1. Current WSL distributions:" -ForegroundColor Yellow
wsl -l -v
Write-Host ""

# 2. Ubuntu 22.04の実行ファイルを探す
Write-Host "2. Searching for Ubuntu 22.04 executable..." -ForegroundColor Yellow

$possiblePaths = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\ubuntu2204.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\CanonicalGroupLimited.Ubuntu22.04LTS_79rhkp1fndgsc\ubuntu2204.exe",
    "$env:ProgramFiles\WindowsApps\CanonicalGroupLimited.Ubuntu22.04LTS*\ubuntu2204.exe"
)

$ubuntu2204Exe = $null

foreach ($path in $possiblePaths) {
    if ($path -contains '*') {
        $files = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        if ($files) {
            $ubuntu2204Exe = $files[0].FullName
            break
        }
    } elseif (Test-Path $path) {
        $ubuntu2204Exe = $path
        break
    }
}

if ($ubuntu2204Exe) {
    Write-Host "Found Ubuntu 22.04 executable: $ubuntu2204Exe" -ForegroundColor Green
} else {
    # より広範な検索
    Write-Host "Searching in WindowsApps directory..." -ForegroundColor Gray
    
    try {
        $appPath = Get-AppxPackage -Name "*Ubuntu*22.04*" | Select-Object -ExpandProperty InstallLocation
        if ($appPath) {
            $exeSearch = Get-ChildItem -Path $appPath -Filter "ubuntu*.exe" -ErrorAction SilentlyContinue
            if ($exeSearch) {
                $ubuntu2204Exe = $exeSearch[0].FullName
                Write-Host "Found Ubuntu 22.04 executable: $ubuntu2204Exe" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error searching for Ubuntu executable: $_" -ForegroundColor Red
    }
}

if (-not $ubuntu2204Exe) {
    Write-Host ""
    Write-Host "Ubuntu 22.04 executable not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try:" -ForegroundColor Yellow
    Write-Host "1. Open Microsoft Store" -ForegroundColor Cyan
    Write-Host "2. Search for 'Ubuntu 22.04'" -ForegroundColor Cyan
    Write-Host "3. Click 'Install' or 'Get'" -ForegroundColor Cyan
    Write-Host "4. After installation, click 'Launch' once" -ForegroundColor Cyan
    Write-Host "5. Set up username and password" -ForegroundColor Cyan
    Write-Host "6. Run this script again" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# 3. Ubuntu 22.04の初期化確認
Write-Host "3. Checking Ubuntu 22.04 initialization..." -ForegroundColor Yellow

$needsInit = $false

# WSLに登録されているか確認
$wslList = wsl -l -q 2>$null | Out-String
if ($wslList -notmatch "Ubuntu-22\.04|Ubuntu22\.04") {
    Write-Host "Ubuntu 22.04 is not registered in WSL" -ForegroundColor Yellow
    $needsInit = $true
} else {
    Write-Host "Ubuntu 22.04 is already registered in WSL" -ForegroundColor Green
}

Write-Host ""

# 4. 初期化が必要な場合
if ($needsInit) {
    Write-Host "4. Initializing Ubuntu 22.04..." -ForegroundColor Yellow
    Write-Host "This will open Ubuntu 22.04 for initial setup." -ForegroundColor Cyan
    Write-Host "Please:" -ForegroundColor Cyan
    Write-Host "  1. Enter a username when prompted" -ForegroundColor Gray
    Write-Host "  2. Enter a password (twice)" -ForegroundColor Gray
    Write-Host "  3. After setup, type 'exit' to close Ubuntu" -ForegroundColor Gray
    Write-Host ""
    
    $continue = Read-Host "Press Enter to continue, or 'q' to quit"
    if ($continue -eq 'q') {
        exit 0
    }
    
    # Ubuntu 22.04を起動
    Write-Host "Starting Ubuntu 22.04..." -ForegroundColor Gray
    Start-Process -FilePath $ubuntu2204Exe -Wait
    
    Write-Host ""
    Write-Host "Checking registration again..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

# 5. 最終確認
Write-Host "5. Final check:" -ForegroundColor Yellow
$finalList = wsl -l -v 2>$null

if ($finalList -match "Ubuntu-22\.04|Ubuntu22\.04") {
    Write-Host "✓ Ubuntu 22.04 is now registered in WSL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now use it with:" -ForegroundColor Cyan
    Write-Host "  wsl -d Ubuntu-22.04" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or use it with the minimal image creator:" -ForegroundColor Cyan
    Write-Host "  .\Create-MinimalUbuntuWSL.ps1 -Action CreateBase" -ForegroundColor Gray
} else {
    Write-Host "Ubuntu 22.04 is still not showing in WSL" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual steps to try:" -ForegroundColor Yellow
    Write-Host "1. Open Start Menu" -ForegroundColor Cyan
    Write-Host "2. Search for 'Ubuntu 22.04'" -ForegroundColor Cyan
    Write-Host "3. Click on it to open" -ForegroundColor Cyan
    Write-Host "4. Complete the setup process" -ForegroundColor Cyan
    Write-Host "5. Check again with: wsl -l -v" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Current WSL distributions:" -ForegroundColor Yellow
wsl -l -v