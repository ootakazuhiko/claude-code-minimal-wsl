# WSL Installation Guide / WSLインストールガイド

## Prerequisites / 前提条件

### System Requirements / システム要件
- Windows 10 version 2004 and higher (Build 19041 and higher)
- Windows 11
- 64-bit processor
- 4GB RAM (8GB recommended)
- Virtualization enabled in BIOS

### Check Your Windows Version / Windowsバージョンの確認
```powershell
# Run in PowerShell
winver
```

## Quick Installation (Recommended) / クイックインストール（推奨）

### 1. Open PowerShell as Administrator / 管理者としてPowerShellを開く
- Press `Win + X`
- Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

### 2. Install WSL / WSLのインストール
```powershell
wsl --install
```

This command will:
- Enable required Windows features
- Download and install WSL2
- Install Ubuntu as default distribution

### 3. Restart Your Computer / コンピュータを再起動
```powershell
Restart-Computer
```

### 4. Complete Ubuntu Setup / Ubuntuのセットアップを完了
After restart, Ubuntu will launch automatically:
- Create a username
- Set a password

## Manual Installation / 手動インストール

If the quick installation doesn't work:

### 1. Enable WSL Feature / WSL機能を有効化
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

### 2. Enable Virtual Machine Platform / 仮想マシンプラットフォームを有効化
```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### 3. Restart / 再起動
```powershell
Restart-Computer
```

### 4. Download WSL2 Kernel / WSL2カーネルのダウンロード
Download and install from:
https://aka.ms/wsl2kernel

### 5. Set WSL2 as Default / WSL2をデフォルトに設定
```powershell
wsl --set-default-version 2
```

### 6. Install Ubuntu / Ubuntuのインストール
```powershell
wsl --install -d Ubuntu-22.04
```

## Verification / 確認

### Check WSL Installation / WSLインストールの確認
```powershell
# Check WSL version
wsl --version

# List installed distributions
wsl --list --verbose
```

### Run Requirements Check / 要件チェックの実行
```powershell
.\Check-WSLRequirements.ps1
```

## Troubleshooting / トラブルシューティング

### Error: WSL 2 requires an update to its kernel component
1. Download: https://aka.ms/wsl2kernel
2. Install the MSI package
3. Try again

### Error: Virtual machine could not be started
1. Enable virtualization in BIOS
2. Run as Administrator:
```powershell
bcdedit /set hypervisorlaunchtype auto
```
3. Restart computer

### Error: The Windows Subsystem for Linux optional component is not enabled
```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

## After WSL Installation / WSLインストール後

Once WSL is installed, you can proceed with creating minimal Ubuntu images:

```powershell
# Create minimal base image
.\Create-MinimalUbuntuWSL.ps1 -Action CreateBase -IncludeClaudeCode

# Create new instance
.\Create-MinimalUbuntuWSL.ps1 -Action NewInstance -InstanceName myproject
```

## Additional Resources / 追加リソース

- [Microsoft WSL Documentation](https://learn.microsoft.com/en-us/windows/wsl/)
- [WSL GitHub Repository](https://github.com/microsoft/WSL)
- [WSL Command Reference](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)