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

function Test-JFrogCli {
    if (-not (Get-Command jf -ErrorAction SilentlyContinue)) {
        throw "JFrog CLI 'jf' was not found in PATH. Install JFrog CLI and open a new PowerShell window."
    }
}

function ConvertTo-RepoVars {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Repo,

        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    $repoType = [string]$Repo.rclass
    $xrayEnable = ([string]$Repo.xrayIndex).ToLowerInvariant()
    $repoName = ConvertTo-StudentRepoName -RepoKey $Repo.key -Prefix $Prefix

    $parts = @(
        "repo-name=$repoName",
        "package-type=$($Repo.packageType)",
        "repo-type=$repoType",
        "repo-layout=$($Repo.repoLayoutRef)",
        "xray-enable=$xrayEnable"
    )

    if ($repoType -eq "remote") {
        $parts += "repo-url=$($Repo.url)"
    }
    elseif ($repoType -eq "virtual") {
        $parts += "deploy-repo-name=$(ConvertTo-StudentRepoName -RepoKey $Repo.defaultDeploymentRepo -Prefix $Prefix)"
        $parts += "external-remote-repo-name=$(ConvertTo-StudentRepoName -RepoKey $Repo.externalDependenciesRemoteRepo -Prefix $Prefix)"
        $repos = ([string]$Repo.repositories).Split(",") | ForEach-Object {
            ConvertTo-StudentRepoName -RepoKey $_.Trim() -Prefix $Prefix
        }
        $parts += "repos=$($repos -join ',')"
    }

    return ($parts -join ";")
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

function New-Repositories {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateFile,

        [Parameter(Mandatory = $true)]
        [string]$ValuesFile,

        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )

    $repos = Get-Content -LiteralPath $ValuesFile -Raw | ConvertFrom-Json

    foreach ($repo in $repos) {
        $vars = ConvertTo-RepoVars -Repo $repo -Prefix $Prefix
        if ([string]::IsNullOrWhiteSpace($vars)) {
            continue
        }

        Write-Host "Creating repository: $(ConvertTo-StudentRepoName -RepoKey $repo.key -Prefix $Prefix)"
        & jf rt repo-create $TemplateFile --vars $vars
    }
}

Test-JFrogCli
$StudentPrefix = Format-StudentId -Value $StudentId

switch ($RepoKind) {
    "all" {
        New-Repositories "$ScriptDir\local-repo-template.json" "$ScriptDir\local-repo-values.json" -Prefix $StudentPrefix
        New-Repositories "$ScriptDir\remote-repo-template.json" "$ScriptDir\remote-repo-values.json" -Prefix $StudentPrefix
        New-Repositories "$ScriptDir\virtual-repo-template.json" "$ScriptDir\virtual-repo-values.json" -Prefix $StudentPrefix
    }
    "local" {
        New-Repositories "$ScriptDir\local-repo-template.json" "$ScriptDir\local-repo-values.json" -Prefix $StudentPrefix
    }
    "remote" {
        New-Repositories "$ScriptDir\remote-repo-template.json" "$ScriptDir\remote-repo-values.json" -Prefix $StudentPrefix
    }
    "virtual" {
        New-Repositories "$ScriptDir\virtual-repo-template.json" "$ScriptDir\virtual-repo-values.json" -Prefix $StudentPrefix
    }
}
