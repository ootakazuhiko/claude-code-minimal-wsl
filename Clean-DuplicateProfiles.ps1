# Clean-DuplicateProfiles.ps1
# Windows Terminalの重複したWSLプロファイルをクリーンアップ

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

Write-ColorOutput Cyan @"

=====================================
 Clean Duplicate WSL Profiles
=====================================

This script will identify and optionally remove
duplicate WSL profiles in Windows Terminal.

"@

$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (-not (Test-Path $settingsPath)) {
    Write-ColorOutput Red "Windows Terminal settings not found!"
    return
}

try {
    # 設定ファイルのバックアップ
    $backupPath = "$settingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $settingsPath $backupPath
    Write-Host "Created backup: $backupPath" -ForegroundColor Gray
    Write-Host ""
    
    # 設定を読み込み
    $settingsContent = Get-Content $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json
    
    # プロファイルを分析
    $wslProfiles = @{}
    $duplicates = @()
    
    foreach ($profile in $settings.profiles.list) {
        # WSL関連のプロファイルを検出
        if ($profile.source -eq "Windows.Terminal.Wsl" -or 
            $profile.commandline -like "*wsl.exe*" -or
            $profile.name -like "*Ubuntu*" -or
            $profile.name -like "*WSL*") {
            
            # ディストリビューション名を抽出
            $distroName = ""
            if ($profile.commandline -match "-d\s+([^\s]+)") {
                $distroName = $matches[1]
            } elseif ($profile.name -match "(Ubuntu-[^\s]+)") {
                $distroName = $matches[1]
            } else {
                $distroName = $profile.name
            }
            
            if (-not $wslProfiles.ContainsKey($distroName)) {
                $wslProfiles[$distroName] = @()
            }
            $wslProfiles[$distroName] += $profile
        }
    }
    
    # 重複を報告
    Write-Host "WSL Profile Analysis:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($distro in $wslProfiles.Keys) {
        $profiles = $wslProfiles[$distro]
        if ($profiles.Count -gt 1) {
            Write-Host "Distribution: $distro" -ForegroundColor Cyan
            Write-Host "  Found $($profiles.Count) profiles:" -ForegroundColor Yellow
            
            $keepProfile = $null
            foreach ($profile in $profiles) {
                $info = "    - Name: '$($profile.name)'"
                if ($profile.source) { $info += ", Source: $($profile.source)" }
                if ($profile.icon -eq "🤖") { 
                    $info += " [Claude Theme]"
                    $keepProfile = $profile
                }
                Write-Host $info
            }
            
            # Claude テーマが適用されていない場合は、自動生成を優先
            if (-not $keepProfile) {
                $keepProfile = $profiles | Where-Object { $_.source -eq "Windows.Terminal.Wsl" } | Select-Object -First 1
            }
            if (-not $keepProfile) {
                $keepProfile = $profiles[0]
            }
            
            # 削除対象を特定
            foreach ($profile in $profiles) {
                if ($profile -ne $keepProfile) {
                    $duplicates += $profile
                }
            }
            
            Write-Host "  → Keeping: '$($keepProfile.name)'" -ForegroundColor Green
            Write-Host ""
        }
    }
    
    if ($duplicates.Count -eq 0) {
        Write-ColorOutput Green "No duplicate profiles found!"
        return
    }
    
    # 削除確認
    Write-Host "Found $($duplicates.Count) duplicate profile(s) to remove:" -ForegroundColor Yellow
    foreach ($dup in $duplicates) {
        Write-Host "  - $($dup.name)" -ForegroundColor Red
    }
    Write-Host ""
    
    if ($DryRun) {
        Write-ColorOutput Yellow "DRY RUN: No changes made. Run without -DryRun to apply changes."
    } else {
        $confirm = Read-Host "Remove these duplicate profiles? (Y/N)"
        if ($confirm -eq 'Y' -or $confirm -eq 'y') {
            # 重複を削除
            foreach ($dup in $duplicates) {
                $settings.profiles.list = @($settings.profiles.list | Where-Object { $_ -ne $dup })
            }
            
            # 設定を保存
            $json = $settings | ConvertTo-Json -Depth 10
            Set-Content -Path $settingsPath -Value $json -Encoding UTF8
            
            Write-ColorOutput Green "✓ Removed $($duplicates.Count) duplicate profile(s)"
            Write-Host ""
            Write-Host "Please restart Windows Terminal to see the changes." -ForegroundColor Yellow
        } else {
            Write-Host "Operation cancelled." -ForegroundColor Gray
        }
    }
    
} catch {
    Write-ColorOutput Red "Error: $_"
    if (Test-Path $backupPath) {
        Write-Host "You can restore from backup: $backupPath" -ForegroundColor Yellow
    }
}