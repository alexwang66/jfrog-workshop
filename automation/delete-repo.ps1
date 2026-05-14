param(
    [Parameter(Mandatory = $true)]
    [string]$StudentId,

    [ValidateSet("all", "local", "remote", "virtual")]
    [string]$RepoKind = "all"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Format-StudentId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Trim().ToLowerInvariant()
    if ($normalized -notmatch '^[a-z0-9](?:[a-z0-9-]{1,18}[a-z0-9])$') {
        throw "Invalid StudentId '$Value'. Use 3-20 lowercase letters, numbers, and hyphens only. Examples: alex, mary-chen, john2."
    }

    return $normalized
}

function ConvertTo-StudentRepoName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoKey,

        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    $baseName = $RepoKey -replace '^workshop-', ''
    return "$Prefix-$baseName"
}

function Test-JFrogCli {
    if (-not (Get-Command jf -ErrorAction SilentlyContinue)) {
        throw "JFrog CLI 'jf' was not found in PATH. Install JFrog CLI and open a new PowerShell window."
    }
}

function Remove-Repositories {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValuesFile,

        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    $repos = Get-Content -LiteralPath $ValuesFile -Raw | ConvertFrom-Json

    foreach ($repo in $repos) {
        if ([string]::IsNullOrWhiteSpace($repo.key)) {
            continue
        }

        $repoName = ConvertTo-StudentRepoName -RepoKey $repo.key -Prefix $Prefix
        Write-Host "Deleting repository: $repoName"
        & jf rt repo-delete $repoName --quiet
    }
}

Test-JFrogCli
$StudentPrefix = Format-StudentId -Value $StudentId

switch ($RepoKind) {
    "all" {
        Remove-Repositories "$ScriptDir\virtual-repo-values.json" -Prefix $StudentPrefix
        Remove-Repositories "$ScriptDir\remote-repo-values.json" -Prefix $StudentPrefix
        Remove-Repositories "$ScriptDir\local-repo-values.json" -Prefix $StudentPrefix
    }
    "local" {
        Remove-Repositories "$ScriptDir\local-repo-values.json" -Prefix $StudentPrefix
    }
    "remote" {
        Remove-Repositories "$ScriptDir\remote-repo-values.json" -Prefix $StudentPrefix
    }
    "virtual" {
        Remove-Repositories "$ScriptDir\virtual-repo-values.json" -Prefix $StudentPrefix
    }
}
