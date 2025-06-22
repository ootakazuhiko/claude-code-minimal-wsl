# Fix-WSLDistroName.ps1
# WSLのディストリビューション名を確認して正しい名前を取得

Write-Host "Checking exact WSL distribution names..." -ForegroundColor Cyan
Write-Host ""

# 全てのディストリビューションを取得
$wslOutput = wsl -l -q 2>$null

Write-Host "Raw output from 'wsl -l -q':" -ForegroundColor Yellow
$wslOutput | ForEach-Object { 
    $name = $_.Trim()
    if ($name -ne "") {
        Write-Host "  [$name]" -ForegroundColor Gray
        
        # 16進数でバイトを表示（エンコーディング問題の診断用）
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($_)
        $hex = ($bytes | ForEach-Object { $_.ToString("X2") }) -join " "
        Write-Host "  Hex: $hex" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Cleaned names:" -ForegroundColor Yellow

$distroNames = @()
$wslOutput | ForEach-Object {
    $cleaned = $_.Trim() -replace '\0', '' -replace '[^\x20-\x7E]', ''
    if ($cleaned -ne "" -and $cleaned -match '\S') {
        $distroNames += $cleaned
        Write-Host "  - $cleaned" -ForegroundColor Green
        
        if ($cleaned -like "*22*04*" -or $cleaned -like "*2204*") {
            Write-Host "    ^ This looks like Ubuntu 22.04!" -ForegroundColor Cyan
        }
    }
}

Write-Host ""
Write-Host "To use a specific distribution, copy its exact name from above." -ForegroundColor Yellow