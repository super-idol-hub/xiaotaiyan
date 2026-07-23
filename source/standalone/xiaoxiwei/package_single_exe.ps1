param()

$ErrorActionPreference = 'Stop'

function Decode-Utf8Base64([string]$Value) {
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$exeName = Decode-Utf8Base64 '5bCP5rOw5aaNLmV4ZQ=='
$deliveryName = Decode-Utf8Base64 '5bCP5rOw5aaNLeWPjOearuiCpOWNlUVYReeJiA=='
$deliveryZipName = Decode-Utf8Base64 '5bCP5rOw5aaNLeWPjOearuiCpOWNlUVYReeJiC56aXA='
$readmeName = Decode-Utf8Base64 '5L2/55So6K+05piOLm1k'
$readmeBase64 = 'IyDlsI/ms7Dlpo3vvZxXZWVrZW5kICsgSU5WVSDlj4zlhoXnva7nmq7ogqQKCuacrOebruW9leWPquWMheWQq+S4gOS4quWPr+aJp+ihjOeoi+W6j++8mmDlsI/ms7Dlpo0uZXhlYOOAgldlZWtlbmQg5LiOIElOVlUg5Lik5aWX5a6M5pW055qu6IKk5Z2H5bey57yW6K+R6L+b6L+Z5LiqIEVYRe+8jOS4zemcgOimgSBgc2tpbnNgIOaWh+S7tuWkue+8jOS5n+S4jemcgOimgeesrOS6jOS4qiBFWEXjgIIKCuS9v+eUqOaWueazle+8mgoKMS4g5Y+M5Ye7IGDlsI/ms7Dlpo0uZXhlYOOAggoyLiDlj7PplK7moYzpnaLop5LoibLjgIIKMy4g5omT5byA4oCc55qu6IKk4oCd44CCCjQuIOmAieaLqeKAnFdlZWtlbmQg57KJ6JOd5ZGo5pyr77yI5YaF572u77yJ4oCd5oiW4oCcSU5WVSDmnIjlvbHlpbPnpZ7vvIjlhoXnva7vvInigJ3jgIIKCuWIh+aNouaXtuS8muaSreaUvuS6uueJqeaXi+i6q+WSjOeUseWktOWIsOiEmueahOaNouijheWKqOeUu++8m+W9k+WJjemAieaLqeS8muWcqOS4i+asoeWQr+WKqOaXtuaBouWkjeOAggoK5Y+z6ZSu6I+c5Y2V4oCc56uL5Y2z5qOA5p+l5YWs5byA5Yqo5oCB4oCd5LiL6Z2i5o+Q5L6b4oCc5byA5py66Ieq5ZCv4oCd5byA5YWz77yM5LuF5YaZ5YWl5b2T5YmNIFdpbmRvd3Mg55So5oi355qE5ZCv5Yqo6aG544CCCgrniYjmnKzvvJoxLjEuMSAgCuW8gOWPkeiAhe+8muS4quS6uumdnuWVhuS4muW8gOWPkQoK5pys56iL5bqP5Li66Z2e5a6Y5pa544CB6Z2e5ZWG5Lia57KJ5Lid5L2c5ZOB44CC56aB5q2i5ZSu5Y2W44CB5pS26LS55YiG5Y+R44CB5ZWG5Lia5o6o5bm/5oiW5YaS55So5a6Y5pa55ZCN5LmJ44CCDQo='
$readmeBase64 = $readmeBase64.Replace('OS4zemcg', 'OS4jemcg')

$project = $PSScriptRoot
$workspace = (Resolve-Path (Join-Path $project '..\..')).Path
$builtDirectory = Join-Path $workspace 'outputs\taeyeon-two-skins-one-exe'
$builtExe = Join-Path $builtDirectory $exeName
$selfTestReport = Join-Path $builtDirectory 'self-test-report.json'
$deliveryDirectory = Join-Path $workspace $deliveryName
$deliveryExe = Join-Path $deliveryDirectory $exeName
$deliveryReadme = Join-Path $deliveryDirectory $readmeName
$deliverySums = Join-Path $deliveryDirectory 'SHA256SUMS.txt'
$deliveryZip = Join-Path $workspace $deliveryZipName

if (-not (Test-Path -LiteralPath $builtExe)) {
    throw "Built executable not found: $builtExe"
}
if (-not (Test-Path -LiteralPath $selfTestReport)) {
    throw "Self-test report not found: $selfTestReport"
}

$selfTest = Get-Content -Raw -Encoding UTF8 -LiteralPath $selfTestReport | ConvertFrom-Json
if (-not $selfTest.ok `
    -or $selfTest.embeddedSkinCount -ne 2 `
    -or -not $selfTest.embeddedSkinCatalogValid `
    -or -not $selfTest.skinTransitionRenderValid) {
    throw 'The two-embedded-skin self-test has not passed.'
}

New-Item -ItemType Directory -Force -Path $deliveryDirectory | Out-Null
Copy-Item -LiteralPath $builtExe -Destination $deliveryExe -Force
Set-Content -LiteralPath $deliveryReadme -Value (Decode-Utf8Base64 $readmeBase64) -Encoding UTF8

$exeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $deliveryExe).Hash.ToLowerInvariant()
Set-Content -LiteralPath $deliverySums -Value ("{0}  {1}" -f $exeHash, $exeName) -Encoding ASCII

$temporaryZip = $deliveryZip + '.tmp.zip'
if (Test-Path -LiteralPath $temporaryZip) {
    Remove-Item -LiteralPath $temporaryZip -Force
}
Compress-Archive -LiteralPath @($deliveryExe, $deliveryReadme, $deliverySums) -DestinationPath $temporaryZip -CompressionLevel Optimal
Move-Item -LiteralPath $temporaryZip -Destination $deliveryZip -Force

$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $deliveryZip).Hash.ToLowerInvariant()
[pscustomobject]@{
    executable = $deliveryExe
    executableBytes = (Get-Item -LiteralPath $deliveryExe).Length
    executableSha256 = $exeHash
    archive = $deliveryZip
    archiveBytes = (Get-Item -LiteralPath $deliveryZip).Length
    archiveSha256 = $zipHash
    embeddedSkinCount = [int]$selfTest.embeddedSkinCount
    embeddedSkinIds = @($selfTest.embeddedSkinIds)
    selfTestOk = [bool]$selfTest.ok
    skinTransitionRenderValid = [bool]$selfTest.skinTransitionRenderValid
} | ConvertTo-Json -Depth 4
