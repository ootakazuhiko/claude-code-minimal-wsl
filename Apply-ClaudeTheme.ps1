# Apply-ClaudeTheme.ps1
# 既存のWSLインスタンスにClaude Tealテーマを適用

param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceName
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

Write-ColorOutput Cyan @"

=====================================
 Apply Claude Theme to WSL Instance
=====================================

This script will apply the Claude Dark Teal theme
to an existing WSL instance.

"@

# Windows Terminal プロファイル設定関数（Create-MinimalUbuntuWSL.ps1から抜粋）
function Set-ClaudeTerminalProfile {
    param(
        [string]$InstanceName,
        [string]$BackgroundColor = "#001414"  # より暗いティール色
    )
    
    Write-Host "Setting up Windows Terminal profile..." -ForegroundColor Yellow
    
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    if (-not (Test-Path $settingsPath)) {
        Write-Host "Windows Terminal not found, skipping profile setup" -ForegroundColor Gray
        return
    }
    
    try {
        # 設定ファイルを読み込み
        $settingsContent = Get-Content $settingsPath -Raw
        $settings = $settingsContent | ConvertFrom-Json
        
        # Claude用カラースキーム追加（より暗いティール）
        $claudeScheme = @{
            "name" = "Claude-Dark-Teal"
            "background" = "#001414"  # より暗いティール
            "foreground" = "#e0e0e0"
            "black" = "#000000"
            "blue" = "#5eb7f7"
            "brightBlue" = "#81d4fa"
            "cyan" = "#4dd0e1"
            "brightCyan" = "#84ffff"
            "green" = "#69f0ae"
            "brightGreen" = "#b9f6ca"
            "purple" = "#ce93d8"
            "brightPurple" = "#e1bee7"
            "red" = "#ff5252"
            "brightRed" = "#ff8a80"
            "white" = "#eceff1"
            "brightWhite" = "#ffffff"
            "yellow" = "#ffeb3b"
            "brightYellow" = "#ffff8d"
            "gray" = "#546e7a"
            "brightGray" = "#90a4ae"
            "cursorColor" = "#00ffff"
            "selectionBackground" = "#264040"
        }
        
        # 既存のスキームをチェック
        if (-not $settings.schemes) {
            $settings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @() -Force
        }
        
        $schemeExists = $settings.schemes | Where-Object { $_.name -eq "Claude-Dark-Teal" }
        if (-not $schemeExists) {
            $settings.schemes += $claudeScheme
        } else {
            # 既存のスキームを更新
            $index = [array]::IndexOf($settings.schemes, $schemeExists)
            $settings.schemes[$index] = $claudeScheme
        }
        
        # Claude用プロファイル追加
        $claudeProfile = @{
            "name" = "$InstanceName 🤖"
            "commandline" = "wsl.exe -d $InstanceName"
            "colorScheme" = "Claude-Dark-Teal"
            "icon" = "🤖"
            "useAcrylic" = $true
            "acrylicOpacity" = 0.90
            "tabColor" = "#00796b"
            "startingDirectory" = "//wsl$/$InstanceName/home/wsluser"
            "font" = @{
                "face" = "Cascadia Code"
                "size" = 12
            }
            "background" = "#001414"  # 明示的に背景色を指定
        }
        
        # 既存プロファイルをチェック
        $profileExists = $settings.profiles.list | Where-Object { $_.name -eq "$InstanceName 🤖" }
        if ($profileExists) {
            # 既存プロファイルを更新
            $index = [array]::IndexOf($settings.profiles.list, $profileExists)
            $settings.profiles.list[$index] = $claudeProfile
        } else {
            # 新規プロファイルを追加
            $settings.profiles.list += $claudeProfile
        }
        
        # 設定を保存（整形して保存）
        $json = $settings | ConvertTo-Json -Depth 10
        Set-Content -Path $settingsPath -Value $json -Encoding UTF8
        
        Write-ColorOutput Green "✓ Windows Terminal profile created: '$InstanceName 🤖'"
        Write-Host "  Background: Dark Teal (#001414) - Claude専用色" -ForegroundColor Gray
        Write-Host "  Tab color: Dark Cyan (#00796b)" -ForegroundColor Gray
        Write-Host "  To use: Windows Terminal → Click dropdown → Select '$InstanceName 🤖'" -ForegroundColor Gray
        Write-Host ""
        Write-ColorOutput Yellow "Note: You may need to restart Windows Terminal for the changes to take effect"
        
    } catch {
        Write-ColorOutput Yellow "Warning: Could not update Windows Terminal settings: $_"
    }
}

# メイン処理
Write-Host "Applying Claude theme to: $InstanceName" -ForegroundColor Yellow
Write-Host ""

# Windows Terminal設定を適用
Set-ClaudeTerminalProfile -InstanceName $InstanceName

Write-Host ""
Write-ColorOutput Green "Theme application complete!"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Close all Windows Terminal windows" -ForegroundColor Gray
Write-Host "2. Open Windows Terminal" -ForegroundColor Gray
Write-Host "3. Select '$InstanceName 🤖' from the dropdown menu" -ForegroundColor Gray
Write-Host "4. The terminal should now have a dark teal background" -ForegroundColor Gray
Write-Host ""
Write-Host "If the background doesn't change:" -ForegroundColor Yellow
Write-Host "- Try closing and reopening Windows Terminal completely" -ForegroundColor Gray
Write-Host "- Check Windows Terminal Settings → Profiles → '$InstanceName 🤖'" -ForegroundColor Gray
Write-Host "- Ensure 'Color scheme' is set to 'Claude-Dark-Teal'" -ForegroundColor Gray