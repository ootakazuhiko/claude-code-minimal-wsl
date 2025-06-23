# Create-MinimalUbuntuWSL.ps1
# 最小構成のUbuntu WSLイメージを作成・管理するスタンドアロンスクリプト

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("CreateBase", "NewInstance", "ListImages", "Info")]
    [string]$Action = "Info",
    
    [Parameter(Mandatory=$false)]
    [string]$InstanceName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$BaseImagePath = "$env:USERPROFILE\WSL-MinimalImages\ubuntu-22.04-minimal.tar",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepTempInstance = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludePodman = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeGitHubCLI = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeClaudeCode = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDevTools = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DebugMode = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = ""
)

$ErrorActionPreference = "Stop"

# カラー出力
function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

# ログ出力関数
function Write-LogOutput($Text, $Level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Text"
    
    if ($DebugMode) {
        Write-Host $logEntry -ForegroundColor Gray
    }
    
    if (-not [string]::IsNullOrEmpty($LogFile)) {
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }
}

# ヘッダー表示
function Show-Header {
    Write-ColorOutput Cyan @"

======================================
 Minimal Ubuntu WSL Image Creator
======================================

Create ultra-lightweight Ubuntu images for WSL2
- Standard Ubuntu: ~1.5GB → Minimal: ~500MB
- Removed: snap, cloud-init, docs, unnecessary services
- Optimized for containers and development

"@
}

# Information display / 情報表示
function Show-Info {
    Show-Header
    
    Write-ColorOutput Yellow "Available Actions:"
    Write-Host ""
    Write-Host "  CreateBase    - Create a new minimal Ubuntu base image"
    Write-Host "  NewInstance   - Create a new WSL instance from minimal image"
    Write-Host "  ListImages    - List available minimal images"
    Write-Host "  Info          - Show this information"
    Write-Host ""
    Write-ColorOutput Yellow "Examples:"
    Write-Host ""
    Write-Host "  # Create minimal base image"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase"
    Write-Host ""
    Write-Host "  # Create minimal base image with Podman"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludePodman"
    Write-Host ""
    Write-Host "  # Create minimal base image with GitHub CLI"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludeGitHubCLI"
    Write-Host ""
    Write-Host "  # Create minimal base image with multiple tools"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludePodman -IncludeGitHubCLI"
    Write-Host ""
    Write-Host "  # Create minimal base image with all dev tools"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludeDevTools"
    Write-Host ""
    Write-Host "  # Create new instance from minimal image"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action NewInstance -InstanceName myproject"
    Write-Host ""
    Write-Host "  # Use custom image path"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -BaseImagePath C:\MyImages\minimal.tar"
    Write-Host ""
    Write-ColorOutput Yellow "Options:"
    Write-Host ""
    Write-Host "  -IncludePodman     Include Podman container runtime"
    Write-Host "  -IncludeGitHubCLI  Include GitHub CLI (gh)"
    Write-Host "  -IncludeClaudeCode Include Claude Code + Project Identifier"
    Write-Host "  -IncludeDevTools   Include all development tools (Podman + gh + Claude Code)"
    Write-Host "  -DebugMode         Enable debug output during script execution"
    Write-Host "  -LogFile           Save debug output to specified file"
    Write-Host ""
    Write-ColorOutput Yellow "Diagnostic Tools:"
    Write-Host ""
    Write-Host "  Debug-WSLIssues.ps1 - Investigate DNS and MOTD issues in WSL instances"
    Write-Host ""
    
    Write-Host "===================================================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-ColorOutput Yellow "利用可能なアクション:"
    Write-Host ""
    Write-Host "  CreateBase    - 新しい最小Ubuntu基本イメージを作成"
    Write-Host "  NewInstance   - 最小イメージから新しいWSLインスタンスを作成"
    Write-Host "  ListImages    - 利用可能な最小イメージを表示"
    Write-Host "  Info          - この情報を表示"
    Write-Host ""
    Write-ColorOutput Yellow "例:"
    Write-Host ""
    Write-Host "  # 最小基本イメージを作成"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase"
    Write-Host ""
    Write-Host "  # Podman付きの最小基本イメージを作成"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludePodman"
    Write-Host ""
    Write-Host "  # GitHub CLI付きの最小基本イメージを作成"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludeGitHubCLI"
    Write-Host ""
    Write-Host "  # 複数のツール付きの最小基本イメージを作成"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludePodman -IncludeGitHubCLI"
    Write-Host ""
    Write-Host "  # 全開発ツール付きの最小基本イメージを作成"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -IncludeDevTools"
    Write-Host ""
    Write-Host "  # 最小イメージから新しいインスタンスを作成"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action NewInstance -InstanceName myproject"
    Write-Host ""
    Write-Host "  # カスタムイメージパスを使用"
    Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase -BaseImagePath C:\MyImages\minimal.tar"
    Write-Host ""
    Write-ColorOutput Yellow "オプション:"
    Write-Host ""
    Write-Host "  -IncludePodman     Podmanコンテナランタイムを含める"
    Write-Host "  -IncludeGitHubCLI  GitHub CLI (gh)を含める"
    Write-Host "  -IncludeClaudeCode Claude Code + Project Identifierを含める"
    Write-Host "  -IncludeDevTools   全開発ツール（Podman + gh + Claude Code）を含める"
    Write-Host ""
}

