# 使用方法ガイド / Usage Guide

## スクリプト一覧と使用方法

### 1. Create-MinimalUbuntuWSL.ps1
最小構成のUbuntu WSLイメージを作成・管理するメインスクリプト

```powershell
# ベースイメージの作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# Claude Code付きベースイメージの作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode

# 全ツール付きベースイメージの作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode -IncludeGitHubCLI -IncludePodman

# 新規インスタンスの作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject

# イメージ一覧の表示
.\Create-MinimalUbuntuWSL.ps1 -Action ListImages

# ヘルプの表示
.\Create-MinimalUbuntuWSL.ps1 -Action Info
```

### 2. Setup-DevTools.ps1
git、GitHub CLI、Claude Codeの認証設定を行うスクリプト

```powershell
# 対話的に設定
.\Setup-DevTools.ps1 -InstanceName Ubuntu-Minimal-myproject

# パラメータで一括設定
.\Setup-DevTools.ps1 -InstanceName Ubuntu-Minimal-myproject `
    -GitUserName "Your Name" `
    -GitUserEmail "your.email@example.com" `
    -GitHubToken "ghp_xxxxx" `
    -AnthropicApiKey "sk-ant-xxxxx"

# Windows認証情報を使用
.\Setup-DevTools.ps1 -InstanceName Ubuntu-Minimal-myproject -UseWindowsCredentials
```

### 3. Setup-AllDevTools.ps1
設定ファイルから認証情報を読み込んで一括設定

```powershell
# 設定ファイルの準備
Copy-Item devtools-config.example.json devtools-config.json
# devtools-config.json を編集

# 設定の適用
.\Setup-AllDevTools.ps1 -InstanceName Ubuntu-Minimal-myproject
```

### 4. Apply-ClaudeTheme.ps1
既存のWSLインスタンスにClaude Tealテーマを適用

```powershell
.\Apply-ClaudeTheme.ps1 -InstanceName Ubuntu-Minimal-myproject
```

### 5. Clean-DuplicateProfiles.ps1
Windows Terminalの重複プロファイルをクリーンアップ

```powershell
# 重複を確認（実行せずに確認のみ）
.\Clean-DuplicateProfiles.ps1 -DryRun

# 重複を削除
.\Clean-DuplicateProfiles.ps1
```

### 6. Test-MinimalWSL.ps1
WSLインスタンスの問題をテスト

```powershell
.\Test-MinimalWSL.ps1 -InstanceName Ubuntu-Minimal-myproject
```

### 7. Manual-Fix.ps1
既存インスタンスのMOTD問題を手動修正

```powershell
.\Manual-Fix.ps1 -InstanceName Ubuntu-Minimal-myproject
```

## 典型的なワークフロー

### 初回セットアップ
```powershell
# 1. ベースイメージの作成（Claude Code付き）
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode -IncludeGitHubCLI

# 2. 新規インスタンスの作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject

# 3. 開発ツールの認証設定
.\Setup-DevTools.ps1 -InstanceName Ubuntu-Minimal-myproject

# 4. WSLに接続
wsl -d Ubuntu-Minimal-myproject
```

### 複数インスタンスの一括設定
```powershell
# 1. 設定ファイルの準備
Copy-Item devtools-config.example.json devtools-config.json
# エディタでdevtools-config.jsonを編集

# 2. 複数インスタンスの作成と設定
$projects = @("project1", "project2", "project3")
foreach ($project in $projects) {
    .\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName $project
    .\Setup-AllDevTools.ps1 -InstanceName "Ubuntu-Minimal-$project"
}
```

## トラブルシューティング

### Windows Terminalプロファイルの重複
```powershell
.\Clean-DuplicateProfiles.ps1 -DryRun
.\Clean-DuplicateProfiles.ps1
```

### DNS解決の問題
```powershell
.\Test-MinimalWSL.ps1 -InstanceName Ubuntu-Minimal-myproject
```

### MOTDメッセージが表示される
```powershell
.\Manual-Fix.ps1 -InstanceName Ubuntu-Minimal-myproject
```