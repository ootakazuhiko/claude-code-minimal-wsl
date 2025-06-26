# Setup-DevTools.ps1
# gh, git, claude の認証と設定を一括で行うスクリプト

param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceName,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AnthropicApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [string]$GitUserName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$GitUserEmail = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$UseWindowsCredentials = $false
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

Write-ColorOutput Cyan @"

=====================================
 Developer Tools Setup for WSL
=====================================

This script will configure:
- Git (user configuration)
- GitHub CLI (authentication)
- Claude Code (API key)

"@

# 設定スクリプトの作成
$setupScript = @'
#!/bin/bash
set -e

echo "=== Setting up developer tools ==="
echo ""

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Git設定
echo -e "${BLUE}[1/3] Configuring Git...${NC}"

if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    echo -e "  ${GREEN}✓${NC} Set git user.name: $GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    echo -e "  ${GREEN}✓${NC} Set git user.email: $GIT_USER_EMAIL"
fi

# Git エディタとデフォルト設定
git config --global core.editor "vim"
git config --global init.defaultBranch main
git config --global push.default current
git config --global pull.rebase false

# Windows認証情報マネージャーの設定（オプション）
if [ "$USE_WINDOWS_CREDS" = "true" ]; then
    git config --global credential.helper "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe"
    echo -e "  ${GREEN}✓${NC} Configured Windows credential manager"
else
    # WSL内での認証情報保存
    git config --global credential.helper "store --file ~/.git-credentials"
    git config --global credential.helper 'cache --timeout=3600'
fi

echo ""

# 2. GitHub CLI設定
echo -e "${BLUE}[2/3] Configuring GitHub CLI...${NC}"

if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} GitHub CLI authenticated successfully"
        gh auth status
    else
        echo -e "  ${RED}✗${NC} GitHub CLI authentication failed"
    fi
else
    echo -e "  ${YELLOW}!${NC} No GitHub token provided"
    echo "  To authenticate later, run: gh auth login"
fi

# GitHub CLIのデフォルト設定
gh config set editor vim 2>/dev/null || true
gh config set git_protocol https 2>/dev/null || true
gh config set prompt enabled 2>/dev/null || true

echo ""

# 3. Claude Code設定
echo -e "${BLUE}[3/3] Configuring Claude Code...${NC}"

# Claude設定ディレクトリ作成
mkdir -p ~/.config/claude

if [ -n "$ANTHROPIC_API_KEY" ]; then
    # 環境変数として設定
    echo "export ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY'" >> ~/.bashrc
    echo -e "  ${GREEN}✓${NC} Set ANTHROPIC_API_KEY in ~/.bashrc"
    
    # Claude設定ファイル作成
    cat > ~/.config/claude/config.yaml << EOF
# Claude Code Configuration
api:
  key: "$ANTHROPIC_API_KEY"
  
defaults:
  model: "claude-3-opus-20240229"
  max_tokens: 4096
  temperature: 0.7

editor:
  command: "vim"
EOF
    echo -e "  ${GREEN}✓${NC} Created Claude configuration file"
else
    echo -e "  ${YELLOW}!${NC} No Anthropic API key provided"
    echo "  To set up later:"
    echo "    export ANTHROPIC_API_KEY='your-api-key'"
    echo "    or run: claude auth login"
fi

echo ""

# 4. 設定の永続化
echo -e "${BLUE}Creating persistent configuration...${NC}"

# 起動時設定スクリプト作成
cat > ~/.config/devtools-env.sh << 'EOF'
# Developer Tools Environment Configuration

# GitHub CLI
export GH_NO_UPDATE_NOTIFIER=1

# Claude Code
export CLAUDE_HOME="$HOME/.config/claude"

# Git
export GIT_MERGE_AUTOEDIT=no

# 認証状態の確認関数
check_auth_status() {
    echo "=== Authentication Status ==="
    
    # Git
    echo -n "Git user: "
    git config --global user.name 2>/dev/null || echo "Not configured"
    
    # GitHub CLI
    echo -n "GitHub: "
    gh auth status &>/dev/null && echo "Authenticated" || echo "Not authenticated"
    
    # Claude
    echo -n "Claude: "
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "API key configured"
    else
        echo "Not configured"
    fi
}

# エイリアス
alias auth-status='check_auth_status'
alias gh-login='gh auth login'
alias claude-login='claude auth login'
EOF

# .bashrcに追加
if ! grep -q "devtools-env.sh" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Developer tools configuration" >> ~/.bashrc
    echo "[ -f ~/.config/devtools-env.sh ] && source ~/.config/devtools-env.sh" >> ~/.bashrc
fi

echo -e "  ${GREEN}✓${NC} Created environment configuration"
echo ""

# 5. 最終確認
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Authentication status:"
echo "---------------------"