# 最小化スクリプト作成
function Get-MinimalSetupScript {
    param(
        [bool]$WithPodman,
        [bool]$WithGitHubCLI,
        [bool]$WithClaudeCode
    )
    
    $script = @'
#!/bin/bash
# Minimal Ubuntu Setup Script
# Don't exit on errors - we'll handle them individually
# set -e  # Commented out to prevent early exit

echo "================================================="
echo " Starting Ubuntu Minimization"
echo "================================================="
echo ""

# デバッグ用のエラーハンドラ
error_handler() {
    local exit_code=$?
    local line_no=${1:-$LINENO}
    echo "Warning: Command failed at line $line_no with exit code $exit_code"
    # Continue execution
}

# 環境変数設定
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# 1. 基本アップデート
echo "[1/8] System update..."
apt-get update 2>&1 | tail -n 20 || error_handler
apt-get upgrade -y 2>&1 | tail -n 20 || error_handler

# 2. 必要最小限のパッケージをインストール
echo "[2/8] Installing essential packages..."
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    sudo \
    locales \
    tzdata \
    systemd \
    systemd-sysv \
    dbus \
    vim-tiny 2>&1 | tail -n 20 || error_handler

# ロケール設定
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# 3. 不要なパッケージを削除
echo "[3/8] Removing unnecessary packages..."
REMOVE_PACKAGES=(
    # Snap関連
    snapd
    
    # Cloud関連
    cloud-init
    cloud-guest-utils
    cloud-initramfs-copymods
    cloud-initramfs-dyn-netconf
    
    # 自動更新
    unattended-upgrades
    update-manager-core
    ubuntu-release-upgrader-core
    update-notifier-common
    
    # 不要なシステムサービス
    accountsservice
    bolt
    modemmanager
    network-manager
    networkd-dispatcher
    packagekit
    policykit-1
    udisks2
    upower
    whoopsie
    apport
    popularity-contest
    
    # Plymouth
    plymouth
    plymouth-theme-ubuntu-text
    
    # その他の不要なもの
    landscape-common
    ubuntu-advantage-tools
    xdg-user-dirs
    friendly-recovery
    bcache-tools
    btrfs-progs
    xfsprogs
    mdadm
    open-iscsi
    lxd-agent-loader
    
    # ドキュメント関連
    man-db
    manpages
    manpages-dev
    info
    install-info
    
    # 開発ツール（最小構成では不要）
    build-essential
    python3-pip
    
    # その他
    nano
    ed
    lshw
    hdparm
    eject
    ftp
    telnet
    ntfs-3g
    mlocate
)

for package in "${REMOVE_PACKAGES[@]}"; do
    apt-get remove -y --purge $package 2>/dev/null || true
done

# 重要なパッケージが誤って削除されていないか確認・再インストール
echo "Ensuring essential packages are installed..."
ESSENTIAL_PACKAGES=(
    dpkg
    apt
    base-files
    base-passwd
    bash
    coreutils
    grep
    gzip
    hostname
    init-system-helpers
    libc6
    login
    mount
    passwd
    perl-base
    sed
    sysvinit-utils
    tar
    util-linux
    # DNS解決に必要なパッケージ
    systemd-resolved
    libnss-resolve
    bind9-dnsutils
    bind9-host
)

for package in "${ESSENTIAL_PACKAGES[@]}"; do
    if ! dpkg -l "$package" >/dev/null 2>&1; then
        echo "Reinstalling essential package: $package"
        apt-get install -y --no-install-recommends "$package" || {
            echo "Warning: Failed to install $package"
        }
    fi
done

# 4. 依存関係のクリーンアップ
echo "[4/8] Cleaning up dependencies..."
apt-get autoremove -y --purge >/dev/null 2>&1

# 5. ドキュメントとキャッシュの削除
echo "[5/8] Removing documentation and caches..."

# ドキュメント削除
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*
rm -rf /usr/share/info/*
rm -rf /usr/share/lintian/*

# 不要なロケール削除
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} +

# キャッシュクリア
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*
rm -rf /var/cache/debconf/*
rm -rf /tmp/*
rm -rf /var/tmp/*

# ログクリア
find /var/log -type f -exec truncate -s 0 {} \;

# 6. システム設定の最適化
echo "[6/8] Optimizing system configuration..."

# WSL設定 - resolv.conf の自動生成を完全に無効化
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true
command="/usr/local/bin/wsl-init-fix.sh"

[network]
generateHosts=true
generateResolvConf=false

[automount]
enabled=true
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=true
EOF

# wsl.conf が確実に読み込まれるようにする

# DNS設定 - WSLが自動生成するresolv.confにフォールバック設定を追加
cat > /etc/resolv.conf << 'EOF'
# This file will be overwritten by WSL, but provides fallback DNS
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

# resolv.confの書き込み保護を解除（WSLが更新できるように）
chattr -i /etc/resolv.conf 2>/dev/null || true

# 不要なサービスの無効化
# systemd-resolved は DNS解決に必要なので無効化しない
DISABLE_SERVICES=(
    accounts-daemon
    cron
    rsyslog
    ssh
    multipathd
    networkd-dispatcher
    unattended-upgrades
)

for service in "${DISABLE_SERVICES[@]}"; do
    systemctl disable $service 2>/dev/null || true
    systemctl mask $service 2>/dev/null || true
done

# systemd-resolved が有効であることを確認
systemctl unmask systemd-resolved 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true

# journald設定（ログサイズ制限）
mkdir -p /etc/systemd/journald.conf.d/
cat > /etc/systemd/journald.conf.d/00-wsl.conf << 'EOF'
[Journal]
SystemMaxUse=50M
RuntimeMaxUse=10M
ForwardToSyslog=no
EOF

# apt設定（推奨パッケージ無効化）
cat > /etc/apt/apt.conf.d/99-no-recommends << 'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
EOF

# 不要なcronジョブ削除
rm -f /etc/cron.daily/*
rm -f /etc/cron.weekly/*
rm -f /etc/cron.monthly/*

# MOTD完全無効化 - より包括的なアプローチ
echo "Completely disabling MOTD and login messages..."

# update-motd.d を削除し、その場所にダミーファイルを作成して再作成を防ぐ
rm -rf /etc/update-motd.d
touch /etc/update-motd.d
chmod 000 /etc/update-motd.d

# MOTDファイルを削除し空にする
rm -f /etc/motd
rm -f /etc/motd.dynamic
rm -f /run/motd.dynamic
touch /etc/motd
chmod 444 /etc/motd

# Ubuntu Pro と landscape 関連の完全削除
echo "Removing Ubuntu Pro and landscape messages..."
# ESMメッセージファイル削除
rm -f /etc/apt/apt.conf.d/20apt-esm
rm -f /etc/apt/apt.conf.d/99esm

# landscape関連ファイル削除
rm -rf /etc/landscape
rm -rf /var/lib/landscape

# Ubuntu advantage tools 無効化
if [ -f /etc/ubuntu-advantage/uaclient.conf ]; then
    rm -f /etc/ubuntu-advantage/uaclient.conf
fi

# systemd の motd 関連サービス完全無効化
echo "Disabling systemd MOTD services..."
systemctl disable motd-news.service 2>/dev/null || true
systemctl mask motd-news.service 2>/dev/null || true
systemctl disable motd-news.timer 2>/dev/null || true
systemctl mask motd-news.timer 2>/dev/null || true

# apport (エラーレポート) も無効化
systemctl disable apport.service 2>/dev/null || true
systemctl mask apport.service 2>/dev/null || true

# Ubuntu telemetry 無効化
if [ -f /etc/default/ubuntu-esm ]; then
    rm -f /etc/default/ubuntu-esm
fi

# 7. WSL起動時の問題を修正するための設定
echo "[7/8] Setting up WSL startup fixes..."

# より単純なアプローチ: bashrcに直接追加
cat >> /etc/bash.bashrc << 'BASHRCFIX'

# WSL DNS Fix
if [ -L /etc/resolv.conf ] && [ "$(readlink /etc/resolv.conf)" = "/mnt/wsl/resolv.conf" ]; then
    if [ "$EUID" -eq 0 ]; then
        rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    fi
fi
BASHRCFIX

# root用の.bashrcにも追加
cat >> /root/.bashrc << 'ROOTBASHRC'

# WSL DNS Fix for root
if [ -L /etc/resolv.conf ] && [ "$(readlink /etc/resolv.conf)" = "/mnt/wsl/resolv.conf" ]; then
    rm -f /etc/resolv.conf
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fi
ROOTBASHRC

# resolv.confを事前に正しく設定
rm -f /etc/resolv.conf
cat > /etc/resolv.conf << 'DNSEOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
DNSEOF

# resolv.confの自動生成を防ぐためのダミーファイル作成
mkdir -p /run/resolvconf
touch /run/resolvconf/resolv.conf
ln -sf /etc/resolv.conf /run/resolvconf/resolv.conf

# 8. ユーザー設定
echo "[8/8] Setting up user..."
useradd -m -s /bin/bash -G sudo wsluser 2>/dev/null || true
echo "wsluser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ログインメッセージを完全に無効化 - 包括的アプローチ
echo "Setting up complete login message suppression..."

# すべてのユーザーに対して .hushlogin を設定
echo "Creating .hushlogin files..."

# rootユーザー
touch /root/.hushlogin
chmod 644 /root/.hushlogin

# wsluser
touch /home/wsluser/.hushlogin
chown wsluser:wsluser /home/wsluser/.hushlogin
chmod 644 /home/wsluser/.hushlogin

# デフォルトユーザー（WSLが作成する可能性のあるユーザー）
mkdir -p /etc/skel
touch /etc/skel/.hushlogin
chmod 644 /etc/skel/.hushlogin

# Ubuntu特有のメッセージファイルを無効化
echo "Removing Ubuntu-specific message files..."
if [ -f /etc/legal ]; then
    echo "" > /etc/legal
fi

# landscape-common の完全削除（メッセージの主要原因）
apt-get remove -y --purge landscape-common landscape-client 2>/dev/null || true

# PAM設定でMOTD表示を完全に無効化
echo "Disabling PAM MOTD modules..."
# pam_motd を完全にコメントアウト
sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/login 2>/dev/null || true
sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/sshd 2>/dev/null || true

# Ubuntu 固有のログインメッセージ設定を無効化
echo "Disabling Ubuntu login message configurations..."

# motd-news 設定を無効化
mkdir -p /etc/default
cat > /etc/default/motd-news << 'EOF'
ENABLED=0
EOF

# cloudflare DOH も無効化
if [ -f /etc/systemd/resolved.conf ]; then
    sed -i 's/^#*DNS=.*/DNS=8.8.8.8/' /etc/systemd/resolved.conf
fi

# Pro messages を生成するプロセスを無効化
if [ -f /usr/bin/ubuntu-advantage ]; then
    chmod -x /usr/bin/ubuntu-advantage 2>/dev/null || true
fi

# HWE update notifier 無効化
if [ -f /usr/bin/update-notifier ]; then
    chmod -x /usr/bin/update-notifier 2>/dev/null || true
fi

# landscape-sysinfo 無効化
if [ -f /usr/bin/landscape-sysinfo ]; then
    chmod -x /usr/bin/landscape-sysinfo 2>/dev/null || true
fi

# /etc/issue と /etc/issue.net を空にする
echo "" > /etc/issue
echo "" > /etc/issue.net

# Ubuntu Pro 広告を完全に無効化
mkdir -p /etc/ubuntu-advantage
cat > /etc/ubuntu-advantage/uaclient.conf << 'EOF'
contract_url: https://contracts.canonical.com
security_url: https://ubuntu.com/security
data_dir: /var/lib/ubuntu-advantage
log_level: error
log_file: /dev/null
EOF

echo "Login message suppression setup completed."

'@

    # オプショナルツールのカウンター
    $stepNum = 8
    
    # GitHub CLI インストール
    if ($WithGitHubCLI) {
        $script += @"

# $stepNum. GitHub CLI インストール
echo "[$stepNum/X] Installing GitHub CLI..."

# GitHub CLI GPGキー追加
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1

# リポジトリ追加
echo "deb [arch=`$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

# インストール
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends gh >/dev/null 2>&1

# クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

"@
        $stepNum++
    }
    
    # Claude Code インストール
    if ($WithClaudeCode) {
        # 修正: here-stringのエスケープ問題を解決
        $bashrcContent = @'
# Claude Code settings
export CLAUDE_CODE_HOME=/opt/claude-code
export PATH=$PATH:$CLAUDE_CODE_HOME:$HOME/.local/bin

# Claude Code completion (if available)
if command -v claude-code &> /dev/null; then
    eval "$(claude-code --completion-script bash 2>/dev/null || true)"
fi

# Claude Code aliases
alias claude="claude-code"
alias cc="claude-code"

# Claude Project Identifier integration
if [ -f "$HOME/.claude-project-identifier/init.sh" ]; then
    source "$HOME/.claude-project-identifier/init.sh"
fi

# Auto-display project info when entering directories
cd() {
    builtin cd "$@"
    if [ -f ".claude-project" ]; then
        if command -v claude-project-init &> /dev/null; then
            claude-project-init
        fi
    fi
}
'@

        $configContent = @'
# Claude Code Configuration
# See: https://docs.anthropic.com/ja/docs/claude-code/getting-started

# API設定（キーは後で設定）
api:
  # key: "your-api-key-here"
  # endpoint: "https://api.anthropic.com"

# デフォルト設定
defaults:
  model: "claude-3-opus-20240229"
  max_tokens: 4096
  temperature: 0.7

# エディタ統合
editor:
  command: "vim"
  
# プロジェクト設定
project:
  ignore_patterns:
    - "*.pyc"
    - "__pycache__"
    - ".git"
    - "node_modules"
'@

        $setupHelperContent = @'
#!/bin/bash
# Claude Code セットアップヘルパー

echo "======================================"
echo " Claude Code Setup Helper"
echo "======================================"
echo ""
echo "Claude Code has been installed."
echo ""
echo "To complete setup:"
echo ""
echo "1. Get your API key from: https://console.anthropic.com/"
echo ""
echo "2. Set your API key using one of these methods:"
echo "   a) Environment variable:"
echo "      export ANTHROPIC_API_KEY='your-api-key'"
echo "      echo 'export ANTHROPIC_API_KEY=\"your-api-key\"' >> ~/.bashrc"
echo ""
echo "   b) Claude Code config:"
echo "      claude-code auth login"
echo ""
echo "   c) Config file:"
echo "      Edit ~/.config/claude-code/config.yaml"
echo ""
echo "3. Verify installation:"
echo "   claude-code --version"
echo "   claude-code --help"
echo ""
echo "4. Quick test:"
echo "   echo 'Hello, Claude!' | claude-code"
echo ""
echo "5. Claude Project Identifier setup:"
echo "   # Create a new project"
echo "   mkdir my-project && cd my-project"
echo "   claude-project-init"
echo ""
echo "   # This will create .claude-project and CLAUDE.md files"
echo "   # and show project info in terminal title"
echo ""
echo "For more information:"
echo "https://docs.anthropic.com/ja/docs/claude-code/getting-started"
echo "https://github.com/ootakazuhiko/claude-project-identifier"
echo ""
'@

        $script += @"

# $stepNum. Claude Code インストール
echo "[$stepNum/X] Installing Claude Code..."

# Claude Code の前提条件
apt-get install -y --no-install-recommends python3 python3-venv python3-pip >/dev/null 2>&1

# Claude Code インストール用ディレクトリ
mkdir -p /opt/claude-code
chown -R wsluser:wsluser /opt/claude-code

# Claude Code インストール
echo "Installing Claude Code CLI..."

# pipを使用してインストール（一般的なPythonパッケージの場合）
su - wsluser -c "pip3 install --user claude-code" || {
    echo "Note: Please refer to https://docs.anthropic.com/ja/docs/claude-code/getting-started"
    echo "for the official installation instructions."
}

# Claude Project Identifier インストール
echo "Installing Claude Project Identifier..."
su - wsluser -c "curl -fsSL https://raw.githubusercontent.com/ootakazuhiko/claude-project-identifier/main/install.sh | bash" || {
    echo "Claude Project Identifier installation failed, trying alternative method..."
    
    # Manual installation fallback
    mkdir -p /home/wsluser/.claude-project-identifier
    cd /home/wsluser/.claude-project-identifier
    
    # Download core files
    curl -fsSL -o init.sh https://raw.githubusercontent.com/ootakazuhiko/claude-project-identifier/main/init-project.sh 2>/dev/null || {
        echo "Failed to download Claude Project Identifier files"
    }
    
    # Make executable
    chmod +x init.sh 2>/dev/null || true
    
    # Create command symlink
    mkdir -p /home/wsluser/.local/bin
    ln -sf /home/wsluser/.claude-project-identifier/init.sh /home/wsluser/.local/bin/claude-project-init 2>/dev/null || true
    
    chown -R wsluser:wsluser /home/wsluser/.claude-project-identifier
    chown -R wsluser:wsluser /home/wsluser/.local/bin
    
    echo "Claude Project Identifier installed manually"
}

# 環境変数とパスの設定（修正版）
cat >> /home/wsluser/.bashrc << 'BASHRC_EOF'
$bashrcContent
BASHRC_EOF

# 設定ファイルディレクトリの作成
mkdir -p /home/wsluser/.config/claude-code
chown -R wsluser:wsluser /home/wsluser/.config/claude-code

# 初期設定ファイル
cat > /home/wsluser/.config/claude-code/config.yaml << 'CONFIG_EOF'
$configContent
CONFIG_EOF

chown wsluser:wsluser /home/wsluser/.config/claude-code/config.yaml

# APIキー設定の案内
cat > /opt/claude-code/setup-claude-code.sh << 'SETUP_EOF'
$setupHelperContent
SETUP_EOF

chmod +x /opt/claude-code/setup-claude-code.sh
chown wsluser:wsluser /opt/claude-code/setup-claude-code.sh

# クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Claude Code installation completed."
echo "Run '/opt/claude-code/setup-claude-code.sh' for setup instructions."

"@
        $stepNum++
    }

    # Podman インストール
    if ($WithPodman) {
        $script += @"

# $stepNum. Podman インストール
echo "[$stepNum/X] Installing Podman..."

# Podman前提パッケージ
apt-get install -y --no-install-recommends \
    uidmap \
    slirp4netns \
    fuse-overlayfs \
    libslirp0 >/dev/null 2>&1

# Podmanリポジトリ追加
. /etc/os-release
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_\${VERSION_ID}/ /" > /etc/apt/sources.list.d/podman.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_\${VERSION_ID}/Release.key" | apt-key add - >/dev/null 2>&1

# Podmanインストール
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends podman >/dev/null 2>&1

# Rootless設定
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 wsluser 2>/dev/null || true

# 再度クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

"@
        $stepNum++
    }

    $script += @'

