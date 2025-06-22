# 使用例: 開発環境別の最適な構成

## Web開発者向け（Node.js + GitHub）
```powershell
# GitHub CLI付きイメージを作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeGitHubCLI

# インスタンス作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName web-dev

# 接続してNode.js環境をセットアップ
wsl -d Ubuntu-Minimal-web-dev
sudo apt update
sudo apt install -y nodejs npm
```

## コンテナ開発者向け（Podman + GitHub CLI）
```powershell
# Podman + GitHub CLI付きイメージを作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludePodman -IncludeGitHubCLI

# インスタンス作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName container-dev
```

## AI支援開発向け（すべてのツール）
```powershell
# すべての開発ツール付きイメージを作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeDevTools

# インスタンス作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName ai-dev
```

## 最小構成から始めて後から追加
```powershell
# 最小イメージを作成
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase

# インスタンス作成
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName minimal

# 接続して必要なツールを個別インストール
wsl -d Ubuntu-Minimal-minimal

# GitHub CLIをインストール
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Podmanをインストール
sudo apt install -y podman
```