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
$ExpectedBaseCommit = 'db4eaa4a4c2db42384823b6f621e730d2a2d4b4c'
$PackageRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = (Resolve-Path -LiteralPath $RepoPath).Path

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $output = & git -C $RepoRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no Git: git -C `"$RepoRoot`" $($Arguments -join ' ')`n$output"
    }
    return $output
}

function Get-NormalizedRelativePath {
    param([Parameter(Mandatory = $true)][string]$PathValue)
    return ($PathValue -replace '\\', '/').Trim()
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git não encontrado no PATH.'
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
    throw "O diretório informado não é a raiz de um repositório Git: $RepoRoot"
}
if (-not (Test-Path -LiteralPath (Join-Path $PackageRoot 'LISTA_BRANCA_ARQUIVOS.txt'))) {
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

$AllowList = Get-Content -LiteralPath (Join-Path $PackageRoot 'LISTA_BRANCA_ARQUIVOS.txt') |
    ForEach-Object { Get-NormalizedRelativePath $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$Mappings = @(
    @{ Source = 'supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql'; Destination = 'supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql' },
    @{ Source = 'supabase/verification/verificar_fe08_monitoramento_governanca_aprendizado.sql'; Destination = 'supabase/verification/verificar_fe08_monitoramento_governanca_aprendizado.sql' },
    @{ Source = 'docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md'; Destination = 'docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md' },
    @{ Source = 'docs/03-methodology/RELATORIO_INSPECAO_E_DECISAO_ARQUITETURAL_FE08.md'; Destination = 'docs/03-methodology/RELATORIO_INSPECAO_E_DECISAO_ARQUITETURAL_FE08.md' },
    @{ Source = 'docs/03-methodology/GUIA_EXECUCAO_FE08_SUPABASE_WEB.md'; Destination = 'docs/03-methodology/GUIA_EXECUCAO_FE08_SUPABASE_WEB.md' },
    @{ Source = 'docs/03-methodology/RELATORIO_VALIDACAO_ESTATICA_FE08.md'; Destination = 'docs/03-methodology/RELATORIO_VALIDACAO_ESTATICA_FE08.md' },
    @{ Source = 'scripts/instalar_fe08_no_repositorio.ps1'; Destination = 'scripts/fe08/instalar_fe08_no_repositorio.ps1' },
    @{ Source = 'scripts/validar_e_preparar_commit_fe08.ps1'; Destination = 'scripts/fe08/validar_e_preparar_commit_fe08.ps1' },
    @{ Source = 'scripts/commit_e_push_fe08.ps1'; Destination = 'scripts/fe08/commit_e_push_fe08.ps1' },
    @{ Source = 'LISTA_BRANCA_ARQUIVOS.txt'; Destination = 'scripts/fe08/LISTA_BRANCA_FE08.txt' }
)

foreach ($Mapping in $Mappings) {
    $SourcePath = Join-Path $PackageRoot $Mapping.Source
    $DestinationPath = Join-Path $RepoRoot ($Mapping.Destination -replace '/', [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Arquivo-fonte ausente no pacote: $($Mapping.Source)"
    }

    $DestinationDirectory = Split-Path -Parent $DestinationPath
    if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
        New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $DestinationPath) {
        $SourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
        $DestinationHash = (Get-FileHash -LiteralPath $DestinationPath -Algorithm SHA256).Hash
        if ($SourceHash -eq $DestinationHash) {
            Write-Host "Mantido, conteúdo idêntico: $($Mapping.Destination)"
            continue
        }
        if (-not $Force) {
            throw "Destino já existe com conteúdo diferente: $($Mapping.Destination). Use -Force somente após revisão."
        }
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    Write-Host "Instalado: $($Mapping.Destination)"
}

$ManifestPath = Join-Path $RepoRoot 'scripts/fe08/MANIFESTO_SHA256_FE08.txt'
$HashTargets = $AllowList | Where-Object { $_ -ne 'scripts/fe08/MANIFESTO_SHA256_FE08.txt' }
$ManifestLines = @(
    '# Manifesto SHA-256 — FE-08',
    "# Gerado em UTC: $([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "# Commit-base: $ExpectedBaseCommit"
)
foreach ($RelativePath in $HashTargets) {
    $AbsolutePath = Join-Path $RepoRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $AbsolutePath)) {
        throw "Arquivo da lista branca não encontrado após instalação: $RelativePath"
    }
    $Hash = (Get-FileHash -LiteralPath $AbsolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $ManifestLines += "$Hash  $RelativePath"
}
Set-Content -LiteralPath $ManifestPath -Value $ManifestLines -Encoding UTF8
Write-Host 'Gerado: scripts/fe08/MANIFESTO_SHA256_FE08.txt'

$Changed = @(Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
$Unexpected = @()
foreach ($Line in $Changed) {
    if ([string]::IsNullOrWhiteSpace($Line)) { continue }
    $RelativePath = Get-NormalizedRelativePath $Line.Substring(3)
    if ($AllowList -notcontains $RelativePath) {
        $Unexpected += $Line
    }
}
if ($Unexpected.Count -gt 0) {
    throw "A instalação alterou arquivos fora da lista branca:`n$($Unexpected -join [Environment]::NewLine)"
}

Write-Host ''
Write-Host 'FE-08 instalada no working tree sem staging, commit, push ou merge.'
Write-Host "Branch: $CurrentBranch"
Write-Host "Commit-base: $CurrentCommit"
Write-Host 'Próxima ação: executar a migration e o verificador no Supabase Web.'
