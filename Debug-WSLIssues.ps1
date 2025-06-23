# Debug-WSLIssues.ps1
# WSLインスタンスのDNS解決とMOTD問題を調査するための診断スクリプト

param(
    [Parameter(Mandatory=$false)]
    [string]$InstanceName = "Ubuntu-Minimal-debug"
)

$ErrorActionPreference = "Continue"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

function Test-WSLInstance {
    param([string]$DistroName)
    
    Write-ColorOutput Cyan "=== Debugging WSL Instance: $DistroName ==="
    Write-Host ""
    
    # WSLインスタンス内でデバッグコマンドを実行
    $debugScript = @'
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Kernel: $(uname -r)"
echo ""

echo "=== DNS Configuration Debug ==="
echo "--- /etc/resolv.conf ---"
if [ -f /etc/resolv.conf ]; then
    cat /etc/resolv.conf
    echo "resolv.conf symlink target: $(readlink -f /etc/resolv.conf)"
else
    echo "/etc/resolv.conf not found"
fi
echo ""

echo "--- /etc/wsl.conf ---"
if [ -f /etc/wsl.conf ]; then
    cat /etc/wsl.conf
else
    echo "/etc/wsl.conf not found"
fi
echo ""

echo "--- systemd-resolved status ---"
systemctl status systemd-resolved --no-pager || echo "systemd-resolved not available"
echo ""

echo "--- DNS Resolution Test ---"
echo "Testing with different methods:"

# getent test
echo -n "getent hosts google.com: "
if getent hosts google.com >/dev/null 2>&1; then
    echo "SUCCESS"
    getent hosts google.com | head -1
else
    echo "FAILED"
fi

# nslookup test
echo -n "nslookup google.com: "
if command -v nslookup >/dev/null && nslookup google.com >/dev/null 2>&1; then
    echo "SUCCESS"
else
    echo "FAILED"
fi

# host test
echo -n "host google.com: "
if command -v host >/dev/null && host google.com >/dev/null 2>&1; then
    echo "SUCCESS"
else
    echo "FAILED"
fi

# dig test
echo -n "dig google.com: "
if command -v dig >/dev/null && dig google.com >/dev/null 2>&1; then
    echo "SUCCESS"
else
    echo "FAILED or dig not available"
fi

echo ""
echo "--- systemd-resolved resolve status ---"
if command -v resolvectl >/dev/null; then
    resolvectl status || echo "resolvectl failed"
else
    echo "resolvectl not available"
fi
echo ""

echo "=== MOTD/Login Message Debug ==="
echo "--- Checking MOTD files ---"
echo "/etc/motd exists: $([ -f /etc/motd ] && echo YES || echo NO)"
echo "/etc/motd content:"
if [ -f /etc/motd ]; then
    cat /etc/motd | head -10
fi
echo ""

echo "/etc/motd.dynamic exists: $([ -f /etc/motd.dynamic ] && echo YES || echo NO)"
if [ -f /etc/motd.dynamic ]; then
    echo "/etc/motd.dynamic content:"
    cat /etc/motd.dynamic | head -10
fi
echo ""

echo "--- /etc/update-motd.d directory ---"
if [ -d /etc/update-motd.d ]; then
    echo "Files in /etc/update-motd.d:"
    ls -la /etc/update-motd.d/
    echo ""
    echo "Executable files:"
    find /etc/update-motd.d -type f -executable 2>/dev/null || echo "None"
else
    echo "/etc/update-motd.d does not exist"
fi
echo ""

echo "--- .hushlogin files ---"
echo "Root .hushlogin: $([ -f /root/.hushlogin ] && echo EXISTS || echo MISSING)"
echo "WSL user .hushlogin: $([ -f /home/wsluser/.hushlogin ] && echo EXISTS || echo MISSING)"
echo "Skel .hushlogin: $([ -f /etc/skel/.hushlogin ] && echo EXISTS || echo MISSING)"
echo ""

echo "--- PAM MOTD configuration ---"
echo "PAM login motd config:"
grep -n "pam_motd" /etc/pam.d/login 2>/dev/null || echo "No pam_motd in login"
echo "PAM sshd motd config:"
grep -n "pam_motd" /etc/pam.d/sshd 2>/dev/null || echo "No pam_motd in sshd"
echo ""

echo "--- MOTD news configuration ---"
echo "/etc/default/motd-news:"
if [ -f /etc/default/motd-news ]; then
    cat /etc/default/motd-news
else
    echo "File does not exist"
fi
echo ""

echo "--- systemd MOTD services ---"
echo "motd-news.service status:"
systemctl status motd-news.service --no-pager 2>/dev/null || echo "Service not found"
echo "motd-news.timer status:"
systemctl status motd-news.timer --no-pager 2>/dev/null || echo "Timer not found"
echo ""

echo "--- Landscape configuration ---"
echo "landscape-common package:"
dpkg -l landscape-common 2>/dev/null || echo "Not installed"
echo "landscape client config:"
if [ -f /etc/landscape/client.conf ]; then
    echo "File exists, content:"
    cat /etc/landscape/client.conf
else
    echo "File does not exist"
fi
echo ""

echo "--- Ubuntu advantage tools ---"
echo "ubuntu-advantage-tools package:"
dpkg -l ubuntu-advantage-tools 2>/dev/null || echo "Not installed"
echo ""

echo "--- Legal file ---"
echo "/etc/legal:"
if [ -f /etc/legal ]; then
    echo "File exists, content:"
    cat /etc/legal | head -5
else
    echo "File does not exist"
fi
echo ""

echo "=== Network Interface Info ==="
ip addr show || echo "ip command failed"
echo ""

echo "=== Package Information ==="
echo "DNS-related packages:"
dpkg -l | grep -E "(systemd-resolved|libnss-resolve|bind9)" || echo "No DNS packages found"
echo ""

echo "=== Environment Variables ==="
echo "User: $(whoami)"
echo "Home: $HOME"
echo "PWD: $PWD"
echo ""

echo "=== Debug Complete ==="
'@

    # デバッグスクリプトをBase64エンコード
    $encodedScript = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($debugScript))
    
    try {
        Write-Host "Running diagnostic commands in WSL instance..." -ForegroundColor Yellow
        
        # WSLでデバッグスクリプトを実行
        $result = wsl -d $DistroName -- bash -c "echo '$encodedScript' | base64 -d | bash"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host $result
        } else {
            Write-ColorOutput Red "Failed to run debug script in WSL instance"
            Write-Host "Exit code: $LASTEXITCODE"
        }
        
    } catch {
        Write-ColorOutput Red "Error running diagnostic: $_"
    }
}

