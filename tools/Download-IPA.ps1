# Manual download only; does not start a build or update any installed app.
[CmdletBinding()]
param(
    [string]$Repository = 'kirokko/Reynard-Fennec-iOS',
    [long]$RunId = 0,
    [string]$Destination = (Join-Path $env:USERPROFILE 'Downloads\Reynard-Fennec.ipa')
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install it and run gh auth login.'
}
if ($RunId -gt 0) {
    $json = & gh run view $RunId --repo $Repository --json databaseId,headSha,url,status,conclusion
    if ($LASTEXITCODE -ne 0) { throw 'Could not query the requested GitHub Actions run.' }
    $run = $json | ConvertFrom-Json
    if ($run.status -ne 'completed' -or $run.conclusion -ne 'success') {
        throw 'The requested run has not completed successfully. No IPA has been downloaded.'
    }
} else {
    $json = & gh run list --repo $Repository --workflow build-sidestore.yml --status success --limit 1 --json databaseId,headSha,url
    if ($LASTEXITCODE -ne 0) { throw 'Could not query GitHub Actions. Check gh auth status and network access.' }
    $runs = $json | ConvertFrom-Json
    if (-not $runs) {
        throw 'No successful build exists yet. Wait for the cloud build or inspect its failure log; no IPA has been downloaded.'
    }
    $run = $runs[0]
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('reynard-fennec-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    & gh run download $run.databaseId --repo $Repository --name Reynard-Fennec-SideStore --dir $temp
    if ($LASTEXITCODE -ne 0) { throw 'Artifact download failed. It may have expired or the connection may be unavailable.' }
    $ipa = Join-Path $temp 'Reynard.ipa'
    if (-not (Test-Path -LiteralPath $ipa -PathType Leaf)) { throw 'The expected IPA was not present in the artifact.' }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($ipa)
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName })
        if ($entries -notcontains 'Payload/Reynard.app/Info.plist') { throw 'Invalid IPA: missing the app Info.plist.' }
        if (-not ($entries | Where-Object { $_ -match '^Payload/Reynard\.app/PlugIns/.+\.appex/Info\.plist$' })) {
            throw 'Invalid IPA: required app extensions are missing.'
        }
    } finally { $archive.Dispose() }
    $parent = Split-Path -Parent $Destination
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $ipa -Destination $Destination -Force
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash
    @("Repository: $Repository", "Run: $($run.url)", "Commit: $($run.headSha)", "SHA256: $hash", 'This is a development build. Device testing is still required.') |
        Set-Content -LiteralPath ($Destination + '.build.txt') -Encoding UTF8
    Write-Host "Saved: $Destination"
    Write-Host "SHA256: $hash"
    Write-Host 'Keep App Extensions when installing in SideStore. Installation does not automatically enable JIT.'
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
