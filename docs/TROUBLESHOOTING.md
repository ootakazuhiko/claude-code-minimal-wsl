# Troubleshooting Guide / トラブルシューティングガイド

## PowerShell Script Execution Issues / PowerShellスクリプト実行エラー

### 環境による動作の違い

PowerShellスクリプトが一部の環境で動作しない主な原因：

### 1. **文字エンコーディングの違い**

#### 問題
- 日本語Windows環境: Shift-JIS (CP932)
- 英語Windows環境: Windows-1252
- PowerShell Core: UTF-8

#### 確認方法
```powershell
# PowerShellのエンコーディング確認
[System.Console]::OutputEncoding
[System.Console]::InputEncoding
$PSDefaultParameterValues['*:Encoding']

# システムロケール確認
Get-Culture
Get-WinSystemLocale
```

#### 解決方法
```powershell
# PowerShellセッションでUTF-8を強制
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
```

### 2. **PowerShellバージョンの違い**

#### 確認方法
```powershell
# PowerShellバージョン確認
$PSVersionTable
```

#### 影響する要素
- Windows PowerShell 5.1: Windows標準（レガシー）
- PowerShell Core 6.x/7.x: クロスプラットフォーム版（推奨）

#### 解決方法
```powershell
# PowerShell 7のインストール
winget install Microsoft.PowerShell

# PowerShell 7で実行
pwsh.exe .\Create-MinimalUbuntuWSL.ps1 -Action CreateBase
```

### 3. **実行ポリシーの違い**

#### 確認方法
```powershell
Get-ExecutionPolicy -List
```

#### 解決方法
```powershell
# 現在のセッションのみ許可
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# または署名なしスクリプトを許可
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### 4. **ファイルのダウンロード方法による違い**

#### 問題
- GitHubからZIPダウンロード: Zone.Identifier付き
- Git clone: Zone.Identifierなし
- ブラウザダウンロード: ブロックされる可能性

#### 確認方法
```powershell
# ファイルのゾーン情報確認
Get-Item .\Create-MinimalUbuntuWSL.ps1 -Stream Zone.Identifier
```

#### 解決方法
```powershell
# ブロック解除
Unblock-File .\*.ps1

# または一括解除
Get-ChildItem -Recurse *.ps1 | Unblock-File
```

### 5. **改行コードの違い**

#### 問題
- Windows (CRLF): `\r\n`
- Unix/Linux (LF): `\n`
- 混在すると解析エラー

#### 確認方法
```powershell
# ファイルの改行コード確認
$content = Get-Content .\Create-MinimalUbuntuWSL.ps1 -Raw
$content.Contains("`r`n")  # True = CRLF
$content.Contains("`n") -and -not $content.Contains("`r`n")  # True = LF
```

#### 解決方法
```powershell
# Git設定で改行コードを統一
git config core.autocrlf true  # Windows環境
```

### 6. **BOM (Byte Order Mark) の有無**

#### 問題
- UTF-8 with BOM: 一部の環境で問題
- UTF-8 without BOM: 推奨

#### 確認方法
```powershell
# ファイルの先頭バイト確認
$bytes = [System.IO.File]::ReadAllBytes(".\Create-MinimalUbuntuWSL.ps1")
$bytes[0..2] | ForEach-Object { $_.ToString("X2") }
# EF BB BF = UTF-8 BOM
```

### 7. **Windows Terminal vs レガシーコンソール**

#### 確認方法
```powershell
# コンソールホスト確認
$env:WT_SESSION  # Windows Terminalの場合は値が設定される
```

#### 推奨設定
- Windows Terminal使用を推奨
- UTF-8サポートが完全

## 推奨環境設定

### 最も安定する構成
```powershell
# 1. PowerShell 7をインストール
winget install Microsoft.PowerShell

# 2. Windows Terminalをインストール
winget install Microsoft.WindowsTerminal

# 3. Git for Windowsをインストール
winget install Git.Git

# 4. リポジトリをクローン
git clone https://github.com/ootakazuhiko/claude-code-minimal-wsl.git
cd claude-code-minimal-wsl

# 5. PowerShell 7で実行
pwsh.exe -ExecutionPolicy Bypass .\Create-MinimalUbuntuWSL.ps1 -Action CreateBase
```

## エラー別対処法

### "式またはステートメントのトークンを使用できません"
```powershell
# エンコーディング修正
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

# ファイルを再ダウンロード
git clone https://github.com/ootakazuhiko/claude-code-minimal-wsl.git
```

### "文字列に終端記号がありません"
```powershell
# 改行コード確認と修正
$content = Get-Content .\Create-MinimalUbuntuWSL.ps1 -Raw
$content = $content -replace "`r`n", "`n"
Set-Content .\Create-MinimalUbuntuWSL.ps1 -Value $content -NoNewline
```

### "ハッシュリテラルが不完全です"
- 通常は文字エンコーディングの問題
- UTF-8 without BOMで保存し直す

## 診断スクリプト

環境の違いを診断するスクリプト：

```powershell
# Save as Check-Environment.ps1
Write-Host "=== PowerShell Environment Check ===" -ForegroundColor Cyan

# PowerShell Version
Write-Host "`nPowerShell Version:" -ForegroundColor Yellow
$PSVersionTable | Format-Table -AutoSize

# Encoding
Write-Host "`nEncoding Settings:" -ForegroundColor Yellow
Write-Host "Output Encoding: $([System.Console]::OutputEncoding.EncodingName)"
Write-Host "Input Encoding: $([System.Console]::InputEncoding.EncodingName)"

# Culture
Write-Host "`nCulture Settings:" -ForegroundColor Yellow
Write-Host "Current Culture: $(Get-Culture)"
Write-Host "System Locale: $(Get-WinSystemLocale)"

# Console
Write-Host "`nConsole Information:" -ForegroundColor Yellow
Write-Host "Windows Terminal: $(if($env:WT_SESSION){'Yes'}else{'No'})"
Write-Host "Console Code Page: $(chcp.com | Select-String -Pattern '\d+')"

# Execution Policy
Write-Host "`nExecution Policy:" -ForegroundColor Yellow
Get-ExecutionPolicy -List | Format-Table -AutoSize

# Git Settings
Write-Host "`nGit Configuration:" -ForegroundColor Yellow
try {
    git config core.autocrlf
    git config core.eol
} catch {
    Write-Host "Git not installed or not in PATH" -ForegroundColor Red
}
```

## ベストプラクティス

1. **開発環境の統一**
   - PowerShell 7.x を使用
   - Windows Terminal を使用
   - VSCode でファイル編集（UTF-8 without BOM）

2. **ファイル取得方法**
   - `git clone` を使用（推奨）
   - ZIP ダウンロードの場合は `Unblock-File` 実行

3. **実行方法**
   ```powershell
   # PowerShell 7 で明示的に実行
   pwsh.exe -ExecutionPolicy Bypass -File .\Create-MinimalUbuntuWSL.ps1 -Action CreateBase
   ```

4. **エンコーディング統一**
   ```powershell
   # セッション開始時に設定
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   $PSDefaultParameterValues['*:Encoding'] = 'utf8'
   ```