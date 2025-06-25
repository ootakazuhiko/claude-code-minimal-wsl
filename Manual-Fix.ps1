# Manual-Fix.ps1
# 既存のWSLインスタンスのMOTD問題を手動で修正するスクリプト

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
 Manual WSL Instance Fix
=====================================

This script will fix MOTD and .hushlogin issues
in existing WSL instances.

"@

# 修正スクリプト
$fixScript = @'
#!/bin/bash

echo "=== Manual Fix for WSL Instance ==="
echo ""

echo "1. Creating .hushlogin files..."
# rootユーザー
touch /root/.hushlogin
chmod 644 /root/.hushlogin
echo "✓ Created /root/.hushlogin"

# wsluser（存在する場合）
if [ -d /home/wsluser ]; then
    touch /home/wsluser/.hushlogin
    chown wsluser:wsluser /home/wsluser/.hushlogin
    chmod 644 /home/wsluser/.hushlogin
    echo "✓ Created /home/wsluser/.hushlogin"
fi

# skel
mkdir -p /etc/skel
touch /etc/skel/.hushlogin
chmod 644 /etc/skel/.hushlogin
echo "✓ Created /etc/skel/.hushlogin"

echo ""
echo "2. Disabling MOTD scripts..."
# update-motd.d のスクリプトを無効化
if [ -d /etc/update-motd.d ]; then
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
    echo "✓ Disabled MOTD scripts"
fi

echo ""
echo "3. Disabling motd-news..."
# motd-news を無効化
if [ -f /etc/default/motd-news ]; then
    sed -i 's/ENABLED=1/ENABLED=0/' /etc/default/motd-news
    echo "✓ Disabled motd-news"
else
    echo "ENABLED=0" > /etc/default/motd-news
    echo "✓ Created motd-news config (disabled)"
fi

echo ""
echo "4. Removing landscape packages..."
# landscape-common を削除
apt-get remove -y --purge landscape-common landscape-client 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
echo "✓ Removed landscape packages"

echo ""
echo "5. Disabling PAM MOTD..."
# PAM設定でMOTD表示を無効化
sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/login 2>/dev/null || true
sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/sshd 2>/dev/null || true
echo "✓ Disabled PAM MOTD"

echo ""
echo "6. Masking systemd MOTD services..."
# systemd motdサービスを無効化
systemctl disable motd-news.service 2>/dev/null || true
systemctl mask motd-news.service 2>/dev/null || true
systemctl disable motd-news.timer 2>/dev/null || true
systemctl mask motd-news.timer 2>/dev/null || true
echo "✓ Masked MOTD services"

echo ""
echo "7. Clearing MOTD files..."
# 空のmotdファイルを作成
echo "" > /etc/motd
echo "" > /etc/issue
echo "" > /etc/issue.net
echo "✓ Cleared MOTD files"

echo ""
echo "8. Testing changes..."
echo "Checking .hushlogin files:"
ls -la /root/.hushlogin 2>/dev/null && echo "  ✓ /root/.hushlogin exists" || echo "  ✗ /root/.hushlogin missing"
[ -d /home/wsluser ] && ls -la /home/wsluser/.hushlogin 2>/dev/null && echo "  ✓ /home/wsluser/.hushlogin exists" || echo "  ✗ /home/wsluser/.hushlogin missing"

echo ""
echo "Checking MOTD configuration:"
grep "ENABLED=" /etc/default/motd-news 2>/dev/null || echo "  motd-news config not found"

echo ""
echo "Checking executable MOTD scripts:"
find /etc/update-motd.d -type f -executable 2>/dev/null | wc -l | xargs echo "  Executable MOTD scripts:"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Please exit and re-enter the WSL instance to test:"
echo "  1. Exit WSL: exit"
echo "  2. Re-enter: wsl -d $INSTANCE_NAME"
echo "  3. Check if login messages are suppressed"
'@

$tempScriptFile = "$env:TEMP\manual-fix-$(Get-Random).sh"

try {
    Write-Host "Running manual fix on instance: $InstanceName" -ForegroundColor Yellow
    Write-Host ""
    
    # UTF8 without BOM でファイルに保存し、LF改行にする
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tempScriptFile, $fixScript.Replace("`r`n", "`n"), $utf8NoBom)
    
    # ファイルをWSLにコピー
    $windowsPath = $tempScriptFile.Replace('\', '/')
    $wslWindowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(2)
    $wslScriptPath = "/tmp/manual-fix.sh"
    
    # ファイルをコピーして実行
    $copyCommand = "cp '$wslWindowsPath' $wslScriptPath && chmod +x $wslScriptPath"
    wsl -d $InstanceName -- bash -c $copyCommand
    
    # スクリプトを実行
    $result = wsl -d $InstanceName -- sudo bash $wslScriptPath
    
    Write-Host $result
    
    # クリーンアップ
    wsl -d $InstanceName -- bash -c "rm -f $wslScriptPath"
    
    Write-Host ""
    Write-ColorOutput Green "Manual fix completed!"
    Write-Host ""
    Write-Host "To test the fix:" -ForegroundColor Yellow
    Write-Host "1. Exit WSL instance: exit" -ForegroundColor Gray
    Write-Host "2. Re-enter: wsl -d $InstanceName" -ForegroundColor Gray
    Write-Host "3. Check if login messages are suppressed" -ForegroundColor Gray
    
} catch {
    Write-ColorOutput Red "Error running manual fix: $_"
} finally {
    # 一時ファイルを削除
    if (Test-Path $tempScriptFile) {
        Remove-Item $tempScriptFile -ErrorAction SilentlyContinue
    }
}