# 最終クリーンアップ
echo ""
echo "Cleaning up final bits..."
apt-get clean
rm -rf /tmp/*

# サイズ確認（エラーハンドリング付き）
echo ""
echo "================================================="
echo " Minimization Complete!"
echo "================================================="
echo ""
echo "Disk usage:"
if command -v df >/dev/null 2>&1; then
    df -h / 2>/dev/null | grep -E "^/|Filesystem" || echo "Disk usage information unavailable"
else
    echo "df command not available"
fi
echo ""

# dpkgの存在確認と最終的なパッケージ数カウント
if command -v dpkg >/dev/null 2>&1; then
    PACKAGE_COUNT=$(dpkg -l 2>/dev/null | grep '^ii' | wc -l 2>/dev/null || echo "unknown")
    echo "Package count: $PACKAGE_COUNT packages"
    
    # 重要なパッケージの存在確認
    echo "Essential packages status:"
    for pkg in dpkg apt bash coreutils; do
        if dpkg -l "$pkg" >/dev/null 2>&1; then
            echo "  ✓ $pkg"
        else
            echo "  ✗ $pkg (missing)"
        fi
    done
else
    echo "Error: dpkg command not available - attempting to reinstall..."
    apt-get update >/dev/null 2>&1
    apt-get install -y --no-install-recommends dpkg >/dev/null 2>&1
    
    if command -v dpkg >/dev/null 2>&1; then
        PACKAGE_COUNT=$(dpkg -l 2>/dev/null | grep '^ii' | wc -l 2>/dev/null || echo "unknown")
        echo "Package count: $PACKAGE_COUNT packages (after dpkg reinstall)"
    else
        echo "Critical error: Could not restore dpkg functionality"
    fi
fi
# DNS解決の詳細設定と検証
echo "Configuring and testing DNS resolution..."

# systemd-resolved を確実に有効化
echo "Enabling systemd-resolved..."
systemctl unmask systemd-resolved 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true
systemctl start systemd-resolved 2>/dev/null || true

# NSS設定の確認と修正
echo "Configuring NSS for DNS resolution..."
if [ -f /etc/nsswitch.conf ]; then
    # DNS解決にsystemd-resolvedを使用するよう設定
    if ! grep -q "resolve" /etc/nsswitch.conf; then
        sed -i 's/^hosts:.*/hosts: files resolve [!UNAVAIL=return] dns myhostname/' /etc/nsswitch.conf
        echo "Updated NSS configuration to use systemd-resolved"
    fi
