[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoPath = (Get-Location).Path,

    [Parameter(Mandatory = $true)]
    [switch]$SupabaseValidado,

    [Parameter(Mandatory = $false)]
    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedBranch = 'feature/formulacao-estrategica-operacional'
$ExpectedBaseCommit = 'db4eaa4a4c2db42384823b6f621e730d2a2d4b4c'
$CommitMessage = 'feat: adiciona monitoramento governanca e aprendizado estrategico'
$RepoRoot = (Resolve-Path -LiteralPath $RepoPath).Path
$AllowListPath = Join-Path $RepoRoot 'scripts/fe08/LISTA_BRANCA_FE08.txt'

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

if (-not $SupabaseValidado) {
    throw 'Confirme explicitamente -SupabaseValidado após migration, verificador e testes autenticados.'
}
if (-not (Test-Path -LiteralPath $AllowListPath)) {
    throw 'Lista branca FE-08 não encontrada.'
}

$CurrentBranch = (Invoke-Git -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') | Select-Object -First 1).Trim()
$CurrentCommit = (Invoke-Git -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
if ($CurrentBranch -ne $ExpectedBranch) {
    throw "Branch incorreta. Esperada: $ExpectedBranch. Atual: $CurrentBranch"
}
if ($CurrentCommit -ne $ExpectedBaseCommit) {
    throw "HEAD diferente do commit-base esperado. Esperado: $ExpectedBaseCommit. Atual: $CurrentCommit"
}

$AllowList = Get-Content -LiteralPath $AllowListPath |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$StagedPaths = @(Invoke-Git -Arguments @('diff', '--cached', '--name-only')) |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
if ($StagedPaths.Count -eq 0) {
    throw 'Não há arquivos staged. Execute validar_e_preparar_commit_fe08.ps1.'
}
$UnexpectedStaged = $StagedPaths | Where-Object { $AllowList -notcontains $_ }
if (@($UnexpectedStaged).Count -gt 0) {
    throw "Staging contém arquivos fora da lista branca:`n$($UnexpectedStaged -join [Environment]::NewLine)"
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
    Write-Host "Push confirmado. SHA local e remoto: $NewCommit"
} else {
    Write-Host 'Push não executado. Use -Push quando desejar publicar a branch.'
}

$FinalStatus = @(Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
if ($FinalStatus.Count -gt 0) {
    Write-Warning "O working tree não terminou limpo:`n$($FinalStatus -join [Environment]::NewLine)"
} else {
    Write-Host 'Working tree clean.'
}

Write-Host 'Nenhum merge em develop ou main foi realizado.'
