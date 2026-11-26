param(
[Parameter(Mandatory = $false)]
[ValidateSet("gen", "reset")]
[string]$Action = "gen",

[Parameter(Mandatory = $false)]
[double]$Days = 1,

[Parameter(Mandatory = $false)]
[string]$Key = "",

[Parameter(Mandatory = $false)]
[string]$Secret = "TER-ADMIN-2700"
)

$BaseUrl = "https://ter-key-api.copter2700.workers.dev"

if ($Action -eq "gen") {
$url = "$BaseUrl/generate?secret=$([uri]::EscapeDataString($Secret))&days=$Days"
$res = Invoke-RestMethod -Uri $url -Method Get
if ($res.ok) {
Set-Clipboard -Value $res.key
Write-Host "Generated Key: $($res.key) | Days: $($res.days) (Copied to Clipboard)" -ForegroundColor Green
} else {
Write-Host "Failed: $($res.message)" -ForegroundColor Red
}
} elseif ($Action -eq "reset") {
if ([string]::IsNullOrWhiteSpace($Key)) {
Write-Host "Please specify -Key TER-XXXX-XXXX-XXXX" -ForegroundColor Yellow
exit 1
}
$url = "$BaseUrl/reset?secret=$([uri]::EscapeDataString($Secret))&key=$([uri]::EscapeDataString($Key.Trim().ToUpper()))"
$res = Invoke-RestMethod -Uri $url -Method Get
if ($res.ok) {
Write-Host "Reset HWID success for key: $($res.key)" -ForegroundColor Green
} else {
Write-Host "Failed: $($res.message)" -ForegroundColor Red
}
}