else
    echo "Creating nsswitch.conf for DNS resolution..."
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

# systemd-resolved の stub resolver を有効化
echo "Configuring systemd-resolved stub resolver..."
mkdir -p /etc/systemd/resolved.conf.d/
cat > /etc/systemd/resolved.conf.d/wsl.conf << 'EOF'
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
FallbackDNS=208.67.222.222 208.67.220.220
DNSSEC=no
DNSOverTLS=no
Cache=yes
EOF

# resolv.conf のシンボリックリンクを正しく設定
echo "Setting up resolv.conf symlink..."
rm -f /etc/resolv.conf

# systemd-resolved を先に再起動して stub-resolv.conf が生成されるのを待つ
systemctl restart systemd-resolved 2>/dev/null || true
sleep 3

# stub-resolv.conf が存在するか確認してリンク
if [ -f /run/systemd/resolve/stub-resolv.conf ]; then
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    echo "✓ Successfully linked resolv.conf to systemd-resolved"
else
    # フォールバック: 手動で作成
    echo "⚠ stub-resolv.conf not found, creating manual resolv.conf"
    cat > /etc/resolv.conf << 'RESOLVEOF'
nameserver 127.0.0.53
options edns0 trust-ad
search .
RESOLVEOF
fi

# resolv.conf が存在することを確認
if [ -f /etc/resolv.conf ]; then
    echo "✓ /etc/resolv.conf exists"
    cat /etc/resolv.conf
    
    # resolv.conf を保護はしない（systemd-resolved が管理する必要があるため）
