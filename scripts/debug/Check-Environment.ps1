# Check-Environment.ps1
# PowerShell環境診断スクリプト

Write-Host "=== PowerShell Environment Diagnostics ===" -ForegroundColor Cyan
Write-Host ""

# 1. PowerShell Version
Write-Host "1. PowerShell Version:" -ForegroundColor Yellow
Write-Host "   Edition: $($PSVersionTable.PSEdition)"
Write-Host "   Version: $($PSVersionTable.PSVersion)"
Write-Host "   OS: $($PSVersionTable.OS)"
Write-Host "   Platform: $($PSVersionTable.Platform)"
Write-Host ""

# 2. Encoding Settings
Write-Host "2. Character Encoding:" -ForegroundColor Yellow
Write-Host "   Console Output Encoding: $([System.Console]::OutputEncoding.EncodingName) (CP$([System.Console]::OutputEncoding.CodePage))"
Write-Host "   Console Input Encoding: $([System.Console]::InputEncoding.EncodingName) (CP$([System.Console]::InputEncoding.CodePage))"
Write-Host "   Default Parameter Encoding: $($PSDefaultParameterValues['*:Encoding'])"

# Code Page
$codePage = (chcp.com 2>$null) -replace '.*:\s*(\d+).*', '$1'
Write-Host "   Active Code Page: $codePage"
Write-Host ""

# 3. Culture and Locale
Write-Host "3. Culture Settings:" -ForegroundColor Yellow
$culture = Get-Culture
Write-Host "   Current Culture: $($culture.Name) - $($culture.DisplayName)"
Write-Host "   Current UI Culture: $((Get-UICulture).Name)"

try {
    $sysLocale = Get-WinSystemLocale
    Write-Host "   System Locale: $($sysLocale.Name) - $($sysLocale.DisplayName)"
} catch {
    Write-Host "   System Locale: Unable to determine" -ForegroundColor Gray
}
Write-Host ""

# 4. Console/Terminal Detection
Write-Host "4. Terminal Environment:" -ForegroundColor Yellow
if ($env:WT_SESSION) {
    Write-Host "   Windows Terminal: Yes (Session: $env:WT_SESSION)" -ForegroundColor Green
} else {
    Write-Host "   Windows Terminal: No" -ForegroundColor Gray
}

if ($env:TERM_PROGRAM) {
    Write-Host "   Terminal Program: $env:TERM_PROGRAM"
}

Write-Host "   Console Host: $($Host.Name)"
Write-Host "   Console Width: $($Host.UI.RawUI.WindowSize.Width)"
Write-Host ""

# 5. Execution Policy
Write-Host "5. Execution Policy:" -ForegroundColor Yellow
$policies = Get-ExecutionPolicy -List
foreach ($policy in $policies) {
    $color = if ($policy.ExecutionPolicy -eq 'Restricted') { 'Red' } 
             elseif ($policy.ExecutionPolicy -eq 'Undefined') { 'Gray' }
             else { 'Green' }
    Write-Host ("   {0,-20} : {1}" -f $policy.Scope, $policy.ExecutionPolicy) -ForegroundColor $color
}
Write-Host ""

# 6. File System Check
Write-Host "6. Script File Analysis:" -ForegroundColor Yellow
$scriptPath = Join-Path $PSScriptRoot "Create-MinimalUbuntuWSL.ps1"
if (Test-Path $scriptPath) {
    # File attributes
    $file = Get-Item $scriptPath
    Write-Host "   File exists: Yes"
    Write-Host "   File size: $($file.Length) bytes"
    Write-Host "   Last modified: $($file.LastWriteTime)"
    
    # Check for Zone.Identifier
    try {
        $zone = Get-Content "$scriptPath:Zone.Identifier" -ErrorAction SilentlyContinue
        if ($zone) {
            Write-Host "   Zone Identifier: Present (file may be blocked)" -ForegroundColor Yellow
            Write-Host "   Zone ID: $($zone | Select-String 'ZoneId=(\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })"
        } else {
            Write-Host "   Zone Identifier: None" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Zone Identifier: None" -ForegroundColor Green
    }
    
    # Check encoding (simple detection)
    $bytes = [System.IO.File]::ReadAllBytes($scriptPath) | Select-Object -First 3
    if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "   File encoding: UTF-8 with BOM" -ForegroundColor Yellow
    } else {
        Write-Host "   File encoding: UTF-8 without BOM (or other)" -ForegroundColor Green
    }
    
    # Line ending check
    $content = [System.IO.File]::ReadAllText($scriptPath)
    $crlfCount = ([regex]::Matches($content, "`r`n")).Count
    $lfCount = ([regex]::Matches($content, "(?<!`r)`n")).Count
    
    if ($crlfCount -gt 0 -and $lfCount -eq 0) {
        Write-Host "   Line endings: CRLF (Windows)"
    } elseif ($lfCount -gt 0 -and $crlfCount -eq 0) {
        Write-Host "   Line endings: LF (Unix)"
    } else {
        Write-Host "   Line endings: Mixed" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Create-MinimalUbuntuWSL.ps1 not found in current directory" -ForegroundColor Red
}
Write-Host ""

# 7. Git Configuration
Write-Host "7. Git Configuration:" -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Git installed: Yes ($gitVersion)"
        Write-Host "   core.autocrlf: $(git config core.autocrlf)"
        Write-Host "   core.eol: $(git config core.eol)"
    } else {
        Write-Host "   Git installed: No" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Git installed: No or not in PATH" -ForegroundColor Gray
}
Write-Host ""

# 8. Recommendations
Write-Host "8. Recommendations:" -ForegroundColor Cyan
$issues = @()

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $issues += "- Consider upgrading to PowerShell 7.x for better UTF-8 support"
}

# Check encoding
if ([System.Console]::OutputEncoding.CodePage -ne 65001) {
    $issues += "- Set UTF-8 encoding: [Console]::OutputEncoding = [Text.Encoding]::UTF8"
}

# Check execution policy
$currentPolicy = (Get-ExecutionPolicy -Scope Process).ToString()
if ($currentPolicy -eq 'Restricted') {
    $issues += "- Set execution policy: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process"
}

# Check Windows Terminal
if (-not $env:WT_SESSION) {
    $issues += "- Use Windows Terminal for better Unicode support"
}

if ($issues.Count -gt 0) {
    Write-Host "   Issues found:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
} else {
    Write-Host "   Environment looks good!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Diagnostics Complete ===" -ForegroundColor Cyan