# Git状態
echo -n "Git configuration: "
if [ -n "$(git config --global user.name)" ] && [ -n "$(git config --global user.email)" ]; then
    echo -e "${GREEN}✓${NC} Configured"
    echo "  Name: $(git config --global user.name)"
    echo "  Email: $(git config --global user.email)"
else
    echo -e "${YELLOW}Partial${NC}"
fi

# GitHub CLI状態
echo -n "GitHub CLI: "
if gh auth status &>/dev/null; then
    echo -e "${GREEN}✓${NC} Authenticated"
else
    echo -e "${RED}✗${NC} Not authenticated"
fi

# Claude状態
echo -n "Claude Code: "
if [ -n "$ANTHROPIC_API_KEY" ] || [ -f ~/.config/claude/config.yaml ]; then
    echo -e "${GREEN}✓${NC} Configured"
else
    echo -e "${RED}✗${NC} Not configured"
fi

echo ""
echo "Next steps:"
echo "-----------"
if ! gh auth status &>/dev/null; then
    echo "1. Authenticate GitHub CLI: gh auth login"
fi
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "2. Set Claude API key: export ANTHROPIC_API_KEY='your-key'"
fi
echo ""
echo "To check auth status anytime: auth-status"
'@

# 環境変数の設定
$envVars = @{
    "GIT_USER_NAME" = $GitUserName
    "GIT_USER_EMAIL" = $GitUserEmail
    "GITHUB_TOKEN" = $GitHubToken
    "ANTHROPIC_API_KEY" = $AnthropicApiKey
    "USE_WINDOWS_CREDS" = if ($UseWindowsCredentials) { "true" } else { "false" }
}

# Windows側の認証情報を取得（オプション）
if ($UseWindowsCredentials -and [string]::IsNullOrEmpty($GitUserName)) {
    try {
        $gitName = git config --global user.name 2>$null
        $gitEmail = git config --global user.email 2>$null
        if ($gitName) { $envVars["GIT_USER_NAME"] = $gitName }
        if ($gitEmail) { $envVars["GIT_USER_EMAIL"] = $gitEmail }
        Write-Host "  Using Windows Git configuration" -ForegroundColor Gray
    } catch {
        Write-Host "  Could not read Windows Git configuration" -ForegroundColor Yellow
    }
}

# スクリプトを一時ファイルに保存
$tempScriptFile = "$env:TEMP\setup-devtools-$(Get-Random).sh"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tempScriptFile, $setupScript.Replace("`r`n", "`n"), $utf8NoBom)

try {
    Write-Host "Running setup in WSL instance: $InstanceName" -ForegroundColor Yellow
    Write-Host ""
    
    # ファイルをWSLにコピー
    $windowsPath = $tempScriptFile.Replace('\', '/')
    $wslWindowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(2)
    $wslScriptPath = "/tmp/setup-devtools.sh"
    
    # 環境変数を設定してスクリプトを実行
    $envString = ($envVars.GetEnumerator() | Where-Object { $_.Value } | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join " "
    
    $command = @"
cp '$wslWindowsPath' $wslScriptPath && 
chmod +x $wslScriptPath && 
$envString bash $wslScriptPath
"@
    
    wsl -d $InstanceName -- bash -c $command
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorOutput Green "✓ Developer tools setup completed!"
        
        if ([string]::IsNullOrEmpty($GitHubToken) -or [string]::IsNullOrEmpty($AnthropicApiKey)) {
            Write-Host ""
            Write-Host "Manual authentication required:" -ForegroundColor Yellow
            
            if ([string]::IsNullOrEmpty($GitHubToken)) {
                Write-Host "  GitHub CLI:" -ForegroundColor Cyan
                Write-Host "    wsl -d $InstanceName" -ForegroundColor Gray
                Write-Host "    gh auth login" -ForegroundColor Gray
            }
            
            if ([string]::IsNullOrEmpty($AnthropicApiKey)) {
                Write-Host "  Claude Code:" -ForegroundColor Cyan
                Write-Host "    Get API key from: https://console.anthropic.com/" -ForegroundColor Gray
                Write-Host "    wsl -d $InstanceName" -ForegroundColor Gray
                Write-Host "    export ANTHROPIC_API_KEY='your-api-key'" -ForegroundColor Gray
                Write-Host "    echo 'export ANTHROPIC_API_KEY=\"your-api-key\"' >> ~/.bashrc" -ForegroundColor Gray
            }
        }
    }
    
} finally {
    # クリーンアップ
    if (Test-Path $tempScriptFile) {
        Remove-Item $tempScriptFile -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "To check authentication status:" -ForegroundColor Yellow
Write-Host "  wsl -d $InstanceName" -ForegroundColor Gray
Write-Host "  auth-status" -ForegroundColor Gray