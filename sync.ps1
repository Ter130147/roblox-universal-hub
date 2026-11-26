
param([string]$Message = "chore: sync roblox-universal-hub")

Set-Location "$env:USERPROFILE\Desktop\roblox-universal-hub"

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($file in @("standalone.lua", "loader.lua", "README.md")) {

if (Test-Path "$PWD$file") {

$raw = [System.IO.File]::ReadAllText("$PWD$file")

[System.IO.File]::WriteAllText("$PWD$file", $raw, $Utf8NoBom)

}

}

$MainCode = [System.IO.File]::ReadAllText("$PWD\standalone.lua")

Set-Clipboard -Value $MainCode

git add standalone.lua loader.lua README.md

git commit -m $Message

git push -u origin main --force-with-lease

Write-Host "Synced standalone.lua, loader.lua, and README.md -> clipboard & origin/main" -ForegroundColor Green
