# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PowerShell-based Windows project for creating minimal Ubuntu WSL2 instances optimized for Claude Code development. The project creates lightweight Ubuntu distributions (~500MB vs standard 1.5GB) with optional development tools.

## Common Commands

### Creating WSL Instances

```powershell
# Base image only (~500MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode $false

# With Claude Code CLI (~650MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# With Podman (~850MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman $true

# With GitHub CLI (~700MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeGitHubCLI $true

# All tools (~1GB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman $true -IncludeGitHubCLI $true
```

### Managing Instances

```powershell
# List all WSL instances
wsl --list -v

# Stop an instance
wsl --terminate MyUbuntu

# Remove an instance
wsl --unregister MyUbuntu

# Enter an instance
wsl -d MyUbuntu
```

## Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| InstanceName | String | Required | Name for the WSL instance |
| BaseDir | String | $env:USERPROFILE\WSLInstances | Installation directory |
| UbuntuVersion | String | "jammy" | Ubuntu version (jammy=22.04) |
| InstallClaudeCode | Boolean | $true | Install Claude Code CLI |
| InstallPodman | Boolean | $false | Install Podman container engine |
| InstallGitHubCLI | Boolean | $false | Install GitHub CLI |
| CreateUserHome | Boolean | $true | Create home directory structure |
| SetupSudo | Boolean | $true | Configure sudo access |
| LocaleSetup | String | "en_US.UTF-8" | System locale |
| Timezone | String | "UTC" | System timezone |
| UserName | String | "ubuntu" | Default user name |

## Architecture

- **Main Script**: `Create-MinimalUbuntuWSL.ps1` - PowerShell script that orchestrates the entire setup
- **Installer Script**: `claude-code-installer.sh` - Bash script for Claude Code installation
- **No build system**: This is a script collection, not a compiled project
- **No tests**: No testing framework is implemented

## Development Workflow

1. Modify PowerShell scripts for WSL creation logic
2. Test changes by creating new instances with different parameters
3. Update documentation files when adding new features
4. Previous versions are kept as .old files for reference

## Special Considerations

- Requires Windows 10/11 with WSL2 enabled
- PowerShell must be run as Administrator for some operations
- Internet connection required for package downloads
- Each instance is completely isolated from others
- Minimal setup removes many standard Ubuntu packages to save space

## Claude Project Identifier

This image includes Claude Project Identifier for enhanced project context display:

### Quick Start
```bash
# Create a new project
mkdir my-project && cd my-project
claude-project-init

# This creates:
# - .claude-project (project metadata)
# - CLAUDE.md (project instructions)
# - Shows project info in terminal title
```

### Usage
```bash
# Display project info
claude-project-init

# Auto-display when entering project directories
cd my-project  # Automatically shows project info
```

## Troubleshooting Commands

```bash
# Inside WSL - Check Claude Code installation
claude --version

# Check Claude Project Identifier
claude-project-init --version

# Check available disk space
df -h

# Update package lists if installation fails
sudo apt update

# Check system information
lsb_release -a
```

## Size Optimization Details

The minimal setup removes:
- Documentation packages
- Development headers
- Perl, Python packages
- Manual pages
- Localization files (except en_US)
- Various system utilities not needed for development

This results in ~1GB savings compared to standard Ubuntu WSL installations.

---

# CLAUDE.md (日本語版)

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code) にガイダンスを提供します。

## プロジェクト概要

これは、Claude Code開発用に最適化された最小Ubuntu WSL2インスタンスを作成するためのPowerShellベースのWindowsプロジェクトです。このプロジェクトは、オプションの開発ツールを含む軽量Ubuntu配布版（標準1.5GBに対し約500MB）を作成します。

## 一般的なコマンド

### WSLインスタンスの作成

```powershell
# ベースイメージのみ (~500MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode $false

# Claude Code CLI付き (~650MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# Podman付き (~850MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman $true

# GitHub CLI付き (~700MB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeGitHubCLI $true

# 全ツール付き (~1GB)
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman $true -IncludeGitHubCLI $true
```

### インスタンス管理

```powershell
# すべてのWSLインスタンスを表示
wsl --list -v

# インスタンスを停止
wsl --terminate MyUbuntu

# インスタンスを削除
wsl --unregister MyUbuntu

# インスタンスに入る
wsl -d MyUbuntu
```

## 主要パラメータ

| パラメータ | 型 | デフォルト | 説明 |
|-----------|------|---------|-------------|
| InstanceName | String | 必須 | WSLインスタンスの名前 |
| BaseDir | String | $env:USERPROFILE\WSLInstances | インストールディレクトリ |
| UbuntuVersion | String | "jammy" | Ubuntuバージョン (jammy=22.04) |
| InstallClaudeCode | Boolean | $true | Claude Code CLIをインストール |
| InstallPodman | Boolean | $false | Podmanコンテナエンジンをインストール |
| InstallGitHubCLI | Boolean | $false | GitHub CLIをインストール |
| CreateUserHome | Boolean | $true | ホームディレクトリ構造を作成 |
| SetupSudo | Boolean | $true | sudoアクセスを設定 |
| LocaleSetup | String | "en_US.UTF-8" | システムロケール |
| Timezone | String | "UTC" | システムタイムゾーン |
| UserName | String | "ubuntu" | デフォルトユーザー名 |

## アーキテクチャ

- **メインスクリプト**: `Create-MinimalUbuntuWSL.ps1` - セットアップ全体を統制するPowerShellスクリプト
- **インストーラースクリプト**: `claude-code-installer.sh` - Claude Codeインストール用のBashスクリプト
- **ビルドシステムなし**: これはコンパイルされたプロジェクトではなく、スクリプトの集合です
- **テストなし**: テストフレームワークは実装されていません

## 開発ワークフロー

1. WSL作成ロジック用にPowerShellスクリプトを修正
2. 異なるパラメータで新しいインスタンスを作成してテスト
3. 新機能追加時にドキュメントファイルを更新
4. 過去のバージョンは参照用に.oldファイルとして保持

## 特別な考慮事項

- WSL2が有効なWindows 10/11が必要
- 一部の操作ではPowerShellを管理者として実行する必要があります
- パッケージダウンロードにインターネット接続が必要
- 各インスタンスは完全に分離されています
- 最小セットアップは開発に不要な多くの標準Ubuntuパッケージを削除します

## Claude Project Identifier

このイメージには、プロジェクトコンテキスト表示を強化するClaude Project Identifierが含まれています：

### クイックスタート
```bash
# 新しいプロジェクトを作成
mkdir my-project && cd my-project
claude-project-init

# これにより以下が作成されます：
# - .claude-project (プロジェクトメタデータ)
# - CLAUDE.md (プロジェクト指示)
# - ターミナルタイトルにプロジェクト情報を表示
```

### 使用法
```bash
# プロジェクト情報を表示
claude-project-init

# プロジェクトディレクトリに入ると自動表示
cd my-project  # プロジェクト情報を自動的に表示
```

## トラブルシューティングコマンド

```bash
# WSL内 - Claude Codeインストールを確認
claude --version

# Claude Project Identifierを確認
claude-project-init --version

# 利用可能なディスク容量を確認
df -h

# インストール失敗時にパッケージリストを更新
sudo apt update

# システム情報を確認
lsb_release -a
```

## サイズ最適化の詳細

最小セットアップでは以下を削除します：
- ドキュメントパッケージ
- 開発ヘッダー
- Perl、Pythonパッケージ
- マニュアルページ
- ローカライゼーションファイル（en_US以外）
- 開発に不要な各種システムユーティリティ

これにより、標準Ubuntu WSLインストールと比較して約1GBの節約になります。