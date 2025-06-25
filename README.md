# Minimal Ubuntu WSL Image Creator

A PowerShell-based tool for creating ultra-lightweight Ubuntu WSL2 instances optimized for Claude Code development.

## Features

- **Ultra-lightweight**: Reduces standard Ubuntu from ~1.5GB to ~500MB
- **Claude Code optimized**: Pre-configured with Claude Code CLI and Project Identifier
- **Optional tools**: Selectively include Podman, GitHub CLI, and development tools
- **Easy management**: Simple commands for creating and managing WSL instances
- **Project context**: Automatic project identification and terminal title display

## Quick Start

**Note**: First time users may need to set PowerShell execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### 1. Create a Minimal Base Image

```powershell
# Basic minimal image with Claude Code (default)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# With specific tools (use - not +)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman -IncludeGitHubCLI

# With all development tools
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeDevTools

# Without Claude Code (base only)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode:$false
```

### 2. Create a New Instance

```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject
```

### 3. Connect to Your Instance

```powershell
wsl -d Ubuntu-Minimal-myproject
```

## Available Options

| Option | Description | Size Impact |
|--------|-------------|-------------|
| Base only | Minimal Ubuntu without Claude Code | ~500MB |
| `+IncludeClaudeCode` | Claude Code CLI + Project Identifier | ~650MB |
| `+IncludePodman` | Podman container runtime | ~850MB |
| `+IncludeGitHubCLI` | GitHub CLI (gh) | ~700MB |
| `+IncludeDevTools` | All tools combined | ~1GB |

## Commands

### Initial Setup / 初回設定

PowerShellの実行ポリシーを設定する必要があります:
```powershell
# 現在のセッションのみ許可
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# または、現在のユーザーに対して許可（永続的）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Base Management
```powershell
# Create base images
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase [-IncludePodman] [-IncludeGitHubCLI] [-IncludeClaudeCode] [-IncludeDevTools]

# List available images
.\Create-MinimalUbuntuWSL.ps1 -Action ListImages

# Show help
.\Create-MinimalUbuntuWSL.ps1 -Action Info
```

### Instance Management
```powershell
# Create new instance
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName <name>

# List all WSL instances
wsl --list -v

# Connect to instance
wsl -d Ubuntu-Minimal-<name>

# Stop instance
wsl --terminate Ubuntu-Minimal-<name>

# Remove instance
wsl --unregister Ubuntu-Minimal-<name>
```

## Claude Project Identifier Integration

Automatically installed with Claude Code option:

### Features
- Automatic project detection when entering directories
- Terminal title display with project information
- Context-aware development environment

### Usage
```bash
# Initialize a new project
mkdir my-project && cd my-project
claude-project-init

# Auto-display when changing directories
cd my-project  # Automatically shows project info
```

## System Requirements

- Windows 10/11 with WSL2 enabled
- PowerShell 5.1 or later
- Internet connection for package downloads
- At least 2GB free disk space

## PowerShell Execution Policy

By default, PowerShell may block script execution. Before running the scripts, you need to set the execution policy:

### Option 1: Temporary (Current Session Only)
```powershell
# Set execution policy for current PowerShell session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Option 2: Current User
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Option 3: Run Script Directly
```powershell
# Run script bypassing policy (one-time)
powershell.exe -ExecutionPolicy Bypass -File .\Create-MinimalUbuntuWSL.ps1 -Action Info
```

## Troubleshooting

### Common Issues

1. **WSL2 not enabled**
   ```powershell
   # Enable WSL and Virtual Machine Platform
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **Ubuntu-22.04 not available**
   - Install from Microsoft Store manually
   - Use diagnostic script: `.\Check-WSLDistributions.ps1`

3. **Permission issues**
   - Run PowerShell as Administrator for some operations

### Diagnostic Tools

```powershell
# Check WSL environment
.\Check-WSLDistributions.ps1

# Debug script generation
.\Debug-ScriptGeneration.ps1
```

## File Structure

```
ClaudeCode_WSL_Ubuntu_Image_Setup/
├── Create-MinimalUbuntuWSL.ps1      # Main creation script
├── Check-WSLDistributions.ps1       # Diagnostic tool
├── Debug-ScriptGeneration.ps1       # Debug tool
├── CLAUDE.md                        # Claude Code instructions
└── README.md                        # This file
```

## License

This project is provided as-is for educational and development purposes.

---

# Minimal Ubuntu WSL Image Creator (日本語)

Claude Code開発用に最適化された超軽量Ubuntu WSL2インスタンスを作成するPowerShellベースのツールです。

## 特徴

- **超軽量**: 標準Ubuntuの約1.5GBを約500MBに削減
- **Claude Code最適化**: Claude Code CLIとProject Identifierが事前設定済み
- **オプションツール**: Podman、GitHub CLI、開発ツールを選択的に含める
- **簡単管理**: WSLインスタンスの作成と管理が簡単なコマンドで可能
- **プロジェクトコンテキスト**: 自動プロジェクト識別とターミナルタイトル表示

## クイックスタート

**注意**: 初回実行時はPowerShell実行ポリシーの設定が必要な場合があります：
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### 1. 最小基本イメージの作成

```powershell
# Claude Code付きの基本最小イメージ（デフォルト）
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# 特定のツールを含める（+ではなく-を使用）
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman -IncludeGitHubCLI

