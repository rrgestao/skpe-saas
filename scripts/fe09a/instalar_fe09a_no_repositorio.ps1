[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedBranch = 'feature/formulacao-estrategica-operacional'
$ExpectedBaseCommit = '0fd801bfe076c07fd6f06ac2aea94a8aa094115f'
$PackageRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$RepoRoot = (Resolve-Path -LiteralPath $RepoPath).Path
$PackageAllowList = Join-Path $PackageRoot 'LISTA_BRANCA_ARQUIVOS.txt'

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

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git não encontrado no PATH.'
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
    throw "Não é a raiz de um repositório Git: $RepoRoot"
}
if (-not (Test-Path -LiteralPath $PackageAllowList)) {
    throw 'LISTA_BRANCA_ARQUIVOS.txt não encontrada no pacote.'
}

$CurrentBranch = (Invoke-Git -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') | Select-Object -First 1).Trim()
$CurrentCommit = (Invoke-Git -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()

if ($CurrentBranch -ne $ExpectedBranch) {
    throw "Branch incorreta. Esperada: $ExpectedBranch. Atual: $CurrentBranch"
}
if ($CurrentCommit -ne $ExpectedBaseCommit) {
    throw "Commit-base incorreto. Esperado: $ExpectedBaseCommit. Atual: $CurrentCommit"
}

$InitialStatus = @(Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
if ($InitialStatus.Count -gt 0) {
    throw "O working tree deve estar limpo antes da instalação.`n$($InitialStatus -join [Environment]::NewLine)"
}

$AllowList = Get-Content -LiteralPath $PackageAllowList |
    ForEach-Object { Normalize-PathValue $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

foreach ($RelativePath in $AllowList) {
    $SourcePath = Join-Path $PackageRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $DestinationPath = Join-Path $RepoRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Arquivo-fonte ausente: $RelativePath"
    }

    $DestinationDirectory = Split-Path -Parent $DestinationPath
    if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
        New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $DestinationPath) {
        $SourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
        $DestinationHash = (Get-FileHash -LiteralPath $DestinationPath -Algorithm SHA256).Hash
        if ($SourceHash -eq $DestinationHash) {
            Write-Host "Mantido, conteúdo idêntico: $RelativePath"
            continue
        }
        if (-not $Force) {
            throw "Destino existente com conteúdo diferente: $RelativePath. Use -Force somente após revisão."
        }
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    Write-Host "Instalado: $RelativePath"
}

$RepoAllowList = Join-Path $RepoRoot 'scripts/fe09a/LISTA_BRANCA_FE09A.txt'
Set-Content -LiteralPath $RepoAllowList -Value $AllowList -Encoding UTF8

$ManifestPath = Join-Path $RepoRoot 'scripts/fe09a/MANIFESTO_SHA256_FE09A.txt'
$HashTargets = $AllowList | Where-Object { $_ -ne 'scripts/fe09a/MANIFESTO_SHA256_FE09A.txt' }
$ManifestLines = @(
    '# Manifesto SHA-256 — FE-09.A',
    "# Gerado em UTC: $([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "# Commit-base: $ExpectedBaseCommit"
)
foreach ($RelativePath in $HashTargets) {
    $AbsolutePath = Join-Path $RepoRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $Hash = (Get-FileHash -LiteralPath $AbsolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $ManifestLines += "$Hash  $RelativePath"
}
Set-Content -LiteralPath $ManifestPath -Value $ManifestLines -Encoding UTF8

Write-Host ''
Write-Host 'Pacote arquitetural FE-09.A instalado sem staging, commit, push ou merge.'
