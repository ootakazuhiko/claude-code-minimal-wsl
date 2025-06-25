# Test-MinimalWSL.ps1
# 最小構成WSLインスタンスの問題をテストするスクリプト

param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceName
)

$ErrorActionPreference = "Continue"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

Write-ColorOutput Cyan @"

=====================================
 Testing Minimal WSL Instance
=====================================

"@

# テストスクリプト
$testScript = @'
#!/bin/bash

echo "=== Testing WSL Instance Configuration ==="
echo ""

echo "1. Checking resolv.conf:"
ls -la /etc/resolv.conf
cat /etc/resolv.conf
echo ""

echo "2. Testing DNS resolution:"
echo -n "  getent hosts google.com: "
if getent hosts google.com >/dev/null 2>&1; then
    echo "SUCCESS"
else
    echo "FAILED"
fi

echo -n "  nslookup google.com: "
if nslookup google.com >/dev/null 2>&1; then
    echo "SUCCESS"
else
    echo "FAILED"
fi
echo ""

echo "3. Checking systemd-resolved:"
systemctl status systemd-resolved --no-pager | head -5
echo ""

echo "4. Checking .hushlogin files:"
ls -la /root/.hushlogin 2>/dev/null || echo "  /root/.hushlogin: NOT FOUND"
ls -la /home/wsluser/.hushlogin 2>/dev/null || echo "  /home/wsluser/.hushlogin: NOT FOUND"
echo ""

echo "5. Checking MOTD configuration:"
echo "  /etc/update-motd.d:"
ls -la /etc/update-motd.d 2>/dev/null | head -5
echo "  /etc/default/motd-news:"
cat /etc/default/motd-news 2>/dev/null | grep ENABLED || echo "  File not found"
echo ""

echo "6. Checking WSL configuration:"
cat /etc/wsl.conf
echo ""

echo "7. Checking first-boot fixes:"
echo -n "  /usr/local/bin/wsl-init-fix.sh: "
if [ -f /usr/local/bin/wsl-init-fix.sh ]; then
    echo "EXISTS"
    ls -la /usr/local/bin/wsl-init-fix.sh
else
    echo "NOT FOUND"
fi

echo -n "  wsl-init-fix.service: "
if systemctl list-unit-files | grep -q wsl-init-fix.service; then
    echo "EXISTS"
    systemctl status wsl-init-fix.service --no-pager | head -3
else
    echo "NOT FOUND"
fi

echo -n "  /etc/profile.d/wsl-first-boot-fix.sh: "
if [ -f /etc/profile.d/wsl-first-boot-fix.sh ]; then
    echo "EXISTS"
else
    echo "NOT FOUND"
fi
echo ""

echo "8. Manually running first-boot fix:"
if [ -f /usr/local/bin/wsl-init-fix.sh ]; then
    echo "  Executing wsl-init-fix.sh..."
    bash /usr/local/bin/wsl-init-fix.sh
    echo "  Done. Retesting DNS..."
    echo -n "  DNS after fix: "
    if getent hosts google.com >/dev/null 2>&1; then
        echo "SUCCESS"
    else
        echo "FAILED"
    fi
else
    echo "  Script not found, cannot run manual fix"
fi
'@

# スクリプトをファイルに保存してコピー（改行文字の問題を回避）
$tempScriptFile = "$env:TEMP\wsl-test-script-$(Get-Random).sh"

try {
    Write-Host "Running tests on instance: $InstanceName" -ForegroundColor Yellow
    Write-Host ""
    
    # UTF8 without BOM でファイルに保存し、LF改行にする
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tempScriptFile, $testScript.Replace("`r`n", "`n"), $utf8NoBom)
    
    # ファイルをWSLにコピー
    $windowsPath = $tempScriptFile.Replace('\', '/')
    $wslWindowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(2)
    $wslScriptPath = "/tmp/test-script.sh"
    
    # ファイルをコピーして実行
    $copyCommand = "cp '$wslWindowsPath' $wslScriptPath && chmod +x $wslScriptPath"
    wsl -d $InstanceName -- bash -c $copyCommand
    
    # スクリプトを実行
    $result = wsl -d $InstanceName -- bash $wslScriptPath
    
    Write-Host $result
    
    # クリーンアップ
    wsl -d $InstanceName -- bash -c "rm -f $wslScriptPath"
    
} catch {
    Write-ColorOutput Red "Error running tests: $_"
} finally {
    # 一時ファイルを削除
    if (Test-Path $tempScriptFile) {
        Remove-Item $tempScriptFile -ErrorAction SilentlyContinue
    }
}