else
    echo "✗ ERROR: /etc/resolv.conf still missing!"
fi

# DNS解決テスト
echo "Testing DNS resolution..."
dns_working=false

# systemd-resolved の状態確認
if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    echo "✓ systemd-resolved is active"
else
    echo "⚠ systemd-resolved is not active"
fi

# 複数の方法でDNS解決をテスト
echo "Running DNS resolution tests..."

# Test 1: getent (NSS経由)
echo -n "Testing getent hosts google.com: "
if getent hosts google.com >/dev/null 2>&1; then
    echo "SUCCESS"
    dns_working=true
else
    echo "FAILED"
fi

# Test 2: nslookup
echo -n "Testing nslookup google.com: "
if command -v nslookup >/dev/null 2>&1 && nslookup google.com >/dev/null 2>&1; then
    echo "SUCCESS"
    dns_working=true
else
    echo "FAILED"
fi

# Test 3: host
echo -n "Testing host google.com: "
if command -v host >/dev/null 2>&1 && host google.com >/dev/null 2>&1; then
    echo "SUCCESS"
    dns_working=true
else
    echo "FAILED"
fi

# Test 4: dig
echo -n "Testing dig google.com: "
if command -v dig >/dev/null 2>&1 && dig google.com >/dev/null 2>&1; then
    echo "SUCCESS"
    dns_working=true
else
    echo "FAILED or dig not available"
fi

# 結果表示
if [ "$dns_working" = true ]; then
    echo "✓ DNS resolution is working"
else
    echo "⚠ DNS resolution has issues - debugging info:"
    echo "--- resolv.conf ---"
    cat /etc/resolv.conf 2>/dev/null || echo "No resolv.conf"
    echo "--- nsswitch.conf hosts line ---"
    grep "^hosts:" /etc/nsswitch.conf 2>/dev/null || echo "No hosts line"
    echo "--- systemd-resolved status ---"
    systemctl status systemd-resolved --no-pager 2>&1 | head -5
    echo "--- resolvectl status ---"
    if command -v resolvectl >/dev/null; then
        resolvectl status 2>&1 | head -10
    fi
fi

echo ""
echo "=== Post-minimization validation ==="

# resolv.conf の最終確認と修正
echo "Validating DNS configuration..."
if [ ! -f /etc/resolv.conf ]; then
    echo "WARNING: /etc/resolv.conf is missing, recreating..."
    
    # systemd-resolved が動作していることを確認
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        if [ -f /run/systemd/resolve/stub-resolv.conf ]; then
            ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
            echo "✓ Recreated resolv.conf symlink"
        else
            # 手動で作成
            cat > /etc/resolv.conf << 'RESOLVEOF'
nameserver 127.0.0.53
options edns0 trust-ad
search .
RESOLVEOF
            echo "✓ Created manual resolv.conf"
        fi
    else
        # systemd-resolved が動作していない場合
        cat > /etc/resolv.conf << 'RESOLVEOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
RESOLVEOF
        echo "✓ Created fallback resolv.conf"
    fi
fi

# .hushlogin ファイルの最終確認
echo "Validating login message suppression..."
if [ ! -f /root/.hushlogin ]; then
    echo "WARNING: /root/.hushlogin missing, recreating..."
    touch /root/.hushlogin
    chmod 644 /root/.hushlogin
fi

if [ -d /home/wsluser ] && [ ! -f /home/wsluser/.hushlogin ]; then
    echo "WARNING: /home/wsluser/.hushlogin missing, recreating..."
    touch /home/wsluser/.hushlogin
    chown wsluser:wsluser /home/wsluser/.hushlogin
    chmod 644 /home/wsluser/.hushlogin
fi

if [ ! -f /etc/skel/.hushlogin ]; then
    echo "WARNING: /etc/skel/.hushlogin missing, recreating..."
    mkdir -p /etc/skel
    touch /etc/skel/.hushlogin
    chmod 644 /etc/skel/.hushlogin
fi

# MOTD が確実に無効化されていることを確認
if [ -d /etc/update-motd.d ]; then
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
    echo "✓ MOTD scripts disabled"
fi

# 最終的なDNSテスト
echo "Final DNS resolution test..."
if getent hosts google.com >/dev/null 2>&1; then
    echo "✓ DNS resolution confirmed working"
else
    echo "⚠ DNS resolution still has issues"
    echo "Current resolv.conf:"
    cat /etc/resolv.conf
fi

echo ""
echo "Minimization script completed successfully!"
'@

    return $script
}

