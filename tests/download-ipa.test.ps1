# Isolated Windows PowerShell test. No GitHub requests, credentials or real IPAs.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$script:root = Join-Path ([IO.Path]::GetTempPath()) ('reynard-download-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $script:root | Out-Null
$global:ReynardDownloadTestScenario = 'success'
$script:passed = 0
function gh {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $global:LASTEXITCODE = 0
    if ($Arguments[0] -ne 'run') { throw 'Unexpected mock command' }
    switch ($Arguments[1]) {
        'view' {
            $conclusion = if ($global:ReynardDownloadTestScenario -eq 'failed-run') { 'failure' } else { 'success' }
            return (@{ databaseId = 42; headSha = 'fixture'; url = 'https://example.invalid/run/42'; status = 'completed'; conclusion = $conclusion } | ConvertTo-Json -Compress)
        }
        'list' { return '[]' }
        'download' {
            $dirIndex = [Array]::IndexOf($Arguments, '--dir')
            $file = Join-Path $Arguments[$dirIndex + 1] 'Reynard.ipa'
            $zip = [IO.Compression.ZipFile]::Open($file, [IO.Compression.ZipArchiveMode]::Create)
            try {
                $null = $zip.CreateEntry('Payload/Reynard.app/Info.plist')
                if ($global:ReynardDownloadTestScenario -ne 'missing-extensions') { $null = $zip.CreateEntry('Payload/Reynard.app/PlugIns/Reynard Helper.appex/Info.plist') }
            } finally { $zip.Dispose() }
        }
        default { throw 'Unexpected mock subcommand' }
    }
}
try {
    $downloader = Join-Path $PSScriptRoot '..\tools\Download-IPA.ps1'
    foreach ($scenario in @('success', 'failed-run', 'missing-extensions', 'no-successful-run')) {
        $global:ReynardDownloadTestScenario = $scenario
        $destination = Join-Path $script:root ($scenario + '.ipa')
        $caught = $false
        try {
            $id = if ($scenario -eq 'no-successful-run') { 0 } else { 42 }
            & $downloader -RunId $id -Destination $destination
        } catch {
            $caught = $true
            if ($scenario -eq 'success') { throw }
        }
        if ($scenario -eq 'success') {
            if ($caught -or -not (Test-Path $destination) -or -not (Test-Path ($destination + '.build.txt'))) { throw 'Successful mock artifact was not saved.' }
        } else {
            if (-not $caught -or (Test-Path $destination)) { throw "Unsafe download behavior in scenario: $scenario" }
        }
        $script:passed++
        Write-Host "PASS: $scenario"
    }
    Write-Host "All $script:passed isolated artifact tests passed."
} finally {
    Remove-Variable -Name ReynardDownloadTestScenario -Scope Global -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
}
