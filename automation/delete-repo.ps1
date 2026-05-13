param(
    [ValidateSet("all", "local", "remote", "virtual")]
    [string]$RepoKind = "all"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-JFrogCli {
    if (-not (Get-Command jf -ErrorAction SilentlyContinue)) {
        throw "JFrog CLI 'jf' was not found in PATH. Install JFrog CLI and open a new PowerShell window."
    }
}

function Remove-Repositories {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValuesFile
    )

    $repos = Get-Content -LiteralPath $ValuesFile -Raw | ConvertFrom-Json

    foreach ($repo in $repos) {
        if ([string]::IsNullOrWhiteSpace($repo.key)) {
            continue
        }

        Write-Host "Deleting repository: $($repo.key)"
        & jf rt repo-delete $repo.key --quiet
    }
}

Test-JFrogCli

switch ($RepoKind) {
    "all" {
        Remove-Repositories "$ScriptDir\virtual-repo-values.json"
        Remove-Repositories "$ScriptDir\remote-repo-values.json"
        Remove-Repositories "$ScriptDir\local-repo-values.json"
    }
    "local" {
        Remove-Repositories "$ScriptDir\local-repo-values.json"
    }
    "remote" {
        Remove-Repositories "$ScriptDir\remote-repo-values.json"
    }
    "virtual" {
        Remove-Repositories "$ScriptDir\virtual-repo-values.json"
    }
}
