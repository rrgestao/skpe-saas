[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$SkipBaseCommitCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedBranch = 'feature/formulacao-estrategica-operacional'
$ExpectedBaseCommit = 'db4eaa4a4c2db42384823b6f621e730d2a2d4b4c'
$RepoRoot = (Resolve-Path -LiteralPath $RepoPath).Path
$AllowListPath = Join-Path $RepoRoot 'scripts/fe08/LISTA_BRANCA_FE08.txt'
$ManifestPath = Join-Path $RepoRoot 'scripts/fe08/MANIFESTO_SHA256_FE08.txt'

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

if (-not (Test-Path -LiteralPath $AllowListPath)) {
    throw 'Lista branca da FE-08 não encontrada. Execute primeiro instalar_fe08_no_repositorio.ps1.'
}

$CurrentBranch = (Invoke-Git -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') | Select-Object -First 1).Trim()
$CurrentCommit = (Invoke-Git -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
if ($CurrentBranch -ne $ExpectedBranch) {
    throw "Branch incorreta. Esperada: $ExpectedBranch. Atual: $CurrentBranch"
}
if (-not $SkipBaseCommitCheck -and $CurrentCommit -ne $ExpectedBaseCommit) {
    throw "HEAD diferente do commit-base esperado. Esperado: $ExpectedBaseCommit. Atual: $CurrentCommit"
}

$AllowList = Get-Content -LiteralPath $AllowListPath |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

foreach ($RelativePath in $AllowList) {
    $AbsolutePath = Join-Path $RepoRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $AbsolutePath)) {
        throw "Arquivo obrigatório ausente: $RelativePath"
    }
}

$StatusLines = @(Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
$Unexpected = @()
foreach ($Line in $StatusLines) {
    if ([string]::IsNullOrWhiteSpace($Line)) { continue }
    $RelativePath = Normalize-PathValue $Line.Substring(3)
    if ($AllowList -notcontains $RelativePath) {
        $Unexpected += $Line
    }
}
if ($Unexpected.Count -gt 0) {
    throw "Existem alterações fora da lista branca:`n$($Unexpected -join [Environment]::NewLine)"
}

& git -C $RepoRoot --no-pager diff --check
if ($LASTEXITCODE -ne 0) {
    throw 'git diff --check encontrou whitespace ou conflito.'
}

$HashTargets = $AllowList | Where-Object { $_ -ne 'scripts/fe08/MANIFESTO_SHA256_FE08.txt' }
$ManifestLines = @(
    '# Manifesto SHA-256 — FE-08',
    "# Gerado em UTC: $([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "# Commit-base: $ExpectedBaseCommit"
)
foreach ($RelativePath in $HashTargets) {
    $AbsolutePath = Join-Path $RepoRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $Hash = (Get-FileHash -LiteralPath $AbsolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $ManifestLines += "$Hash  $RelativePath"
}
Set-Content -LiteralPath $ManifestPath -Value $ManifestLines -Encoding UTF8

$GitAddArguments = @('add', '--') + $AllowList
Invoke-Git -Arguments $GitAddArguments | Out-Null

& git -C $RepoRoot --no-pager diff --cached --check
if ($LASTEXITCODE -ne 0) {
    throw 'git diff --cached --check encontrou whitespace ou conflito.'
}

$StagedPaths = @(Invoke-Git -Arguments @('diff', '--cached', '--name-only')) |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$UnexpectedStaged = $StagedPaths | Where-Object { $AllowList -notcontains $_ }
if (@($UnexpectedStaged).Count -gt 0) {
    throw "Staging contém arquivos fora da lista branca:`n$($UnexpectedStaged -join [Environment]::NewLine)"
}
if ($StagedPaths.Count -eq 0) {
    throw 'Nenhuma alteração foi preparada para commit.'
}

Write-Host ''
Write-Host 'Validação Git concluída e staging seletivo preparado.'
Write-Host 'Arquivos staged:'
& git -C $RepoRoot --no-pager diff --cached --name-status
Write-Host ''
Write-Host 'Resumo:'
& git -C $RepoRoot --no-pager diff --cached --stat
Write-Host ''
Write-Host 'Nenhum commit, push ou merge foi executado.'
Write-Host 'Após confirmar Supabase e testes autenticados, execute commit_e_push_fe08.ps1.'
