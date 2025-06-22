# Check-WSLDistributions.ps1
# WSL環境の診断スクリプト

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " WSL Distribution Checker" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    Write-Host "Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "Running as regular user (some checks may be limited)" -ForegroundColor Yellow
}
Write-Host ""

# 1. WSL状態確認
Write-Host "1. Checking WSL Status:" -ForegroundColor Yellow
try {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "WSL is installed and available" -ForegroundColor Green
        # WSLバージョン情報を表示
        $wslVersion = wsl --version 2>&1 | Out-String
        if ($wslVersion -match "WSL バージョン|WSL version") {
            Write-Host $wslVersion -ForegroundColor Gray
        }
    } else {
        Write-Host "WSL is not properly installed or configured" -ForegroundColor Red
        Write-Host $wslStatus -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking WSL status: $_" -ForegroundColor Red
}
Write-Host ""

# 2. インストール済みディストリビューション確認
Write-Host "2. Currently Installed Distributions:" -ForegroundColor Yellow
try {
    # 方法1: wsl --list --verbose
    Write-Host "   Method 1 (wsl -l -v):" -ForegroundColor Cyan
    $installedDistros = wsl -l -v 2>&1
    if ($LASTEXITCODE -eq 0) {
        $installedDistros | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "   No distributions found or error occurred" -ForegroundColor Red
    }
    
    # 方法2: wsl --list --quiet (名前のみ)
    Write-Host ""
    Write-Host "   Method 2 (wsl -l -q):" -ForegroundColor Cyan
    $quietList = wsl -l -q 2>&1
    if ($LASTEXITCODE -eq 0) {
        $distroNames = $quietList | Where-Object { $_ -match '\S' }
        if ($distroNames) {
            $distroNames | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
            
            # Ubuntu-22.04の確認
            if ($distroNames -match "Ubuntu-22\.04") {
                Write-Host "   ✓ Ubuntu-22.04 is installed!" -ForegroundColor Green
            } else {
                Write-Host "   ✗ Ubuntu-22.04 is NOT installed" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "   Error listing distributions: $_" -ForegroundColor Red
}
Write-Host ""

# 3. 利用可能なディストリビューション確認
Write-Host "3. Available Distributions for Installation:" -ForegroundColor Yellow
try {
    Write-Host "   Running: wsl --list --online" -ForegroundColor Gray
    $availableDistros = wsl --list --online 2>&1 | Out-String
    
    # 出力を行ごとに処理
    $lines = $availableDistros -split "`n"
    $distroFound = $false
    $ubuntu2204Found = $false
    
    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()
        
        # ヘッダーや空行をスキップ
        if ($trimmedLine -eq "" -or 
            $trimmedLine -match "NAME\s+FRIENDLY" -or 
            $trimmedLine -match "インストールできる" -or
            $trimmedLine -match "The following is a list") {
            continue
        }
        
        # ディストリビューション行を検出
        if ($trimmedLine -match "^([A-Za-z0-9\-\.]+)\s+") {
            $distroName = $matches[1]
            if ($distroName) {
                $distroFound = $true
                Write-Host "   - $distroName" -ForegroundColor Gray
                
                if ($distroName -eq "Ubuntu-22.04") {
                    $ubuntu2204Found = $true
                    Write-Host "     ✓ Ubuntu-22.04 is available!" -ForegroundColor Green
                }
            }
        }
    }
    
    if (-not $distroFound) {
        Write-Host "   Could not parse distribution list" -ForegroundColor Yellow
        Write-Host "   Raw output:" -ForegroundColor Gray
        Write-Host $availableDistros -ForegroundColor Gray
    }
    
    if (-not $ubuntu2204Found) {
        Write-Host ""
        Write-Host "   ⚠ Ubuntu-22.04 is NOT in the available list" -ForegroundColor Yellow
        Write-Host "   This might be why installation is failing" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   Error checking available distributions: $_" -ForegroundColor Red
}
Write-Host ""

# 4. Windows Storeアプリの確認
Write-Host "4. Checking Windows Store Apps:" -ForegroundColor Yellow
try {
    $ubuntuApps = Get-AppxPackage | Where-Object { $_.Name -match "Ubuntu" }
    if ($ubuntuApps) {
        Write-Host "   Found Ubuntu-related apps:" -ForegroundColor Green
        $ubuntuApps | ForEach-Object {
            Write-Host "   - $($_.Name) (Version: $($_.Version))" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No Ubuntu apps found in Windows Store" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Error checking Windows Store apps: $_" -ForegroundColor Red
}
Write-Host ""

# 5. システム情報
Write-Host "5. System Information:" -ForegroundColor Yellow
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "   Windows Version: $($os.Caption) $($os.Version)" -ForegroundColor Gray
    Write-Host "   Architecture: $($os.OSArchitecture)" -ForegroundColor Gray
    
    # 空き容量確認
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    Write-Host "   Free disk space: ${freeGB}GB" -ForegroundColor Gray
    
    if ($freeGB -lt 10) {
        Write-Host "   ⚠ Low disk space! WSL distributions need several GB" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Error getting system information: $_" -ForegroundColor Red
}
Write-Host ""

# 6. WSL関連のWindowsフィーチャー確認
if ($isAdmin) {
    Write-Host "6. Windows Features Status:" -ForegroundColor Yellow
    try {
        $features = @(
            @{Name="Microsoft-Windows-Subsystem-Linux"; DisplayName="Windows Subsystem for Linux"},
            @{Name="VirtualMachinePlatform"; DisplayName="Virtual Machine Platform"},
            @{Name="Microsoft-Hyper-V"; DisplayName="Hyper-V"}
        )
        
        foreach ($feature in $features) {
            $state = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue
            if ($state) {
                $status = if ($state.State -eq "Enabled") { "✓ Enabled" } else { "✗ Disabled" }
                $color = if ($state.State -eq "Enabled") { "Green" } else { "Red" }
                Write-Host "   $($feature.DisplayName): $status" -ForegroundColor $color
            }
        }
    } catch {
        Write-Host "   Error checking Windows features: $_" -ForegroundColor Red
    }
} else {
    Write-Host "6. Windows Features Status: (Run as Administrator to check)" -ForegroundColor Yellow
}
Write-Host ""

# 7. 推奨事項
Write-Host "7. Recommendations:" -ForegroundColor Yellow

# Ubuntu-22.04が利用可能でない場合の対処法
$recommendations = @()

if (-not $ubuntu2204Found) {
    $recommendations += "Ubuntu-22.04 is not in the available distributions list. Try:"
    $recommendations += "  - Use 'Ubuntu' (default version) instead"
    $recommendations += "  - Check if Windows Store has Ubuntu 22.04 app"
    $recommendations += "  - Ensure Windows is fully updated"
}

if ($freeGB -lt 10) {
    $recommendations += "Free up disk space (at least 10GB recommended)"
}

if (-not $isAdmin) {
    $recommendations += "Run this script as Administrator for complete diagnostics"
}

if ($recommendations.Count -gt 0) {
    $recommendations | ForEach-Object { Write-Host "   $_" -ForegroundColor Cyan }
} else {
    Write-Host "   Everything looks good!" -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 最後に直接インストールを試みる提案
Write-Host "Quick Fix Attempt:" -ForegroundColor Yellow
Write-Host "If Ubuntu-22.04 is not available, try installing the default Ubuntu:" -ForegroundColor Cyan
Write-Host "  wsl --install -d Ubuntu" -ForegroundColor Gray
Write-Host ""
Write-Host "Or check Microsoft Store for specific Ubuntu versions." -ForegroundColor Cyan