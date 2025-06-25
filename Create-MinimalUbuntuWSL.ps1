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
    [switch]$ShowOutput = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = ""
)

# エラー処理を調整：重要でないエラーではスクリプトを停止しない
$ErrorActionPreference = "Continue"

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
- Standard Ubuntu: ~1.5GB -> Minimal: ~500MB
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
    Write-Host "  -DebugMode         Enable full debug output during script execution"
    Write-Host "  -ShowOutput        Show detailed output (less than DebugMode)"
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
# Enhanced error handling and debugging

echo "================================================="
echo " Starting Ubuntu Minimization"
echo "================================================="
echo ""
echo "Script started at: $(date)"
echo "Running as user: $(whoami)"
echo "Working directory: $(pwd)"
echo ""

# エラーハンドラの改善
error_handler() {
    local exit_code=$?
    local line_no=${1:-$LINENO}
    echo "ERROR: Command failed at line $line_no with exit code $exit_code"
    echo "  Last command: $BASH_COMMAND"
    echo "  Continuing execution..."
    return 0
}

# トラップを設定（ただし、スクリプト全体は停止しない）
trap 'error_handler $LINENO' ERR

# デバッグ情報の表示
debug_info() {
    echo "DEBUG: $1"
}

debug_info "Error handler and trap configured"

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

# WSL設定 - systemd-resolved とWSLの協調動作を設定
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true

[network]
generateHosts=true
generateResolvConf=true

[automount]
enabled=true
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=true
EOF

# systemd-resolved設定を最適化
mkdir -p /etc/systemd/resolved.conf.d/
cat > /etc/systemd/resolved.conf.d/wsl.conf << 'EOF'
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1
FallbackDNS=208.67.222.222 208.67.220.220
DNSSEC=no
Cache=yes
DNSStubListener=yes
EOF

# systemd-resolved を有効化し起動
systemctl unmask systemd-resolved 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true

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

# systemd-resolved が確実に有効であることを再確認
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

# MOTD完全無効化 - より確実なアプローチ
echo "Completely disabling MOTD and login messages..."

# update-motd.d のスクリプトを無効化（削除ではなく実行権限を剥奪）
if [ -d /etc/update-motd.d ]; then
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
    # 特に問題のあるスクリプトを個別に無効化
    chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
    chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
    chmod -x /etc/update-motd.d/91-* 2>/dev/null || true
    chmod -x /etc/update-motd.d/99-* 2>/dev/null || true
fi

# MOTDファイルを空にする
echo "" > /etc/motd
echo "" > /etc/issue
echo "" > /etc/issue.net

# ランタイムのMOTDファイルも無効化
rm -f /run/motd.dynamic 2>/dev/null || true
mkdir -p /run
touch /run/motd.dynamic
chmod 444 /run/motd.dynamic

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

# systemd-resolved が正しく動作するようにnsswitchを設定
if [ -f /etc/nsswitch.conf ]; then
    # hostsラインを修正してsystemd-resolved経由で名前解決するように設定
    sed -i 's/^hosts:.*/hosts: files resolve [!UNAVAIL=return] dns myhostname/' /etc/nsswitch.conf
else
    # nsswitch.confを作成
    cat > /etc/nsswitch.conf << 'NSSEOF'
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
NSSEOF
fi

# /etc/resolv.confのリンクを正しく設定（systemd-resolved用）
rm -f /etc/resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 8. ユーザー設定
echo "[8/8] Setting up user..."
useradd -m -s /bin/bash -G sudo wsluser 2>/dev/null || true
echo "wsluser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ログインメッセージを完全に無効化 - 包括的アプローチ
echo "Setting up complete login message suppression..."

# Claude環境専用のプロンプト設定（ティール系）
echo "Setting up Claude-specific teal prompt..."

# プロンプト設定を.bashrcに追加する関数
setup_claude_prompt() {
    local target_file="$1"
    
    cat >> "$target_file" << 'CLAUDE_PROMPT'

# Claude Code Environment - Teal Theme
export PS1='\[\e[48;5;30m\]\[\e[97m\] [CLAUDE] \[\e[0m\] \[\e[36m\]\u@\h\[\e[0m\]:\[\e[93m\]\w\[\e[0m\]\$ '

# Claude environment indicator on login
if [ -z "$CLAUDE_WELCOME_SHOWN" ]; then
    echo -e "\e[48;5;30m\e[97m ========================================= \e[0m"
    echo -e "\e[48;5;30m\e[97m |     Claude Code Environment Active    | \e[0m"
    echo -e "\e[48;5;30m\e[97m ========================================= \e[0m"
    echo ""
    export CLAUDE_WELCOME_SHOWN=1
fi

# Claude-specific aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias cls='clear'

# Set terminal title to show Claude environment
echo -ne "\033]0;[Claude WSL] - $(pwd)\007"

# Update terminal title on directory change
cd() {
    builtin cd "$@"
    echo -ne "\033]0;[Claude WSL] - $(pwd)\007"
}
CLAUDE_PROMPT
}

# /etc/skel/.bashrcに追加（新規ユーザー用）
setup_claude_prompt "/etc/skel/.bashrc"