# ベースイメージ作成
function New-MinimalBaseImage {
    Show-Header
    Write-ColorOutput Green "Creating Minimal Ubuntu Base Image"
    Write-Host ""
    
    # ログファイルの初期化
    if (-not [string]::IsNullOrEmpty($LogFile)) {
        $logDir = Split-Path $LogFile -Parent
        if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Force -Path $logDir | Out-Null
        }
        Write-LogOutput "Starting minimal base image creation" "INFO"
    }
    
    # イメージ保存ディレクトリ作成
    $imageDir = Split-Path $BaseImagePath -Parent
    if ([string]::IsNullOrEmpty($imageDir)) {
        Write-ColorOutput Red "Error: Invalid BaseImagePath specified"
        return
    }
    if (-not (Test-Path $imageDir)) {
        Write-Host "      Creating image directory: $imageDir" -ForegroundColor Gray
        New-Item -ItemType Directory -Force -Path $imageDir | Out-Null
    }
    
    # 既存イメージチェック
    if (Test-Path $BaseImagePath) {
        Write-ColorOutput Yellow "Base image already exists: $BaseImagePath"
        $overwrite = Read-Host "Overwrite? (y/N)"
        if ($overwrite -ne 'y') {
            Write-Host "Cancelled."
            return
        }
    }
    
    # 一時インスタンス名と変数初期化
    $tempDistro = "Ubuntu-Minimal-Temp-$(Get-Random -Maximum 9999)"
    $tempExport = "$env:TEMP\ubuntu-temp-base-$(Get-Random).tar"
    $tempInstanceDir = "$env:TEMP\wsl-minimal-temp-$(Get-Random)"
    
    try {
        # WSL状態確認
        Write-Host "[1/5] Checking WSL environment..." -ForegroundColor White
        
        # WSL有効性確認
        try {
            wsl --status | Out-Null
        } catch {
            Write-ColorOutput Red "Error: WSL is not available or not properly configured"
            Write-Host "Please ensure WSL2 is installed and enabled."
            return
        }
        
        # 既存のUbuntu-22.04確認と処理
        $existingDistros = wsl --list --quiet 2>$null | ForEach-Object { 
            # 不可視文字と空白を削除
            $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
        } | Where-Object { $_ -ne '' }
        
        $hasUbuntu2204 = $false
        foreach ($distro in $existingDistros) {
            if ($distro -eq "Ubuntu-22.04") {
                $hasUbuntu2204 = $true
                break
            }
        }
        
        if ($hasUbuntu2204) {
            Write-Host "      Ubuntu-22.04 already exists, using existing installation" -ForegroundColor Gray
        } else {
            # 利用可能なディストリビューション確認
            Write-Host "      Checking for Ubuntu-22.04..." -ForegroundColor Gray
            
            # 直接インストールを試行（言語に依存しない方法）
            Write-Host "      Attempting to install Ubuntu-22.04..." -ForegroundColor Gray
            
            try {
                # まず、既にインストールされているか再確認（異なるエンコーディングの可能性）
                $testInstall = & wsl.exe --list --quiet 2>$null | Out-String
                if ($testInstall -match "Ubuntu-22\.04") {
                    Write-Host "      Ubuntu-22.04 found on second check" -ForegroundColor Gray
                    # 既にインストールされているので、続行
                } else {
                    # wsl --install コマンドで直接インストール
                    $installProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--install", "-d", "Ubuntu-22.04", "--no-launch" -PassThru -NoNewWindow -Wait
                
                    if ($installProcess.ExitCode -eq 0) {
                        Write-Host "      Installation command executed successfully" -ForegroundColor Gray
                        
                        # インストール完了待機
                        $timeout = 180  # 3分
                        $elapsed = 0
                        $installSuccess = $false
                        
                        Write-Host "      Waiting for Ubuntu-22.04 to be registered..." -ForegroundColor Gray
                        
                        while ($elapsed -lt $timeout) {
                            Start-Sleep -Seconds 5
                            $elapsed += 5
                            
                            # インストール済みディストリビューションを確認
                            $currentDistros = wsl --list --quiet 2>$null | ForEach-Object { 
                                $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
                            } | Where-Object { $_ -ne '' }
                            
                            if ($currentDistros -contains "Ubuntu-22.04") {
                                Write-Host "      Ubuntu-22.04 installation confirmed!" -ForegroundColor Green
                                $installSuccess = $true
                                break
                            }
                            
                            if ($elapsed % 30 -eq 0) {
                                Write-Host "      Still waiting... ($elapsed/$timeout seconds)" -ForegroundColor Gray
                            }
                        }
                        
                        if (-not $installSuccess) {
                            # もう一度確認（念のため）
                            $currentDistros = wsl --list --quiet 2>$null | ForEach-Object { 
                                $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
                            } | Where-Object { $_ -ne '' }
                            
                            if ($currentDistros -contains "Ubuntu-22.04") {
                                $installSuccess = $true
                            } else {
                                throw "Ubuntu-22.04 was not found after installation timeout"
                            }
                        }
                    } else {
                        # インストールが失敗した場合、他のUbuntuバージョンを探す
                        Write-ColorOutput Yellow "Ubuntu-22.04 installation failed (exit code: $($installProcess.ExitCode))"
                        
                        # 利用可能な他のUbuntuバージョンを確認
                        Write-Host "      Checking for alternative Ubuntu versions..." -ForegroundColor Gray
                        
                        # Ubuntu (デフォルト版) を試す
                        $currentDistros = wsl --list --quiet 2>$null
                        if ($currentDistros -match "^Ubuntu$") {
                            Write-Host "      Found default Ubuntu installation" -ForegroundColor Gray
                            
                            # デフォルトUbuntuをベースとして使用することを提案
                            Write-ColorOutput Yellow "Ubuntu-22.04 is not available, but default Ubuntu is installed."
                            Write-Host "You can either:"
                            Write-Host "  1. Use default Ubuntu as base (may be a different version)"
                            Write-Host "  2. Manually install Ubuntu-22.04 from Microsoft Store"
                            Write-Host ""
                            
                            $useDefault = Read-Host "Use default Ubuntu as base? (y/N)"
                            if ($useDefault -eq 'y') {
                                # デフォルトUbuntuを使用するための調整
                                Write-Host "      Using default Ubuntu as base..." -ForegroundColor Gray
                                # この場合、後続の処理でUbuntu-22.04の代わりにUbuntuを使用
                                $global:UseDefaultUbuntu = $true
                            } else {
                                throw "Ubuntu-22.04 installation required"
                            }
                        } else {
                            throw "No suitable Ubuntu distribution found"
                        }
                    }
                }
            } catch {
                Write-ColorOutput Red "Error: Could not install or find Ubuntu-22.04"
                Write-Host "Error details: $_"
                Write-Host ""
                Write-Host "Please try one of the following:"
                Write-Host "  1. Install Ubuntu-22.04 manually from Microsoft Store"
                Write-Host "  2. Run: wsl --install -d Ubuntu-22.04"
                Write-Host "  3. Check your internet connection and try again"
                return
            }
        }
        
        # 最終確認（デフォルトUbuntuフォールバックを考慮）
        if (-not $global:UseDefaultUbuntu) {
            $finalCheck = wsl --list --quiet 2>$null | ForEach-Object { 
                $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
            } | Where-Object { $_ -ne '' }
            
            if ($finalCheck -notcontains "Ubuntu-22.04") {
                Write-ColorOutput Red "Error: Ubuntu-22.04 is not available"
                return
            }
        }
        
        # 一時インスタンスとして再インポート
        Write-Host "[2/5] Creating temporary instance..." -ForegroundColor White
        
        # 使用するベースディストリビューション名を決定
        $baseDistro = if ($global:UseDefaultUbuntu) { "Ubuntu" } else { "Ubuntu-22.04" }
        
        try {
            Write-Host "      Exporting $baseDistro as base..." -ForegroundColor Gray
            wsl --export $baseDistro $tempExport
            
            if (-not (Test-Path $tempExport)) {
                throw "Export file was not created: $tempExport"
            }
            
            Write-Host "      Creating temporary instance..." -ForegroundColor Gray
            wsl --import $tempDistro $tempInstanceDir $tempExport
            
            # インポート直後に少し待機
            Start-Sleep -Seconds 2
            
            # 一時インスタンスが作成されたか確認
            Write-Host "      Verifying temporary instance creation..." -ForegroundColor Gray
            $tempCheck = wsl --list --quiet 2>$null | ForEach-Object { 
                $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
            } | Where-Object { $_ -ne '' }
            
            Write-Host "      Current WSL instances:" -ForegroundColor DarkGray
            $tempCheck | ForEach-Object { Write-Host "        - $_" -ForegroundColor DarkGray }
            
            if ($tempCheck -notcontains $tempDistro) {
                throw "Temporary instance was not created: $tempDistro"
            }
            
            Write-Host "      Temporary instance created successfully: $tempDistro" -ForegroundColor Gray
            
            # エクスポートファイル削除（サイズが大きいため）
            Remove-Item $tempExport -ErrorAction SilentlyContinue
            
        } catch {
            Write-ColorOutput Red "Error creating temporary instance: $_"
            if (Test-Path $tempExport) {
                Remove-Item $tempExport -ErrorAction SilentlyContinue
            }
            return
        }
        
        # IncludeDevTools が指定された場合、すべてのツールを含める
        if ($IncludeDevTools) {
            $IncludePodman = $true
            $IncludeGitHubCLI = $true
            $IncludeClaudeCode = $true
        }
        
        # 最小化スクリプト実行
        Write-Host "[3/5] Running minimization script..." -ForegroundColor White
        if ($IncludePodman) {
            Write-Host "      Including: Podman" -ForegroundColor Gray
        }
        if ($IncludeGitHubCLI) {
            Write-Host "      Including: GitHub CLI" -ForegroundColor Gray
        }
        if ($IncludeClaudeCode) {
            Write-Host "      Including: Claude Code" -ForegroundColor Gray
        }
        
        $setupScript = Get-MinimalSetupScript -WithPodman $IncludePodman -WithGitHubCLI $IncludeGitHubCLI -WithClaudeCode $IncludeClaudeCode
        $randomId = Get-Random -Maximum 9999
        $scriptPath = "$env:TEMP\minimal-setup-$randomId.sh"
        $setupScript | Out-File -FilePath $scriptPath -Encoding UTF8 -NoNewline
        
        # スクリプト実行の改善
        Write-Host "      Executing minimization script inside WSL..." -ForegroundColor Gray
        
        # スクリプトをWSL内にコピーして実行
        $wslScriptPath = "/tmp/minimal-setup.sh"
        
        Write-Host "      Preparing minimization script..." -ForegroundColor Gray
        
        # スクリプトの内容をBase64エンコード（特殊文字の問題を回避）
        $scriptBytes = [System.Text.Encoding]::UTF8.GetBytes($setupScript)
        $scriptBase64 = [Convert]::ToBase64String($scriptBytes)
        
        # Base64デコードしてWSL内にスクリプトを作成
        Write-Host "      Copying script to WSL instance..." -ForegroundColor Gray
        $decodeCommand = "echo '$scriptBase64' | base64 -d > $wslScriptPath && chmod +x $wslScriptPath"
        wsl -d $tempDistro -u root -- bash -c $decodeCommand
        
        # スクリプトの存在確認
        $checkCommand = "test -f $wslScriptPath && echo 'Script created successfully' || echo 'Script creation failed'"
        wsl -d $tempDistro -u root -- bash -c $checkCommand
        
        # WSL内でスクリプト実行
        $exitCode = 0
        try {
            Write-Host "      Running minimization script (this may take several minutes)..." -ForegroundColor Gray
            wsl -d $tempDistro -u root -- bash -c "$wslScriptPath"
            $exitCode = $LASTEXITCODE
        } catch {
            Write-ColorOutput Red "Error during minimization script execution: $_"
            $exitCode = 1
        }
        
        # スクリプト実行結果確認
        if ($exitCode -ne 0) {
            Write-ColorOutput Yellow "Warning: Minimization script completed with exit code $exitCode"
        } else {
            Write-Host "      Minimization script completed successfully" -ForegroundColor Gray
        }
        
        # 一時ファイル削除
        wsl -d $tempDistro -u root bash -c "rm -f /tmp/minimal-setup.sh" 2>$null
        Remove-Item $scriptPath -ErrorAction SilentlyContinue
        
        # エクスポート前の状態確認
        Write-Host "      Verifying minimization results..." -ForegroundColor Gray
        
        # WSL内でサイズ確認
        try {
            $diskInfo = wsl -d $tempDistro -u root bash -c "df -h / 2>/dev/null | tail -1" 2>$null
            if ($diskInfo) {
                Write-Host "      Current disk usage: $diskInfo" -ForegroundColor Gray
            }
        } catch {
            Write-Host "      Could not retrieve disk usage information" -ForegroundColor Gray
        }
        
        # 重要ファイルの存在確認
        Write-Host "      Verifying critical files..." -ForegroundColor Gray
        
        $verifyScript = @'
echo "Checking critical files:"
echo -n "  /etc/resolv.conf: "
if [ -f /etc/resolv.conf ] || [ -L /etc/resolv.conf ]; then
    echo "OK ($(ls -la /etc/resolv.conf | awk '{print $9, $10, $11}'))"
else
    echo "MISSING!"
fi

echo -n "  /root/.hushlogin: "
if [ -f /root/.hushlogin ]; then
    echo "OK"
else
    echo "MISSING!"
fi

echo -n "  /home/wsluser/.hushlogin: "
if [ -f /home/wsluser/.hushlogin ]; then
    echo "OK"
else
    echo "MISSING!"
fi

echo -n "  systemd-resolved: "
if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    echo "ACTIVE"
else
    echo "INACTIVE"
fi

echo -n "  DNS resolution: "
if getent hosts google.com >/dev/null 2>&1; then
    echo "WORKING"
else
    echo "FAILED"
fi
'@
        
        $verifyResult = wsl -d $tempDistro -u root -- bash -c $verifyScript
        Write-Host $verifyResult -ForegroundColor Gray
        
        # 問題が見つかった場合の警告
        if ($verifyResult -match "MISSING!|INACTIVE|FAILED") {
            Write-ColorOutput Yellow "      Warning: Some critical components may have issues"
            Write-LogOutput "Verification found issues: $verifyResult" "WARNING"
        }
        Write-Host "[4/5] Exporting minimal image..." -ForegroundColor White
        wsl --terminate $tempDistro
        wsl --export $tempDistro $BaseImagePath
        
        # サイズ確認と結果表示
        if (Test-Path $BaseImagePath) {
            $imageSize = [math]::Round((Get-Item $BaseImagePath).Length / 1MB, 2)
            Write-Host "[5/5] Image created successfully!" -ForegroundColor Green
        } else {
            Write-ColorOutput Red "Error: Image file was not created at $BaseImagePath"
            return
        }
        Write-Host ""
        Write-ColorOutput Green "Summary:"
        Write-Host "  Image path: $BaseImagePath"
        Write-Host "  Image size: ${imageSize}MB"
        Write-Host "  Features included:"
        Write-Host "    - Minimal Ubuntu 22.04"
        if ($IncludePodman) {
            Write-Host "    - Podman (container runtime)"
        }
        if ($IncludeGitHubCLI) {
            Write-Host "    - GitHub CLI (gh)"
        }
        if ($IncludeClaudeCode) {
            Write-Host "    - Claude Code + Project Identifier"
        }
        
    } finally {
        # クリーンアップ（エラーハンドリング付き）
        if (-not $KeepTempInstance) {
            Write-Host ""
            Write-Host "Cleaning up temporary instance..." -ForegroundColor Gray
            
            try {
                # 一時インスタンスのクリーンアップ
                $tempCheck = wsl --list --quiet 2>$null | ForEach-Object { 
                    $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
                } | Where-Object { $_ -ne '' }
                
                if ($tempCheck -contains $tempDistro) {
                    wsl --terminate $tempDistro 2>$null
                    Start-Sleep -Seconds 2
                    wsl --unregister $tempDistro 2>$null
                }
                
                # 一時ディレクトリのクリーンアップ
                if (Test-Path $tempInstanceDir) {
                    Remove-Item -Recurse -Force $tempInstanceDir -ErrorAction SilentlyContinue
                }
                
                # 一時ファイルクリーンアップ
                Get-ChildItem -Path $env:TEMP -Filter "ubuntu-temp-base-*.tar" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $env:TEMP -Filter "minimal-setup-*.sh" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                
                # wsl-minimal-temp-* ディレクトリのクリーンアップ
                Get-ChildItem -Path $env:TEMP -Filter "wsl-minimal-temp-*" -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                
            } catch {
                Write-ColorOutput Yellow "Warning: Some cleanup operations failed: $_"
            }
        } else {
            Write-Host ""
            Write-ColorOutput Yellow "Temporary instance '$tempDistro' was kept for debugging"
            Write-Host "To manually clean up later:"
            Write-Host "  wsl --unregister $tempDistro"
            if (Test-Path $tempInstanceDir) {
                Write-Host "  Remove-Item -Recurse -Force '$tempInstanceDir'"
            }
        }
    }
    
    Write-Host ""
    Write-ColorOutput Green "✓ Minimal base image created successfully!"
    Write-Host ""
    Write-Host "Next step: Create instances using this image"
    Write-ColorOutput Gray "  .\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject"
}

