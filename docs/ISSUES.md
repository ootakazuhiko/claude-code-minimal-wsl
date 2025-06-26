# Known Issues / 既知の問題

## 1. Windows Terminal プロファイルの重複登録

### 問題の概要
Windows TerminalのドロップダウンメニューにWSLインスタンスが重複して表示される場合があります。
- 自動生成されるプロファイル（例: `Ubuntu-Minimal-test05`）
- Claude テーマ付きプロファイル（例: `Ubuntu-Minimal-test05 🤖`）

### 現在の状況
- Create-MinimalUbuntuWSL.ps1には重複を防ぐロジックが実装済み
- Windows Terminalの自動検出タイミングにより、まれに重複が発生する可能性がある
- Clean-DuplicateProfiles.ps1で事後的にクリーンアップ可能

### 対処方法（一時的）
```powershell
# 重複を確認
.\Clean-DuplicateProfiles.ps1 -DryRun

# 重複を削除
.\Clean-DuplicateProfiles.ps1
```

### TODO
- Windows Terminal APIの動作を詳細に調査
- プロファイル生成のタイミング制御の改善
- より確実な重複防止メカニズムの実装

---

## 2. その他の問題
（今後追加予定）