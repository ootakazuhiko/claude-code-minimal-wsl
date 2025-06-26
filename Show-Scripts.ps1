# Show-Scripts.ps1
# Display available scripts in the repository

Write-Host "`n=== Available Scripts ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Main Script:" -ForegroundColor Yellow
Write-Host "  .\Create-MinimalUbuntuWSL.ps1    - Create minimal Ubuntu WSL instances"
Write-Host ""

Write-Host "Setup Scripts:" -ForegroundColor Yellow
Get-ChildItem -Path "scripts\setup\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  .\scripts\setup\$($_.Name)"
}
Get-ChildItem -Path "scripts\setup\*.sh" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  .\scripts\setup\$($_.Name)"
}
Write-Host ""

Write-Host "Utility Scripts:" -ForegroundColor Yellow
Get-ChildItem -Path "scripts\utility\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  .\scripts\utility\$($_.Name)"
}
Write-Host ""

Write-Host "Debug Scripts:" -ForegroundColor Yellow
Get-ChildItem -Path "scripts\debug\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  .\scripts\debug\$($_.Name)"
}
Write-Host ""

Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  README.md                        - Main documentation"
Write-Host "  CLAUDE.md                        - Claude Code instructions"
Write-Host "  docs\TROUBLESHOOTING.md          - Troubleshooting guide"
Write-Host "  docs\USAGE.md                    - Usage examples"
Write-Host "  docs\CONTRIBUTING.md             - Contribution guidelines"
Write-Host ""

Write-Host "For help with the main script, run:" -ForegroundColor Green
Write-Host "  .\Create-MinimalUbuntuWSL.ps1 -Action Info"
Write-Host ""