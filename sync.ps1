param([string]$Message = "chore: sync standalone.lua")
Set-Location "$env:USERPROFILE\Desktop\roblox-universal-hub"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Content = [System.IO.File]::ReadAllText("$PWD\standalone.lua")
[System.IO.File]::WriteAllText("$PWD\standalone.lua", $Content, $Utf8NoBom)
Set-Clipboard -Value $Content
git add standalone.lua
git commit -m $Message
git push -u origin main --force-with-lease
Write-Host "Synced standalone.lua -> clipboard & origin/main" -ForegroundColor Green