# 全開発ツール付き
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeDevTools

# Claude Codeなし（ベースのみ）
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode:$false
```

### 2. 新しいインスタンスの作成

```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject
```

### 3. インスタンスへの接続

```powershell
wsl -d Ubuntu-Minimal-myproject
```

## 利用可能なオプション

| オプション | 説明 | サイズへの影響 |
|-----------|------|-------------|
| ベースのみ | Claude Codeなしの最小Ubuntu | ~500MB |
| `+IncludeClaudeCode` | Claude Code CLI + Project Identifier | ~650MB |
| `+IncludePodman` | Podmanコンテナランタイム | ~850MB |
| `+IncludeGitHubCLI` | GitHub CLI (gh) | ~700MB |
| `+IncludeDevTools` | 全ツール組み合わせ | ~1GB |

## コマンド

### ベース管理
```powershell
# 基本イメージの作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase [-IncludePodman] [-IncludeGitHubCLI] [-IncludeClaudeCode] [-IncludeDevTools]

# 利用可能なイメージを表示
.\Create-MinimalUbuntuWSL.ps1 -Action ListImages

# ヘルプを表示
.\Create-MinimalUbuntuWSL.ps1 -Action Info
```

### インスタンス管理
```powershell
# 新しいインスタンスを作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName <名前>

# 全WSLインスタンスを表示
wsl --list -v

# インスタンスに接続
wsl -d Ubuntu-Minimal-<名前>

# インスタンスを停止
wsl --terminate Ubuntu-Minimal-<名前>

# インスタンスを削除
wsl --unregister Ubuntu-Minimal-<名前>
```

## Claude Project Identifier統合

Claude Codeオプションで自動インストール：

### 機能
- ディレクトリ進入時の自動プロジェクト検出
- プロジェクト情報のターミナルタイトル表示
- コンテキスト対応開発環境

### 使用法
```bash
# 新しいプロジェクトを初期化
mkdir my-project && cd my-project
claude-project-init

# ディレクトリ変更時の自動表示
cd my-project  # プロジェクト情報を自動表示
```

## システム要件

- WSL2が有効なWindows 10/11
- PowerShell 5.1以降
- パッケージダウンロード用のインターネット接続
- 最低2GBの空きディスク容量

## PowerShell実行ポリシー

デフォルトでは、PowerShellはスクリプトの実行をブロックする場合があります。スクリプトを実行する前に、実行ポリシーを設定する必要があります：

### オプション1: 一時的（現在のセッションのみ）
```powershell
# 現在のPowerShellセッションのみ実行ポリシーを設定
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### オプション2: 現在のユーザー
```powershell
# 現在のユーザーの実行ポリシーを設定
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### オプション3: 直接スクリプトを実行
```powershell
# ポリシーをバイパスしてスクリプトを実行（一回限り）
powershell.exe -ExecutionPolicy Bypass -File .\Create-MinimalUbuntuWSL.ps1 -Action Info
```

## トラブルシューティング

### よくある問題

1. **WSL2が無効**
   ```powershell
   # WSLと仮想マシンプラットフォームを有効化
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **Ubuntu-22.04が利用できない**
   - Microsoft Storeから手動でインストール
   - 診断スクリプトを使用: `.\Check-WSLDistributions.ps1`

3. **権限の問題**
   - 一部の操作では管理者としてPowerShellを実行

### 診断ツール

```powershell
# WSL環境を確認
.\Check-WSLDistributions.ps1

# スクリプト生成をデバッグ
.\Debug-ScriptGeneration.ps1
```

## ファイル構造

```
ClaudeCode_WSL_Ubuntu_Image_Setup/
├── Create-MinimalUbuntuWSL.ps1      # メイン作成スクリプト
├── Check-WSLDistributions.ps1       # 診断ツール
├── Debug-ScriptGeneration.ps1       # デバッグツール
├── CLAUDE.md                        # Claude Code指示書
└── README.md                        # このファイル
```

## ライセンス

このプロジェクトは教育および開発目的で現状のまま提供されます。