# 新規インスタンス作成
function New-MinimalInstance {
    param([string]$Name)
    
    if (-not $Name) {
        Write-ColorOutput Red "Error: InstanceName is required"
        Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) -Action NewInstance -InstanceName <name>"
        return
    }
    
    Show-Header
    Write-ColorOutput Green "Creating New Minimal Instance: $Name"
    Write-Host ""
    
    # ベースイメージ確認
    if (-not (Test-Path $BaseImagePath)) {
        Write-ColorOutput Red "Error: Base image not found at $BaseImagePath"
        Write-Host ""
        Write-Host "Create a base image first:"
        Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase"
        return
    }
    
    $distroName = "Ubuntu-Minimal-$Name"
    $instancePath = "$env:USERPROFILE\WSL-Instances\$Name"
    
    # 既存チェック
    if (wsl --list --quiet | Select-String $distroName) {
        Write-ColorOutput Yellow "Instance '$distroName' already exists!"
        return
    }
    
    # インスタンス作成
    Write-Host "Creating instance from minimal image..."
    New-Item -ItemType Directory -Force -Path $instancePath | Out-Null
    wsl --import $distroName $instancePath $BaseImagePath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorOutput Green "✓ Instance created successfully!"
        Write-Host ""
        Write-Host "Instance name: $distroName"
        Write-Host "Location: $instancePath"
        Write-Host ""
        Write-Host "Connect to instance:"
        Write-ColorOutput Gray "  wsl -d $distroName"
        Write-Host ""
        Write-Host "Default user: wsluser"
        
        # サイズ情報
        $imageSize = [math]::Round((Get-Item $BaseImagePath).Length / 1MB, 2)
        Write-Host "Base image size: ${imageSize}MB"
    }
}

