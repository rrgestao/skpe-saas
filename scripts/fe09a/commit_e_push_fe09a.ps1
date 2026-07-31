[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoPath = (Get-Location).Path,

    [Parameter(Mandatory = $true)]
    [switch]$ArquiteturaValidada,

    [Parameter(Mandatory = $false)]
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedBranch = 'feature/formulacao-estrategica-operacional'
$ExpectedBaseCommit = '0fd801bfe076c07fd6f06ac2aea94a8aa094115f'
$CommitMessage = 'docs: define fundacao aplicacional da formulacao estrategica'
$RepoRoot = (Resolve-Path -LiteralPath $RepoPath).Path
$AllowListPath = Join-Path $RepoRoot 'scripts/fe09a/LISTA_BRANCA_FE09A.txt'

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $output = & git -C $RepoRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no Git: git -C `"$RepoRoot`" $($Arguments -join ' ')`n$output"
    }
    return $output
}

function Normalize-PathValue {
    param([Parameter(Mandatory = $true)][string]$Value)
    return ($Value -replace '\\', '/').Trim()
}

if (-not $ArquiteturaValidada) {
    throw 'Confirme explicitamente -ArquiteturaValidada.'
}
if (-not (Test-Path -LiteralPath $AllowListPath)) {
    throw 'Lista branca FE-09.A não encontrada.'
}

$CurrentBranch = (Invoke-Git -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') | Select-Object -First 1).Trim()
$CurrentCommit = (Invoke-Git -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()

if ($CurrentBranch -ne $ExpectedBranch) {
    throw "Branch incorreta. Esperada: $ExpectedBranch. Atual: $CurrentBranch"
}
if ($CurrentCommit -ne $ExpectedBaseCommit) {
    throw "HEAD diferente do commit-base. Esperado: $ExpectedBaseCommit. Atual: $CurrentCommit"
}

$AllowList = Get-Content -LiteralPath $AllowListPath |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$StagedPaths = @(Invoke-Git -Arguments @('diff', '--cached', '--name-only')) |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($StagedPaths.Count -eq 0) {
    throw 'Não há arquivos staged. Execute validar_fe09a_planejamento.ps1.'
}

$UnexpectedStaged = $StagedPaths | Where-Object { $AllowList -notcontains $_ }
if (@($UnexpectedStaged).Count -gt 0) {
    throw "Staging contém arquivo fora da lista branca:`n$($UnexpectedStaged -join [Environment]::NewLine)"
}

& git -C $RepoRoot --no-pager diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'git diff --cached --check falhou.'
}

Invoke-Git -Arguments @('commit', '-m', $CommitMessage) | ForEach-Object { Write-Host $_ }
$NewCommit = (Invoke-Git -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
Write-Host "Commit criado: $NewCommit"

if ($Push) {
    Invoke-Git -Arguments @('push', 'origin', $ExpectedBranch) | ForEach-Object { Write-Host $_ }
    $RemoteLine = Invoke-Git -Arguments @('ls-remote', 'origin', "refs/heads/$ExpectedBranch") | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($RemoteLine)) {
        throw 'Não foi possível confirmar o SHA remoto.'
    }
    $RemoteCommit = ($RemoteLine -split '\s+')[0].Trim()
    if ($RemoteCommit -ne $NewCommit) {
        throw "SHA local e remoto divergentes. Local: $NewCommit. Remoto: $RemoteCommit"
    }
    Write-Host "Push confirmado: $NewCommit"
} else {
    Write-Host 'Push não executado.'
}

Write-Host 'Nenhum merge em develop ou main foi realizado.'
