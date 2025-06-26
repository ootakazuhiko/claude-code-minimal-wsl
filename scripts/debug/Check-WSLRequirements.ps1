# Check-WSLRequirements.ps1
# WSL環境の要件確認スクリプト

$ErrorActionPreference = "Stop"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

Write-ColorOutput Cyan @"

=====================================
 WSL Requirements Check
=====================================

"@

# 1. Windows バージョン確認
Write-Host "1. Checking Windows version..." -ForegroundColor Yellow
$os = Get-WmiObject -Class Win32_OperatingSystem
$version = [System.Version]$os.Version
$build = $os.BuildNumber

Write-Host "   Windows Version: $($os.Caption)" -ForegroundColor Gray
Write-Host "   Build: $build" -ForegroundColor Gray

if ($version.Major -ge 10 -and $build -ge 19041) {
    Write-ColorOutput Green "   ✓ Windows version is compatible with WSL2"
} else {
    Write-ColorOutput Red "   ✗ Windows version may not support WSL2"
    Write-Host "   Required: Windows 10 build 19041 or higher" -ForegroundColor Gray
}

Write-Host ""

# 2. WSLインストール確認
Write-Host "2. Checking WSL installation..." -ForegroundColor Yellow

$wslInstalled = $false
$wslVersion = $null

try {
    # WSLコマンドの存在確認
    $wslPath = "$env:SystemRoot\System32\wsl.exe"
    if (Test-Path $wslPath) {
        Write-Host "   WSL executable found at: $wslPath" -ForegroundColor Gray
        
        # WSLバージョン確認
        $wslOutput = & wsl --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $wslInstalled = $true
            Write-ColorOutput Green "   ✓ WSL is installed"
            Write-Host "   Version info:" -ForegroundColor Gray
            $wslOutput | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
        } else {
            Write-ColorOutput Yellow "   ⚠ WSL found but version check failed"
        }
    } else {
        Write-ColorOutput Red "   ✗ WSL not found"
    }
} catch {
    Write-ColorOutput Red "   ✗ Error checking WSL: $_"
}

Write-Host ""

# 3. 仮想化機能の確認
Write-Host "3. Checking virtualization features..." -ForegroundColor Yellow

# Hyper-V
$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($hyperV -and $hyperV.State -eq "Enabled") {
    Write-ColorOutput Green "   ✓ Hyper-V is enabled"
} else {
    Write-ColorOutput Yellow "   ⚠ Hyper-V is not enabled (optional for WSL2)"
}

# Virtual Machine Platform
$vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
if ($vmp -and $vmp.State -eq "Enabled") {
    Write-ColorOutput Green "   ✓ Virtual Machine Platform is enabled"
} else {
    Write-ColorOutput Red "   ✗ Virtual Machine Platform is not enabled (required for WSL2)"
}

# WSL Feature
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
if ($wslFeature -and $wslFeature.State -eq "Enabled") {
    Write-ColorOutput Green "   ✓ Windows Subsystem for Linux is enabled"
} else {
    Write-ColorOutput Red "   ✗ Windows Subsystem for Linux is not enabled"
}

Write-Host ""

# 4. 既存のWSLディストリビューション確認
if ($wslInstalled) {
    Write-Host "4. Checking existing WSL distributions..." -ForegroundColor Yellow
    try {
        $distros = wsl --list --quiet 2>$null
        if ($distros) {
            Write-Host "   Found distributions:" -ForegroundColor Gray
            $distros | Where-Object { $_ -ne "" } | ForEach-Object { 
                Write-Host "     - $_" -ForegroundColor Gray 
            }
        } else {
            Write-Host "   No distributions installed" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   Could not list distributions" -ForegroundColor Yellow
    }
    Write-Host ""
}

# 5. 推奨事項
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host ""

if (-not $wslInstalled) {
    Write-Host "To install WSL:" -ForegroundColor Yellow
    Write-Host "1. Open PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "2. Run the following command:" -ForegroundColor Gray
    Write-Host "   wsl --install" -ForegroundColor White
    Write-Host "3. Restart your computer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For manual installation:" -ForegroundColor Yellow
    Write-Host "   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" -ForegroundColor Gray
    Write-Host "   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "For more information:" -ForegroundColor Yellow
Write-Host "https://learn.microsoft.com/en-us/windows/wsl/install" -ForegroundColor Gray
Write-Host ""

# 6. PowerShell実行ポリシー確認
Write-Host "PowerShell Execution Policy:" -ForegroundColor Yellow
$policy = Get-ExecutionPolicy
Write-Host "   Current policy: $policy" -ForegroundColor Gray

if ($policy -eq "Restricted") {
    Write-ColorOutput Yellow "   ⚠ Execution policy is restricted"
    Write-Host "   To run scripts, use one of these commands:" -ForegroundColor Gray
    Write-Host "     Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process" -ForegroundColor White
    Write-Host "     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
} else {
    Write-ColorOutput Green "   ✓ Scripts can be executed"
}

Write-Host ""
Write-Host "Check complete!" -ForegroundColor Green