# イメージ一覧表示
function Show-ImageList {
    Show-Header
    Write-ColorOutput Green "Available Minimal Images"
    Write-Host ""
    
    $imageDir = Split-Path $BaseImagePath -Parent
    if (Test-Path $imageDir) {
        $images = Get-ChildItem -Path $imageDir -Filter "*.tar" -File
        
        if ($images.Count -eq 0) {
            Write-Host "No minimal images found in: $imageDir"
        } else {
            Write-Host "Images in: $imageDir"
            Write-Host ""
            $images | ForEach-Object {
                $size = [math]::Round($_.Length / 1MB, 2)
                Write-Host ("  {0,-40} {1,10} MB" -f $_.Name, $size)
            }
        }
    } else {
        Write-Host "Image directory not found: $imageDir"
    }
    
    Write-Host ""
    Write-ColorOutput Green "Active Minimal Instances"
    Write-Host ""
    
    $instances = wsl --list --verbose | Select-String "Ubuntu-Minimal-"
    if ($instances) {
        Write-Host $instances
    } else {
        Write-Host "No minimal instances found."
    }
}

# メイン処理
switch ($Action) {
    "CreateBase" {
        New-MinimalBaseImage
    }
    "NewInstance" {
        New-MinimalInstance -Name $InstanceName
    }
    "ListImages" {
        Show-ImageList
    }
    "Info" {
        Show-Info
    }
    default {
        Show-Info
    }
}