# rootユーザーの.bashrcに追加
setup_claude_prompt "/root/.bashrc"

# wsluserの.bashrcに追加
if [ -f /home/wsluser/.bashrc ]; then
    setup_claude_prompt "/home/wsluser/.bashrc"
fi

# 他の既存ユーザーにも適用
for user_home in /home/*; do
    if [ -d "$user_home" ] && [ -f "$user_home/.bashrc" ] && [ "$(basename "$user_home")" != "lost+found" ]; then
        setup_claude_prompt "$user_home/.bashrc"
    fi
done

echo "Claude teal prompt setup completed."

# すべてのユーザーに対して .hushlogin を設定
echo "Creating .hushlogin files..."

# rootユーザー用 .hushlogin（確実に作成）
touch /root/.hushlogin
chmod 644 /root/.hushlogin
chown root:root /root/.hushlogin

# wsluser用 .hushlogin
if [ -d /home/wsluser ]; then
    touch /home/wsluser/.hushlogin
    chown wsluser:wsluser /home/wsluser/.hushlogin
    chmod 644 /home/wsluser/.hushlogin
fi

# デフォルトユーザー用（WSLが作成する可能性のあるユーザー）
mkdir -p /etc/skel
touch /etc/skel/.hushlogin
chmod 644 /etc/skel/.hushlogin

# 追加のユーザーディレクトリがある場合の対応
for user_dir in /home/*; do
    if [ -d "$user_dir" ] && [ "$(basename "$user_dir")" != "lost+found" ]; then
        username=$(basename "$user_dir")
        if ! [ -f "$user_dir/.hushlogin" ]; then
            touch "$user_dir/.hushlogin"
            chown "$username:$username" "$user_dir/.hushlogin" 2>/dev/null || true
            chmod 644 "$user_dir/.hushlogin"
        fi
    fi
done

# .hushloginの確認と保護
echo "Protecting .hushlogin files from deletion..."
chattr +i /root/.hushlogin 2>/dev/null || true
if [ -f /home/wsluser/.hushlogin ]; then
    chattr +i /home/wsluser/.hushlogin 2>/dev/null || true
fi

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

# 最終確認とログ出力
echo ""
echo "=== Final Configuration Verification ==="
echo ""

# DNS設定の確認
echo "DNS Configuration:"
echo "  systemd-resolved status:"
systemctl is-enabled systemd-resolved 2>/dev/null | head -1
echo "  resolv.conf link:"
ls -la /etc/resolv.conf 2>/dev/null | head -1
echo "  systemd-resolved config:"
ls -la /etc/systemd/resolved.conf.d/ 2>/dev/null | grep -v total | head -3

# MOTD設定の確認
echo ""
echo "MOTD Configuration:"
echo "  .hushlogin files:"
ls -la /root/.hushlogin 2>/dev/null && echo "    ✓ /root/.hushlogin exists" || echo "    ✗ /root/.hushlogin missing"
[ -f /home/wsluser/.hushlogin ] && echo "    ✓ /home/wsluser/.hushlogin exists" || echo "    ✗ /home/wsluser/.hushlogin missing"
ls -la /etc/skel/.hushlogin 2>/dev/null && echo "    ✓ /etc/skel/.hushlogin exists" || echo "    ✗ /etc/skel/.hushlogin missing"

echo "  MOTD scripts executable status:"
executable_motd_count=$(find /etc/update-motd.d -type f -executable 2>/dev/null | wc -l)
echo "    Executable MOTD scripts: $executable_motd_count (should be 0)"

echo "  motd-news config:"
grep "ENABLED=" /etc/default/motd-news 2>/dev/null | head -1 || echo "    motd-news config not found"

# ネットワーク設定の確認
echo ""
echo "Network Configuration:"
echo "  nsswitch.conf hosts line:"
grep "^hosts:" /etc/nsswitch.conf 2>/dev/null | head -1 || echo "    nsswitch.conf not found"

echo ""
echo "=== Configuration Setup Complete ==="
echo ""

'@

    # オプショナルツールのカウンター
    $stepNum = 8
    
    # GitHub CLI インストール
    if ($WithGitHubCLI) {
        $script += @'

# $stepNum. GitHub CLI インストール
echo "[$stepNum/X] Installing GitHub CLI..."

# GitHub CLI GPGキー追加
echo "  Downloading GitHub CLI GPG key..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /tmp/githubcli.gpg || {
    echo "  ERROR: Failed to download GitHub CLI GPG key"
    return 1
}
dd if=/tmp/githubcli.gpg of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1
rm -f /tmp/githubcli.gpg

# リポジトリ追加
echo "deb [arch=`$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

# インストール
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends gh >/dev/null 2>&1

# クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

'@
        $stepNum++
    }
    
    # Claude Code インストール
    if ($WithClaudeCode) {

        $script += @'

# 9. Claude Code インストール
echo "[9/X] Installing Claude Code..."

# Claude Code の前提条件
echo "Installing Node.js for Claude Code..."
echo "  Downloading Node.js setup script..."
# Node.js 20.x をインストール
curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh || {
    echo "  ERROR: Failed to download Node.js setup script"
    return 1
}
bash /tmp/nodesource_setup.sh >/dev/null 2>&1
rm -f /tmp/nodesource_setup.sh
apt-get install -y nodejs >/dev/null 2>&1

# npmが正しくインストールされたか確認
if ! command -v npm >/dev/null 2>&1; then
    echo "Error: npm installation failed"
    return 1
fi

# Claude Code インストール
echo "Installing Claude Code CLI..."

# npm を使用してグローバルにインストール（出力を制御）
npm install -g @anthropic-ai/claude-code 2>&1 | grep -v "^npm notice" | grep -v "^$" || {
    echo "Error: Claude Code installation failed"
    echo "Please check https://docs.anthropic.com/en/docs/claude-code for installation instructions"
}

# シンボリックリンクを作成（claude-codeがclaudeとしても使えるように）
claude_path=`$(command -v claude-code 2>/dev/null || command -v claude 2>/dev/null)
if [ -n "`$claude_path" ]; then
    if [ ! -e /usr/bin/claude ]; then
        ln -sf "`$claude_path" /usr/bin/claude 2>/dev/null || true
    fi
    echo "Claude Code installed at: `$claude_path"
    # バージョン確認
    claude --version 2>/dev/null || claude-code --version 2>/dev/null || echo "Warning: Could not verify Claude Code version"
else
    echo "Warning: Claude Code binary not found in PATH"
fi

# Claude Project Identifier インストール
echo "Installing Claude Project Identifier..."

# インストール前にgitが利用可能か確認
if ! command -v git >/dev/null 2>&1; then
    echo "  ERROR: git is not available for Claude Project Identifier installation"
    echo "  Skipping Claude Project Identifier installation..."
else
    echo "  Downloading installation script..."
    
    # より詳細なエラー出力でインストールスクリプトを実行
    su - wsluser -c "
        export DEBIAN_FRONTEND=noninteractive
        curl -fsSL https://raw.githubusercontent.com/ootakazuhiko/claude-project-identifier/main/scripts/install.sh 2>/dev/null | bash -s 2>&1
    " || {
        echo "  Claude Project Identifier installation failed, trying manual installation..."
        
        # Manual installation fallback - より安全な方法
        mkdir -p /home/wsluser/.claude-project-identifier
        cd /home/wsluser/.claude-project-identifier
        
        echo "  Downloading core files manually..."
        
        # 個別にファイルをダウンロード
        curl -fsSL -o init.sh https://raw.githubusercontent.com/ootakazuhiko/claude-project-identifier/main/scripts/init-project.sh 2>/dev/null && {
            chmod +x init.sh
            chown wsluser:wsluser init.sh
            echo "  Manual installation completed"
        } || {
            echo "  Manual installation also failed - Claude Project Identifier will not be available"
            rm -rf /home/wsluser/.claude-project-identifier
        }
    }
fi

# Create command symlink if installation succeeded
if [ -d /home/wsluser/.claude-project-identifier ]; then
    mkdir -p /home/wsluser/.local/bin
    ln -sf /home/wsluser/.claude-project-identifier/init.sh /home/wsluser/.local/bin/claude-project-init 2>/dev/null || true
    
    chown -R wsluser:wsluser /home/wsluser/.claude-project-identifier 2>/dev/null || true
    chown -R wsluser:wsluser /home/wsluser/.local/bin 2>/dev/null || true
fi

# 環境変数とパスの設定（修正版）
echo '# Claude Code settings' >> /home/wsluser/.bashrc
echo 'export PATH=$PATH:$HOME/.local/bin' >> /home/wsluser/.bashrc
echo '' >> /home/wsluser/.bashrc
echo '# Claude Code completion (if available)' >> /home/wsluser/.bashrc
echo 'if command -v claude &> /dev/null; then' >> /home/wsluser/.bashrc
echo '    eval "$(claude --completion-script bash 2>/dev/null || true)"' >> /home/wsluser/.bashrc
echo 'fi' >> /home/wsluser/.bashrc
echo '' >> /home/wsluser/.bashrc
echo '# Claude Code aliases' >> /home/wsluser/.bashrc
echo 'alias cc="claude"' >> /home/wsluser/.bashrc
echo '' >> /home/wsluser/.bashrc
echo '# Claude Project Identifier integration' >> /home/wsluser/.bashrc
echo 'if [ -f "$HOME/.claude-project-identifier/init.sh" ]; then' >> /home/wsluser/.bashrc
echo '    source "$HOME/.claude-project-identifier/init.sh"' >> /home/wsluser/.bashrc
echo 'fi' >> /home/wsluser/.bashrc
echo '' >> /home/wsluser/.bashrc
echo '# Auto-display project info when entering directories' >> /home/wsluser/.bashrc
echo 'cd() {' >> /home/wsluser/.bashrc
echo '    builtin cd "$@"' >> /home/wsluser/.bashrc
echo '    if [ -f ".claude-project" ]; then' >> /home/wsluser/.bashrc
echo '        if command -v claude-project-init &> /dev/null; then' >> /home/wsluser/.bashrc
echo '            claude-project-init' >> /home/wsluser/.bashrc
echo '        fi' >> /home/wsluser/.bashrc
echo '    fi' >> /home/wsluser/.bashrc
echo '}' >> /home/wsluser/.bashrc

# 設定ファイルディレクトリの作成
mkdir -p /home/wsluser/.config/claude-code
chown -R wsluser:wsluser /home/wsluser/.config/claude-code

# 初期設定ファイル
echo '# Claude Code Configuration' > /home/wsluser/.config/claude-code/config.yaml
echo '# See: https://docs.anthropic.com/ja/docs/claude-code/getting-started' >> /home/wsluser/.config/claude-code/config.yaml
echo '' >> /home/wsluser/.config/claude-code/config.yaml
echo '# API設定（キーは後で設定）' >> /home/wsluser/.config/claude-code/config.yaml
echo 'api:' >> /home/wsluser/.config/claude-code/config.yaml
echo '  # key: "your-api-key-here"' >> /home/wsluser/.config/claude-code/config.yaml
echo '  ' >> /home/wsluser/.config/claude-code/config.yaml
echo '# プロジェクト設定' >> /home/wsluser/.config/claude-code/config.yaml
echo 'project:' >> /home/wsluser/.config/claude-code/config.yaml
echo '  # プロジェクトルートの自動検出' >> /home/wsluser/.config/claude-code/config.yaml
echo '  auto_detect_root: true' >> /home/wsluser/.config/claude-code/config.yaml
echo '  ' >> /home/wsluser/.config/claude-code/config.yaml
echo '  # プロジェクト固有の設定ファイル' >> /home/wsluser/.config/claude-code/config.yaml
echo '  config_files:' >> /home/wsluser/.config/claude-code/config.yaml
echo '    - ".claude-project"' >> /home/wsluser/.config/claude-code/config.yaml
echo '    - "CLAUDE.md"' >> /home/wsluser/.config/claude-code/config.yaml
echo '    ' >> /home/wsluser/.config/claude-code/config.yaml
echo '# UI設定' >> /home/wsluser/.config/claude-code/config.yaml
echo 'ui:' >> /home/wsluser/.config/claude-code/config.yaml
echo '  # ターミナルのカラー出力' >> /home/wsluser/.config/claude-code/config.yaml
echo '  color: true' >> /home/wsluser/.config/claude-code/config.yaml
echo '  ' >> /home/wsluser/.config/claude-code/config.yaml
echo '  # プログレス表示' >> /home/wsluser/.config/claude-code/config.yaml
echo '  progress: true' >> /home/wsluser/.config/claude-code/config.yaml
echo '  ' >> /home/wsluser/.config/claude-code/config.yaml
echo '# その他設定' >> /home/wsluser/.config/claude-code/config.yaml
echo 'misc:' >> /home/wsluser/.config/claude-code/config.yaml
echo '  # 一時ファイルの自動削除' >> /home/wsluser/.config/claude-code/config.yaml
echo '  auto_cleanup: true' >> /home/wsluser/.config/claude-code/config.yaml

chown wsluser:wsluser /home/wsluser/.config/claude-code/config.yaml

# APIキー設定の案内
mkdir -p /opt/claude-code
echo '#!/bin/bash' > /opt/claude-code/setup-claude-code.sh
echo '# Claude Code セットアップヘルパー' >> /opt/claude-code/setup-claude-code.sh
echo '' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "======================================"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo " Claude Code Setup Helper"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "======================================"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "Claude Code has been installed."' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "To complete setup:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "1. Get your API key from: https://console.anthropic.com/"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "2. Set your API key using one of these methods:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   a) Environment variable:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "      export ANTHROPIC_API_KEY='\''your-api-key'\''"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "      echo '\''export ANTHROPIC_API_KEY=\"your-api-key\"'\'' >> ~/.bashrc"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   b) Claude CLI config:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "      claude auth login"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   c) Config file:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "      Edit ~/.config/claude/config.yaml"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "3. Verify installation:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   claude --version"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   claude --help"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "4. Quick test:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   echo '\''Hello, Claude!'\'' | claude"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "5. Claude Project Identifier setup:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   # Create a new project"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   mkdir my-project && cd my-project"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   claude-project-init"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   # This will create .claude-project and CLAUDE.md files"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "   # and show project info in terminal title"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "For more information:"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "https://docs.anthropic.com/ja/docs/claude-code/getting-started"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo "https://github.com/ootakazuhiko/claude-project-identifier"' >> /opt/claude-code/setup-claude-code.sh
echo 'echo ""' >> /opt/claude-code/setup-claude-code.sh

chmod +x /opt/claude-code/setup-claude-code.sh
chown wsluser:wsluser /opt/claude-code/setup-claude-code.sh

# クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Claude Code installation completed."
echo "Run '/opt/claude-code/setup-claude-code.sh' for setup instructions."

'@
        $stepNum++
    }

    # Podman インストール
    if ($WithPodman) {
        $script += @'

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
echo "  Downloading Podman GPG key..."
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_\${VERSION_ID}/Release.key" -o /tmp/podman.key || {
    echo "  ERROR: Failed to download Podman GPG key"
    return 1
}
apt-key add /tmp/podman.key >/dev/null 2>&1
rm -f /tmp/podman.key

# Podmanインストール
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends podman >/dev/null 2>&1

# Rootless設定
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 wsluser 2>/dev/null || true

# 再度クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

'@
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

# インストールされたツールの確認
echo ""
echo "=== Installed Tools Verification ==="
if command -v podman >/dev/null 2>&1; then
    echo "✓ Podman: `$(podman --version)"
else
    echo "✗ Podman: Not found"
fi

if command -v gh >/dev/null 2>&1; then
    echo "✓ GitHub CLI: `$(gh --version | head -1)"
else
    echo "✗ GitHub CLI: Not found"
fi

if command -v claude >/dev/null 2>&1 || command -v claude-code >/dev/null 2>&1; then
    claude_version=`$(claude --version 2>/dev/null || claude-code --version 2>/dev/null || echo "version unknown")
    echo "✓ Claude Code: `$claude_version"
else
    echo "✗ Claude Code: Not found"
fi

if command -v node >/dev/null 2>&1; then
    echo "✓ Node.js: `$(node --version)"
    echo "✓ npm: `$(npm --version)"
else
    echo "✗ Node.js: Not found"
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
        $ubuntu2204Name = ""
        foreach ($distro in $existingDistros) {
            # Ubuntu-22.04、Ubuntu 22.04 LTS、Ubuntu（デフォルト）、その他の形式をチェック
            if ($distro -eq "Ubuntu-22.04" -or 
                $distro -eq "Ubuntu 22.04 LTS" -or 
                $distro -like "Ubuntu*22.04*" -or
                $distro -eq "Ubuntu") {  # デフォルトのUbuntuも22.04の可能性
                $hasUbuntu2204 = $true
                $ubuntu2204Name = $distro
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
                            
                            # 複数の可能な名前をチェック（Ubuntuも含む）
                            foreach ($distro in $currentDistros) {
                                if ($distro -eq "Ubuntu-22.04" -or 
                                    $distro -eq "Ubuntu 22.04 LTS" -or 
                                    $distro -like "Ubuntu*22.04*" -or
                                    $distro -eq "Ubuntu") {
                                    Write-Host "      Ubuntu installation confirmed as: $distro" -ForegroundColor Green
                                    $installSuccess = $true
                                    $ubuntu2204Name = $distro
                                    break
                                }
                            }
                            
                            if ($installSuccess) {
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
                            
                            # 再度、複数の可能な名前をチェック（Ubuntuも含む）
                            foreach ($distro in $currentDistros) {
                                if ($distro -eq "Ubuntu-22.04" -or 
                                    $distro -eq "Ubuntu 22.04 LTS" -or 
                                    $distro -like "Ubuntu*22.04*" -or
                                    $distro -eq "Ubuntu") {
                                    $installSuccess = $true
                                    $ubuntu2204Name = $distro
                                    Write-Host "      Found Ubuntu as: $distro" -ForegroundColor Green
                                    break
                                }
                            }
                            
                            if (-not $installSuccess) {
                                Write-Host "      Installed distributions:" -ForegroundColor Yellow
                                $currentDistros | ForEach-Object { Write-Host "        - $_" -ForegroundColor Gray }
                                Write-Host ""
                                Write-Host "      Expected one of: Ubuntu-22.04, Ubuntu 22.04 LTS, or Ubuntu" -ForegroundColor Yellow
                                Write-ColorOutput Red "Error: No suitable Ubuntu distribution found after installation timeout"
                                return
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
                                Write-ColorOutput Red "Error: Ubuntu-22.04 installation required"
                                return
                            }
                        } else {
                            Write-ColorOutput Red "Error: No suitable Ubuntu distribution found"
                            return
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
            # 実際に見つかった名前を使用
            if ([string]::IsNullOrEmpty($ubuntu2204Name)) {
                # もう一度確認
                $finalCheck = wsl --list --quiet 2>$null | ForEach-Object { 
                    $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
                } | Where-Object { $_ -ne '' }
                
                foreach ($distro in $finalCheck) {
                    if ($distro -eq "Ubuntu-22.04" -or 
                        $distro -eq "Ubuntu 22.04 LTS" -or 
                        $distro -like "Ubuntu*22.04*" -or
                        $distro -eq "Ubuntu") {  # デフォルトのUbuntuも22.04の可能性
                        $ubuntu2204Name = $distro
                        break
                    }
                }
                
                if ([string]::IsNullOrEmpty($ubuntu2204Name)) {
                    Write-ColorOutput Red "Error: No suitable Ubuntu distribution found"
                    Write-Host "Available distributions:" -ForegroundColor Yellow
                    $finalCheck | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
                    Write-Host ""
                    Write-Host "Expected one of: Ubuntu-22.04, Ubuntu 22.04 LTS, or Ubuntu" -ForegroundColor Yellow
                    return
                }
            }
        }
        
        # 一時インスタンスとして再インポート
        Write-Host "[2/5] Creating temporary instance..." -ForegroundColor White
        
        # 使用するベースディストリビューション名を決定
        $baseDistro = if ($global:UseDefaultUbuntu) { "Ubuntu" } else { $ubuntu2204Name }
        
        try {
            Write-Host "      Exporting $baseDistro as base..." -ForegroundColor Gray
            wsl --export $baseDistro $tempExport
            
            if (-not (Test-Path $tempExport)) {
                Write-ColorOutput Red "Error: Export file was not created: $tempExport"
                return
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
                Write-ColorOutput Red "Error: Temporary instance was not created: $tempDistro"
                return
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
        
        # スクリプトを一時ファイルに保存してコピー（コマンドライン長制限と改行文字の問題を回避）
        Write-Host "      Copying script to WSL instance..." -ForegroundColor Gray
        $tempScriptFile = "$env:TEMP\wsl-setup-script-$(Get-Random).sh"
        
        # UTF8 without BOM でファイルに保存し、LF改行にする
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempScriptFile, $setupScript.Replace("`r`n", "`n"), $utf8NoBom)
        
        # ファイルをWSLにコピー（Windows パスを使用）
        $windowsPath = $tempScriptFile.Replace('\', '/')
        $wslWindowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(2)
        $copyCommand = "cp '$wslWindowsPath' $wslScriptPath && chmod +x $wslScriptPath"
        wsl -d $tempDistro -u root -- bash -c $copyCommand
        
        # 一時ファイルを削除
        Remove-Item $tempScriptFile -ErrorAction SilentlyContinue
        
        # スクリプトの存在確認
        $checkCommand = "test -f $wslScriptPath && echo 'Script created successfully' || echo 'Script creation failed'"
        wsl -d $tempDistro -u root -- bash -c $checkCommand
        
        # WSL内でスクリプト実行
        $exitCode = 0
        try {
            Write-Host "      Running minimization script (this may take several minutes)..." -ForegroundColor Gray
            Write-LogOutput "Starting minimization script execution" "INFO"
            
            # スクリプトの存在を確認
            $scriptExists = wsl -d $tempDistro -u root -- test -f $wslScriptPath
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput Red "Error: Minimization script not found at $wslScriptPath"
                Write-LogOutput "Script not found at $wslScriptPath" "ERROR"
                $exitCode = 1
            } else {
                Write-Host "      Script found, executing..." -ForegroundColor Gray
                Write-LogOutput "Executing: bash $wslScriptPath" "INFO"
                
                # スクリプトを実行し、出力を表示
                $scriptOutput = wsl -d $tempDistro -u root -- bash $wslScriptPath 2>&1
                $exitCode = $LASTEXITCODE
                
                # エラー時は常に最後の数行を表示、デバッグモードの場合は全出力を表示
                if ($exitCode -ne 0) {
                    Write-Host "      Script execution failed. Last output:" -ForegroundColor Yellow
                    # 最後の10行を表示
                    $outputLines = $scriptOutput -split "`n"
                    $lastLines = $outputLines | Select-Object -Last 10
                    foreach ($line in $lastLines) {
                        if ($line.Trim() -ne "") {
                            Write-Host "        $line" -ForegroundColor DarkGray
                        }
                    }
                }
                
                if ($DebugMode -or $ShowOutput) {
                    Write-Host "      Full script output:" -ForegroundColor Gray
                    Write-Host $scriptOutput -ForegroundColor DarkGray
                }
                
                Write-LogOutput "Script completed with exit code: $exitCode" "INFO"
                if (-not [string]::IsNullOrEmpty($LogFile)) {
                    Add-Content -Path $LogFile -Value "=== Script Output ===" -Encoding UTF8
                    Add-Content -Path $LogFile -Value $scriptOutput -Encoding UTF8
                    Add-Content -Path $LogFile -Value "=== End Script Output ===" -Encoding UTF8
                }
            }
        } catch {
            # エラーメッセージをクリーンアップ（改行文字や特殊文字を削除）
            $cleanError = ($_.ToString() -replace '\r?\n', ' ' -replace '\s+', ' ').Trim()
            Write-Host ""  # 改行を追加して表示を整える
            Write-ColorOutput Red "Error during minimization script execution: $cleanError"
            Write-LogOutput "Exception during script execution: $cleanError" "ERROR"
            $exitCode = 1
        }
        
        # スクリプト実行結果確認
        if ($exitCode -ne 0) {
            Write-Host ""  # 改行を追加して表示を整える
            Write-Host "      Warning: Minimization script completed with exit code $exitCode" -ForegroundColor Yellow
        } else {
            Write-Host "      Minimization script completed successfully" -ForegroundColor Gray
        }
        
        # 一時ファイル削除
        wsl -d $tempDistro -u root bash -c "rm -f /tmp/minimal-setup.sh" 2>$null
        
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
    ls -la /etc/resolv.conf | awk '"'"'{print "OK (" $9, $10, $11 ")"}'"'"'
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
        
        try {
            $verifyLines = @()
            $verifyOutput = wsl -d $tempDistro -u root -- bash -c $verifyScript 2>&1
            if ($verifyOutput) {
                # 文字列を確実に行に分割
                $verifyLines = $verifyOutput -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
                
                # 各行を個別に表示（インデント付き）
                foreach ($line in $verifyLines) {
                    if ($line -match "MISSING!|INACTIVE|FAILED") {
                        Write-Host "        $line" -ForegroundColor Yellow
                    } else {
                        Write-Host "        $line" -ForegroundColor Gray
                    }
                }
            }
            
            # 問題が見つかった場合の警告
            $hasIssues = $false
            foreach ($line in $verifyLines) {
                if ($line -match "MISSING!|INACTIVE|FAILED") {
                    $hasIssues = $true
                    break
                }
            }
            
            if ($hasIssues) {
                Write-Host ""
                Write-Host "      Warning: Some critical components may have issues" -ForegroundColor Yellow
                Write-LogOutput "Verification found issues in critical components" "WARNING"
            }
        } catch {
            Write-Host "      Could not verify critical files" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "[4/5] Exporting minimal image..." -ForegroundColor White
        Write-Host "      This may take several minutes..." -ForegroundColor Gray
        wsl --terminate $tempDistro
        Start-Sleep -Seconds 2  # ターミネート後の安定化のため待機
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
    Write-ColorOutput Green "[OK] Minimal base image created successfully!"
    Write-Host ""
    Write-Host "Next step: Create instances using this image"
    Write-ColorOutput Gray "  .\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject"
}

# Windows Terminal プロファイル設定関数
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
    
    # Windows Terminalプロセスが設定を更新している可能性があるため、少し待機
    Start-Sleep -Milliseconds 500
    
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
            "name" = "$InstanceName [Claude]"
            "commandline" = "wsl.exe -d $InstanceName"
            "colorScheme" = "Claude-Dark-Teal"
            "icon" = "ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png"
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
        
        # WSL自動生成プロファイルを探して更新（重複を避ける）
        # 複数の検出パターンで確実に検出
        $autoGeneratedProfile = $settings.profiles.list | Where-Object { 
            ($_.source -eq "Windows.Terminal.Wsl" -and $_.name -eq $InstanceName) -or
            ($_.source -eq "Windows.Terminal.Wsl" -and $_.commandline -like "*-d $InstanceName*") -or
            ($_.source -eq "Windows.Terminal.Wsl" -and $_.commandline -like "*-d `"$InstanceName`"*") -or
            ($_.guid -and $_.name -eq $InstanceName -and -not $_.icon)  # 自動生成は通常iconがない
        }
        
        if ($autoGeneratedProfile) {
            # 自動生成されたプロファイルを更新
            Write-Host "  Updating auto-generated WSL profile..." -ForegroundColor Gray
            $index = [array]::IndexOf($settings.profiles.list, $autoGeneratedProfile)
            
            # 自動生成プロファイルの必要な属性を保持しつつ更新
            $autoGeneratedProfile.name = "$InstanceName [Claude]"
            $autoGeneratedProfile.colorScheme = "Claude-Dark-Teal"
            $autoGeneratedProfile.useAcrylic = $true
            $autoGeneratedProfile.acrylicOpacity = 0.90
            $autoGeneratedProfile.tabColor = "#00796b"
            $autoGeneratedProfile.background = "#001414"
            $autoGeneratedProfile.icon = "ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png"
            if ($autoGeneratedProfile.font -eq $null) {
                $autoGeneratedProfile | Add-Member -MemberType NoteProperty -Name "font" -Value @{
                    "face" = "Cascadia Code"
                    "size" = 12
                } -Force
            }
            
            $settings.profiles.list[$index] = $autoGeneratedProfile
        } else {
            # 手動作成プロファイルが既に存在するかチェック
            $manualProfile = $settings.profiles.list | Where-Object { $_.name -eq "$InstanceName [Claude]" }
            if ($manualProfile) {
                # 既存の手動プロファイルを更新
                $index = [array]::IndexOf($settings.profiles.list, $manualProfile)
                $settings.profiles.list[$index] = $claudeProfile
            } else {
                # 新規プロファイルを追加
                $settings.profiles.list += $claudeProfile
            }
        }
        
        # 設定を保存（整形して保存）
        $json = $settings | ConvertTo-Json -Depth 10
        Set-Content -Path $settingsPath -Value $json -Encoding UTF8
        
        Write-ColorOutput Green "[OK] Windows Terminal profile created: '$InstanceName'"
        Write-Host "  Background: Dark Teal (#001414) - Claude Theme" -ForegroundColor Gray
        Write-Host "  Tab color: Dark Cyan (#00796b)" -ForegroundColor Gray
        Write-Host "  To use: Windows Terminal > Click dropdown > Select '$InstanceName'" -ForegroundColor Gray
        Write-Host ""
        Write-ColorOutput Yellow "Note: You may need to restart Windows Terminal for the changes to take effect"
        
    } catch {
        Write-ColorOutput Yellow "Warning: Could not update Windows Terminal settings: $_"
    }
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
    
    # ベースイメージパスを取得（グローバル変数を使用）
    $imagePath = $script:BaseImagePath
    
    # ベースイメージ確認
    if (-not (Test-Path $imagePath)) {
        Write-ColorOutput Red "Error: Base image not found at $imagePath"
        Write-Host ""
        Write-Host "Create a base image first:"
        Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action CreateBase"
        Write-Host ""
        Write-Host "Or specify a custom image path:"
        Write-ColorOutput Gray "  .\$($MyInvocation.MyCommand.Name) -Action NewInstance -InstanceName $Name -BaseImagePath <path>"
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
    wsl --import $distroName $instancePath $imagePath
    
    if ($LASTEXITCODE -eq 0) {
        # Windows Terminal プロファイル設定
        # Windows Terminalが自動プロファイルを生成する時間を確保
        Write-Host "Waiting for Windows Terminal to detect new instance..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        Set-ClaudeTerminalProfile -InstanceName $distroName
        
        Write-Host ""
        Write-ColorOutput Green "[OK] Instance created successfully!"
        Write-Host ""
        Write-Host "Instance name: $distroName"
        Write-Host "Location: $instancePath"
        Write-Host ""
        Write-Host "Connect to instance:"
        Write-ColorOutput Gray "  wsl -d $distroName"
        Write-Host "Or use Windows Terminal with the new '$distroName [Claude]' profile (Teal background)"
        Write-Host ""
        Write-Host "Default user: wsluser"
        
        # サイズ情報
        $imageSize = [math]::Round((Get-Item $imagePath).Length / 1MB, 2)
        Write-Host "Base image size: ${imageSize}MB"
        
        # 開発ツールの設定を促す
        Write-Host ""
        Write-ColorOutput Yellow "Next step: Configure developer tools"
        Write-Host "Run the following to set up git, gh, and claude authentication:"
        Write-ColorOutput Gray "  .\Setup-DevTools.ps1 -InstanceName $distroName"
        Write-Host ""
        Write-Host "Or configure manually inside WSL:"
        Write-Host "  Git: git config --global user.name 'Your Name'" -ForegroundColor Gray
        Write-Host "  GitHub: gh auth login" -ForegroundColor Gray
        Write-Host "  Claude: export ANTHROPIC_API_KEY='your-key'" -ForegroundColor Gray
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

# WSLの存在確認
function Test-WSLInstalled {
    try {
        $wslVersion = wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    } catch {
        # WSLコマンドが見つからない
    }
    
    # wsl.exeの存在を直接確認
    $wslPath = "$env:SystemRoot\System32\wsl.exe"
    if (Test-Path $wslPath) {
        return $true
    }
    
    return $false
}

# WSL確認
if (-not (Test-WSLInstalled)) {
    Write-ColorOutput Red "Error: WSL is not installed on this system."
    Write-Host ""
    Write-Host "Please install WSL first:" -ForegroundColor Yellow
    Write-Host "  1. Open PowerShell as Administrator" -ForegroundColor Gray
    Write-Host "  2. Run: wsl --install" -ForegroundColor Gray
    Write-Host "  3. Restart your computer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For more information:" -ForegroundColor Yellow
    Write-Host "  https://learn.microsoft.com/en-us/windows/wsl/install" -ForegroundColor Gray
    return
}

# メイン処理
try {
    switch ($Action) {
        "CreateBase" {
            try {
                New-MinimalBaseImage
            } catch {
                Write-Host ""
                Write-ColorOutput Red "Error in CreateBase action: $_"
                Write-Host "Stack trace:" -ForegroundColor Yellow
                Write-Host $_.ScriptStackTrace -ForegroundColor Gray
            }
        }
        "NewInstance" {
            try {
                New-MinimalInstance -Name $InstanceName
            } catch {
                Write-Host ""
                Write-ColorOutput Red "Error in NewInstance action: $_"
                Write-Host "Stack trace:" -ForegroundColor Yellow
                Write-Host $_.ScriptStackTrace -ForegroundColor Gray
            }
        }
        "ListImages" {
            try {
                Show-ImageList
            } catch {
                Write-Host ""
                Write-ColorOutput Red "Error in ListImages action: $_"
                Write-Host "Stack trace:" -ForegroundColor Yellow
                Write-Host $_.ScriptStackTrace -ForegroundColor Gray
            }
        }
        "Info" {
            try {
                Show-Info
            } catch {
                Write-Host ""
                Write-ColorOutput Red "Error in Info action: $_"
                Write-Host "Stack trace:" -ForegroundColor Yellow
                Write-Host $_.ScriptStackTrace -ForegroundColor Gray
            }
        }
        default {
            try {
                Show-Info
            } catch {
                Write-Host ""
                Write-ColorOutput Red "Error in default action: $_"
                Write-Host "Stack trace:" -ForegroundColor Yellow
                Write-Host $_.ScriptStackTrace -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host ""
    Write-ColorOutput Red "An unexpected error occurred in main processing: $_"
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Write-Host ""
    Write-Host "If this error persists, please check:" -ForegroundColor Yellow
    Write-Host "  1. WSL is properly installed and running" -ForegroundColor Gray
    Write-Host "  2. You have sufficient disk space" -ForegroundColor Gray
    Write-Host "  3. PowerShell execution policy allows script execution" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For troubleshooting, see:" -ForegroundColor Yellow
    Write-Host "  https://github.com/ootakazuhiko/claude-code-minimal-wsl/blob/main/TROUBLESHOOTING.md" -ForegroundColor Gray
}

# スクリプトの最後に明示的な正常終了を追加
Write-Host ""
Write-Host "Script execution completed." -ForegroundColor Green