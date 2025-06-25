# Setup-AllDevTools.ps1
# 設定ファイルから認証情報を読み込んで一括設定

param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceName,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "devtools-config.json"
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput($Color, $Text) {
    Write-Host $Text -ForegroundColor $Color
}

# 設定ファイルの確認
if (-not (Test-Path $ConfigFile)) {
    Write-ColorOutput Red "Configuration file not found: $ConfigFile"
    Write-Host ""
    Write-Host "Please create a configuration file based on devtools-config.example.json"
    Write-Host "Example:"
    Write-ColorOutput Gray "  Copy-Item devtools-config.example.json devtools-config.json"
    Write-ColorOutput Gray "  # Edit devtools-config.json with your credentials"
    exit 1
}

try {
    # 設定ファイルを読み込み
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    Write-ColorOutput Cyan "Loading configuration from: $ConfigFile"
    Write-Host ""
    
    # パラメータを構築
    $params = @{
        InstanceName = $InstanceName
    }
    
    if ($config.git.userName) {
        $params.GitUserName = $config.git.userName
    }
    
    if ($config.git.userEmail) {
        $params.GitUserEmail = $config.git.userEmail
    }
    
    if ($config.github.token) {
        $params.GitHubToken = $config.github.token
    }
    
    if ($config.claude.apiKey) {
        $params.AnthropicApiKey = $config.claude.apiKey
    }
    
    if ($config.useWindowsCredentials) {
        $params.UseWindowsCredentials = $true
    }
    
    # Setup-DevTools.ps1を実行
    & "$PSScriptRoot\Setup-DevTools.ps1" @params
    
} catch {
    Write-ColorOutput Red "Error reading configuration file: $_"
    exit 1
}