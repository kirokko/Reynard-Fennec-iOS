# Bounded, one-shot delivery for an already manually started build.
# Never starts/retries builds, updates apps, or follows future upstream releases.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][long]$RunId,
    [string]$Repository = 'kirokko/Reynard-Fennec-iOS',
    [int]$MaximumMinutes = 420,
    [string]$Destination = (Join-Path $env:USERPROFILE 'Downloads\Reynard-Fennec.ipa'),
    [string]$StatusFile = (Join-Path $env:USERPROFILE 'Downloads\Reynard-Fennec-build-status.txt')
)
$ErrorActionPreference = 'Stop'
$url = "https://github.com/$Repository/actions/runs/$RunId"
function Write-Status([string]$Message) {
    @("Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')", "Run: $url", $Message,
      'Experimental source changes; successful packaging is not proof of device compatibility.') |
        Set-Content -LiteralPath $StatusFile -Encoding UTF8
}
try {
    if ($MaximumMinutes -le 0) { throw 'MaximumMinutes must be positive.' }
    $deadline = (Get-Date).AddMinutes($MaximumMinutes)
    $networkErrors = 0
    Write-Status 'Waiting for the manually requested cloud build. No IPA exists yet.'
    while ((Get-Date) -lt $deadline) {
        $savedErrorPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $json = & gh run view $RunId --repo $Repository --json status,conclusion,jobs 2>$null
        $queryExitCode = $LASTEXITCODE
        $ErrorActionPreference = $savedErrorPreference
        if ($queryExitCode -ne 0) {
            $networkErrors++
            Write-Status "Could not query GitHub (attempt $networkErrors). Will retry; no artifact downloaded."
            if ($networkErrors -ge 10) { throw 'Stopped after 10 consecutive network/authentication errors. Download manually later.' }
            Start-Sleep -Seconds 60
            continue
        }
        $networkErrors = 0
        $run = $json | ConvertFrom-Json
        if ($run.status -eq 'completed') {
            if ($run.conclusion -ne 'success') {
                Write-Status "BUILD DID NOT SUCCEED: $($run.conclusion). No IPA downloaded. See the run URL for error logs."
                exit 1
            }
            Write-Status 'BUILD SUCCEEDED. Downloading and checking the IPA structure now.'
            & (Join-Path $PSScriptRoot 'Download-IPA.ps1') -Repository $Repository -RunId $RunId -Destination $Destination
            Write-Status "DOWNLOADED: $Destination`r`nBuild URL, commit and SHA256 are saved beside the IPA. Keep App Extensions in SideStore."
            exit 0
        }
        $active = @($run.jobs | ForEach-Object { $_.steps } | Where-Object { $_.status -eq 'in_progress' } | ForEach-Object { $_.name })
        Write-Status "BUILD $($run.status): $($active -join ', '). No IPA exists yet."
        Start-Sleep -Seconds 60
    }
    throw 'The one-shot watcher timed out. It did not cancel the cloud build. Check the run URL and download manually later.'
} catch {
    Write-Status "DELIVERY STOPPED: $($_.Exception.Message)"
    exit 1
}
