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

function ConvertTo-RepoVars {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Repo
    )

    $repoType = [string]$Repo.rclass
    $xrayEnable = ([string]$Repo.xrayIndex).ToLowerInvariant()

    $parts = @(
        "repo-name=$($Repo.key)",
        "package-type=$($Repo.packageType)",
        "repo-type=$repoType",
        "repo-layout=$($Repo.repoLayoutRef)",
        "xray-enable=$xrayEnable"
    )

    if ($repoType -eq "remote") {
        $parts += "repo-url=$($Repo.url)"
    }
    elseif ($repoType -eq "virtual") {
        $parts += "deploy-repo-name=$($Repo.defaultDeploymentRepo)"
        $parts += "external-remote-repo-name=$($Repo.externalDependenciesRemoteRepo)"
        $parts += "repos=$($Repo.repositories)"
    }

    return ($parts -join ";")
}

function New-Repositories {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFile,

        [Parameter(Mandatory = $true)]
        [string]$ValuesFile
    )

    $repos = Get-Content -LiteralPath $ValuesFile -Raw | ConvertFrom-Json

    foreach ($repo in $repos) {
        $vars = ConvertTo-RepoVars -Repo $repo
        if ([string]::IsNullOrWhiteSpace($vars)) {
            continue
        }

        Write-Host "Creating repository: $($repo.key)"
        & jf rt repo-create $TemplateFile --vars $vars
    }
}

Test-JFrogCli

switch ($RepoKind) {
    "all" {
        New-Repositories "$ScriptDir\local-repo-template.json" "$ScriptDir\local-repo-values.json"
        New-Repositories "$ScriptDir\remote-repo-template.json" "$ScriptDir\remote-repo-values.json"
        New-Repositories "$ScriptDir\virtual-repo-template.json" "$ScriptDir\virtual-repo-values.json"
    }
    "local" {
        New-Repositories "$ScriptDir\local-repo-template.json" "$ScriptDir\local-repo-values.json"
    }
    "remote" {
        New-Repositories "$ScriptDir\remote-repo-template.json" "$ScriptDir\remote-repo-values.json"
    }
    "virtual" {
        New-Repositories "$ScriptDir\virtual-repo-template.json" "$ScriptDir\virtual-repo-values.json"
    }
}