# メイン処理
Write-ColorOutput Cyan @"

=====================================
 WSL DNS & MOTD Issues Diagnostic
=====================================

This script will investigate DNS resolution and 
login message issues in WSL instances.

"@

# 利用可能なWSLインスタンスをリスト
Write-Host "Available WSL instances:" -ForegroundColor Yellow
try {
    $wslList = wsl --list --quiet 2>$null | ForEach-Object { 
        $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
    } | Where-Object { $_ -ne '' }
    
    if ($wslList) {
        $wslList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    } else {
        Write-ColorOutput Red "No WSL instances found"
        exit 1
    }
} catch {
    Write-ColorOutput Red "Failed to list WSL instances: $_"
    exit 1
}

Write-Host ""

# 特定のインスタンスが指定されている場合はそれをテスト
if ($InstanceName -ne "Ubuntu-Minimal-debug") {
    if ($wslList -contains $InstanceName) {
        Test-WSLInstance -DistroName $InstanceName
    } else {
        Write-ColorOutput Red "Instance '$InstanceName' not found"
        Write-Host "Available instances: $($wslList -join ', ')"
        exit 1
    }
} else {
    # 最小構成のインスタンスを探してテスト
    $minimalInstances = $wslList | Where-Object { $_ -like "*Minimal*" }
    
    if ($minimalInstances) {
        Write-Host "Found minimal instances, testing the first one..." -ForegroundColor Green
        Test-WSLInstance -DistroName $minimalInstances[0]
    } else {
        Write-Host "No minimal instances found. Testing Ubuntu-22.04 if available..." -ForegroundColor Yellow
        if ($wslList -contains "Ubuntu-22.04") {
            Test-WSLInstance -DistroName "Ubuntu-22.04"
        } else {
            Write-ColorOutput Red "No suitable instance found for testing"
            Write-Host "Please specify an instance name with -InstanceName parameter"
            exit 1
        }
    }
}

Write-Host ""
Write-ColorOutput Green "Diagnostic complete. Please review the output above."
Write-Host ""
Write-Host "If you need to save this output to a file:" -ForegroundColor Yellow
Write-Host "  .\Debug-WSLIssues.ps1 -InstanceName YourInstanceName > debug-output.txt" -ForegroundColor Gray