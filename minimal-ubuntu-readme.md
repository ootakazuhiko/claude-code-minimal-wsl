# Minimal Ubuntu WSL Image Creator

最小構成のUbuntu WSLイメージを作成・管理するスタンドアロンツール

## 特徴

- **超軽量**: 通常の1.5GB → 約500MBに削減
- **高速起動**: 不要なサービスを削除
- **再利用可能**: 一度作成したイメージから複数インスタンスを作成
- **開発ツール対応**: Podman、GitHub CLI、Claude Codeをオプションで追加可能

## 削除される主な要素

- Snap (snapd)
- Cloud-init
- NetworkManager
- 自動更新機能
- ドキュメント・manページ
- 不要なシステムサービス
- 開発ツール（後から必要に応じてインストール可能）

## クイックスタート

### 1. 最小イメージの作成

```powershell
# 基本的な最小イメージ
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# Podman入り最小イメージ
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman

# GitHub CLI入り最小イメージ
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeGitHubCLI

# Claude Code入り最小イメージ
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode

# すべての開発ツール入り（Podman + GitHub CLI + Claude Code）
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeDevTools
```

### 2. インスタンスの作成

```powershell
# 最小イメージから新しいインスタンスを作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject
```

### 3. インスタンスに接続

```bash
# WSLインスタンスに接続
wsl -d Ubuntu-Minimal-myproject
```

## コマンド一覧

### CreateBase - ベースイメージ作成
```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase [-IncludePodman]
```
- 最小構成のUbuntuイメージを作成
- デフォルト保存先: `%USERPROFILE%\WSL-MinimalImages\ubuntu-22.04-minimal.tar`

### NewInstance - 新規インスタンス作成
```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName <n>
```
- 保存されたイメージから新しいWSLインスタンスを作成
- インスタンス名: `Ubuntu-Minimal-<name>`

### ListImages - イメージとインスタンス一覧
```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action ListImages
```
- 作成済みのイメージファイルを表示
- アクティブなインスタンスを表示

### Info - ヘルプ表示
```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action Info
```

## カスタマイズ

### イメージ保存場所の変更
```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase `
    -BaseImagePath "D:\MyImages\minimal-ubuntu.tar"
```

### 一時インスタンスを保持（デバッグ用）
```powershell
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -KeepTempInstance
```

## バッチファイルの使用

付属の `minimal-ubuntu-commands.bat` を使用すると、メニュー形式で操作できます：

```batch
minimal-ubuntu-commands.bat
```

メニューオプション：
1. 最小イメージ作成（ツールなし）
2. 最小イメージ作成（Podman付き）
3. 最小イメージ作成（GitHub CLI付き）
4. 最小イメージ作成（すべての開発ツール付き）
5. 新規インスタンス作成
6. イメージ・インスタンス一覧
7. クイックセットアップ（ベース＋2インスタンス）

## インスタンスの初期設定

作成されたインスタンスには以下が設定されています：

- **デフォルトユーザー**: `wsluser` (sudo権限付き)
- **systemd**: 有効
- **DNS**: 1.1.1.1, 1.0.0.1 (Cloudflare)
- **ロケール**: en_US.UTF-8
- **タイムゾーン**: UTC

### 追加パッケージのインストール例

```bash
# 開発ツール
sudo apt update
sudo apt install -y build-essential

# Docker/Podman
sudo apt install -y podman

# Python
sudo apt install -y python3 python3-pip
```

## トラブルシューティング

### WSLが見つからない
```powershell
# WSLをインストール
wsl --install
```

### イメージ作成に失敗する
- 管理者権限でPowerShellを実行
- 十分なディスク容量があることを確認（最低2GB）

### インスタンスが起動しない
```powershell
# WSLをリセット
wsl --shutdown
```

### GitHub CLIの認証
```bash
# インスタンス内で実行
gh auth login
```

### Podmanが動作しない
```bash
# ユーザー名前空間の確認
podman system migrate
podman system reset
```

### Claude Codeが見つからない
- プレースホルダー実装のため、公式インストール手順に従って手動インストールが必要

## サイズ比較

| 構成 | サイズ | パッケージ数 | 起動時間 |
|------|--------|-------------|----------|
| 標準Ubuntu | ~1.5GB | 600-800 | 5-8秒 |
| 最小構成 | ~500MB | 200-250 | 2-3秒 |
| 最小構成+Podman | ~800MB | 250-300 | 3-4秒 |
| 最小構成+GitHub CLI | ~550MB | 210-260 | 2-3秒 |
| 最小構成+すべての開発ツール | ~900MB | 300-350 | 3-4秒 |

## 削除方法

### インスタンスの削除
```powershell
wsl --unregister Ubuntu-Minimal-myproject
```

### イメージファイルの削除
```powershell
Remove-Item "$env:USERPROFILE\WSL-MinimalImages\ubuntu-22.04-minimal.tar"
```

## Claude Code のインストールについて

Claude Codeは公式ドキュメント（https://docs.anthropic.com/ja/docs/claude-code/getting-started）に基づいてインストールされます。

### インストール内容

1. **Python環境のセットアップ**
   - Python 3とpipのインストール
   - 仮想環境のサポート

2. **Claude Code CLIのインストール**
   - pipを使用したインストール
   - または仮想環境へのインストール

3. **設定ファイルの作成**
   - `~/.config/claude-code/config.yaml`
   - APIキー設定のテンプレート

### インストール後の設定

1. **APIキーの取得**
   ```bash
   # Anthropic Consoleでキーを取得
   # https://console.anthropic.com/
   ```

2. **APIキーの設定**
   ```bash
   # 環境変数で設定（推奨）
   export ANTHROPIC_API_KEY='your-api-key-here'
   echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
   
   # またはインタラクティブログイン
   claude-code auth login
   ```

3. **動作確認**
   ```bash
   # バージョン確認
   claude-code --version
   
   # 簡単なテスト
   echo "Hello, Claude!" | claude-code
   ```

### 手動インストール

インスタンス作成後に手動でClaude Codeをインストールする場合：

```bash
# インスタンスに接続
wsl -d Ubuntu-Minimal-myproject

# 付属のインストールスクリプトを実行
curl -fsSL https://raw.githubusercontent.com/yourusername/minimal-claude-workspaces/main/install-claude-code.sh | bash

# またはpipで直接インストール
pip3 install --user claude-code
```

## 注意事項

- 最小構成のため、多くの一般的なツールが削除されています
- 必要に応じて後からパッケージを追加インストールしてください
- systemdは有効ですが、多くのサービスは無効化されています