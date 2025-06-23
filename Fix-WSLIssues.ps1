# Fix-WSLIssues.ps1
# 既存のWSLインスタンスのDNSとMOTD問題を修正するスクリプト

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
 WSL DNS & MOTD Issues Fix Script
=====================================

This script will fix DNS resolution and 
login message issues in existing WSL instances.

"@

# 修正スクリプト
$fixScript = @'
#!/bin/bash
set -e

echo "=== Fixing WSL Issues ==="
echo ""

# 1. DNS解決の修正
echo "[1/2] Fixing DNS resolution..."

# systemd-resolved が有効であることを確認
systemctl unmask systemd-resolved 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true
systemctl start systemd-resolved 2>/dev/null || true

# resolv.conf を適切に設定
echo "Setting up resolv.conf..."
rm -f /etc/resolv.conf

# systemd-resolved のstub resolverを使用
if [ -f /run/systemd/resolve/stub-resolv.conf ]; then
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    echo "✓ Linked to systemd-resolved stub resolver"
else
    # フォールバック: 手動でresolv.confを作成
    cat > /etc/resolv.conf << 'EOF'
nameserver 127.0.0.53
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    echo "✓ Created fallback resolv.conf"
fi

# systemd-resolved の設定を更新
mkdir -p /etc/systemd/resolved.conf.d/
cat > /etc/systemd/resolved.conf.d/dns.conf << 'EOF'
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1
FallbackDNS=208.67.222.222 208.67.220.220
DNSSEC=no
Cache=yes
EOF

# NSS設定を修正
if [ -f /etc/nsswitch.conf ]; then
    # hostsラインを修正
    sed -i 's/^hosts:.*/hosts: files resolve [!UNAVAIL=return] dns myhostname/' /etc/nsswitch.conf
else
    # nsswitch.confを作成
    cat > /etc/nsswitch.conf << 'EOF'
passwd:         files
group:          files
shadow:         files
gshadow:        files

hosts:          files resolve [!UNAVAIL=return] dns myhostname
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF
fi

# systemd-resolved を再起動
systemctl restart systemd-resolved
sleep 2

# DNS解決テスト
echo "Testing DNS resolution..."
if getent hosts google.com >/dev/null 2>&1; then
    echo "✓ DNS resolution is now working!"
else
    echo "⚠ DNS resolution still has issues"
fi

# 2. MOTD/ログインメッセージの修正
echo ""
echo "[2/2] Fixing login messages..."

# .hushloginファイルを作成
echo "Creating .hushlogin files..."
touch /root/.hushlogin
chmod 644 /root/.hushlogin

if [ -d /home/wsluser ]; then
    touch /home/wsluser/.hushlogin
    chown wsluser:wsluser /home/wsluser/.hushlogin
    chmod 644 /home/wsluser/.hushlogin
fi

mkdir -p /etc/skel
touch /etc/skel/.hushlogin
chmod 644 /etc/skel/.hushlogin

# update-motd.d の実行権限を削除
echo "Disabling MOTD scripts..."
if [ -d /etc/update-motd.d ]; then
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
fi

# motd-news を無効化
echo "Disabling motd-news..."
if [ -f /etc/default/motd-news ]; then
    sed -i 's/ENABLED=1/ENABLED=0/' /etc/default/motd-news
else
    cat > /etc/default/motd-news << 'EOF'
ENABLED=0
EOF
fi

# landscape-common を削除
echo "Removing landscape-common..."
apt-get remove -y --purge landscape-common landscape-client 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

# PAM設定でmotdを無効化
echo "Disabling PAM motd..."
sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/login 2>/dev/null || true
sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/sshd 2>/dev/null || true

# systemd motdサービスを無効化
systemctl disable motd-news.service 2>/dev/null || true
systemctl mask motd-news.service 2>/dev/null || true
systemctl disable motd-news.timer 2>/dev/null || true
systemctl mask motd-news.timer 2>/dev/null || true

# 空のmotdファイルを作成
echo "" > /etc/motd
echo "" > /etc/issue
echo "" > /etc/issue.net

# legal ファイルを空にする
if [ -f /etc/legal ]; then
    echo "" > /etc/legal
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Please exit and re-enter the WSL instance to see the changes."
echo "Test commands:"
echo "  - DNS: ping google.com"
echo "  - MOTD: Exit and re-login to check if messages are suppressed"
'@

# 修正スクリプトをBase64エンコード
$encodedScript = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fixScript))

try {
    Write-Host "Applying fixes to instance: $InstanceName" -ForegroundColor Yellow
    Write-Host ""
    
    # WSLで修正スクリプトを実行
    $result = wsl -d $InstanceName -- bash -c "echo '$encodedScript' | base64 -d | sudo bash"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $result
        Write-Host ""
        Write-ColorOutput Green "Fixes applied successfully!"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Exit the WSL instance: exit" -ForegroundColor Gray
        Write-Host "2. Re-enter the instance: wsl -d $InstanceName" -ForegroundColor Gray
        Write-Host "3. Test DNS: ping google.com" -ForegroundColor Gray
        Write-Host "4. Check if login messages are suppressed" -ForegroundColor Gray
    } else {
        Write-ColorOutput Red "Failed to apply fixes"
        Write-Host "Exit code: $LASTEXITCODE"
    }
    
} catch {
    Write-ColorOutput Red "Error applying fixes: $_"
    exit 1
}