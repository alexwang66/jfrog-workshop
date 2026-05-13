param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Mask-Secret {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value.Length -le 4) {
        return ("*" * $Value.Length)
    }

    $prefix = $Value.Substring(0, [Math]::Min(4, $Value.Length))
    $suffix = $Value.Substring($Value.Length - 2, 2)
    return "$prefix***$suffix"
}

$resolvedPath = Resolve-Path -LiteralPath $EnvFile
$pairs = [ordered]@{}

Get-Content -LiteralPath $resolvedPath | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }
    if ($line.StartsWith("#")) { return }

    $parts = $line -split "=", 2
    if ($parts.Count -ne 2) { return }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    $pairs[$key] = $value
}

if ($pairs.Count -eq 0) {
    throw "No key/value pairs found in $resolvedPath"
}

Write-Host "Demo file: $resolvedPath"
Write-Host "This script reads only the provided mock file. It does not inspect real environment variables or send data over the network."
Write-Host ""
Write-Host "Detected mock credentials:"

$masked = [ordered]@{}
foreach ($entry in $pairs.GetEnumerator()) {
    $maskedValue = Mask-Secret -Value $entry.Value
    $masked[$entry.Key] = $maskedValue
    Write-Host ("- {0} = {1}" -f $entry.Key, $maskedValue)
}

$payload = [ordered]@{
    demo = $true
    source = "local-.env.demo"
    intent = "security-awareness-simulation"
    collected_keys = @($pairs.Keys)
    masked_values = $masked
}

Write-Host ""
Write-Host "Simulated attacker payload (local only):"
$payload | ConvertTo-Json -Depth 4
Write-Host ""
Write-Host "No transmission performed. This is a safe, local-only demonstration."
