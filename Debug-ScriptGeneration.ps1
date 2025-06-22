# Debug-ScriptGeneration.ps1
# スクリプト生成をデバッグするためのテストスクリプト

# Create-MinimalUbuntuWSL.ps1から関数をコピー
function Get-MinimalSetupScript {
    param(
        [bool]$WithPodman,
        [bool]$WithGitHubCLI,
        [bool]$WithClaudeCode
    )
    
    $script = @'
#!/bin/bash
# Minimal Ubuntu Setup Script
set -euo pipefail

echo "================================================="
echo " Starting Ubuntu Minimization"
echo "================================================="
echo ""

# Test section
echo "Testing dpkg command..."
dpkg --version || echo "dpkg not found!"

'@

    # GitHub CLI インストール（問題のある部分）
    if ($WithGitHubCLI) {
        $script += @"

# GitHub CLI インストール
echo "[X/X] Installing GitHub CLI..."

# Test: Check if dpkg is accessible
which dpkg || echo "dpkg not in PATH"

# GitHub CLI GPGキー追加
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1

# リポジトリ追加
echo "deb [arch=`$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

"@
    }

    return $script
}

# テスト実行
Write-Host "Generating test script with GitHub CLI..." -ForegroundColor Cyan
$testScript = Get-MinimalSetupScript -WithGitHubCLI $true

# スクリプトを一時ファイルに保存
$tempFile = "$env:TEMP\test-script-$(Get-Random).sh"
$testScript | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Generated script saved to: $tempFile" -ForegroundColor Green
Write-Host ""
Write-Host "Script content preview:" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow

# スクリプトの内容を表示（最初の50行）
Get-Content $tempFile | Select-Object -First 50 | ForEach-Object {
    Write-Host $_
}

Write-Host ""
Write-Host "Checking for potential issues..." -ForegroundColor Yellow

# 潜在的な問題をチェック
$content = Get-Content $tempFile -Raw
if ($content -match '\$\(dpkg') {
    Write-Host "Found: `$(dpkg...) pattern - this should work in bash" -ForegroundColor Green
}
if ($content -match '\\$\(dpkg') {
    Write-Host "Found: \`$(dpkg...) pattern - this might cause issues" -ForegroundColor Red
}

# 一時ファイルをクリーンアップ
Remove-Item $tempFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Debug complete." -ForegroundColor Cyan