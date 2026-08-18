param(
    [Parameter(Mandatory = $true)]
    [string]$EvidencePath,

    [string]$ExpectedProjectRef = "vumbfpbcozjebomcthdw"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedEvidencePath = (
    Resolve-Path $EvidencePath
).Path

$manifestPath = Join-Path `
    $resolvedEvidencePath `
    "manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "manifest.json nao encontrado."
}

try {
    $manifest = Get-Content `
        $manifestPath `
        -Raw |
        ConvertFrom-Json
}
catch {
    throw "manifest.json invalido. $($_.Exception.Message)"
}

if ($manifest.project_ref -ne $ExpectedProjectRef) {
    throw "Project ref divergente no manifesto."
}

if ([string]::IsNullOrWhiteSpace($manifest.commit)) {
    throw "Commit ausente no manifesto."
}

if ([string]::IsNullOrWhiteSpace($manifest.branch)) {
    throw "Branch ausente no manifesto."
}

if ($null -eq $manifest.files) {
    throw "Lista de arquivos ausente no manifesto."
}

$validatedFiles = 0

foreach ($entry in $manifest.files) {

    $filePath = Join-Path `
        $resolvedEvidencePath `
        $entry.name

    if (-not (Test-Path $filePath)) {
        throw "Arquivo ausente: $($entry.name)"
    }

    $actualHash = (
        Get-FileHash `
            -Path $filePath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $expectedHash = (
        [string]$entry.sha256
    ).ToLowerInvariant()

    if ($actualHash -ne $expectedHash) {
        throw "Hash divergente: $($entry.name)"
    }

    $validatedFiles++
}

foreach ($jsonName in @(
    "security.json",
    "performance.json",
    "git-state.json",
    "environment.json"
)) {

    $jsonPath = Join-Path `
        $resolvedEvidencePath `
        $jsonName

    if (-not (Test-Path $jsonPath)) {
        throw "Evidencia obrigatoria ausente: $jsonName"
    }

    $jsonItem = Get-Item $jsonPath

    if ($jsonItem.Length -eq 0) {
        throw "Evidencia obrigatoria vazia: $jsonName"
    }

    try {
        Get-Content `
            $jsonPath `
            -Raw |
            ConvertFrom-Json |
            Out-Null
    }
    catch {
        throw "JSON invalido: $jsonName"
    }
}

if ([int]$manifest.command_failures -ne 0) {
    throw "O manifesto registra falha em uma ou mais execucoes."
}

Write-Host ""
Write-Host "============================================================"
Write-Host "EVIDENCE_INTEGRITY=PASS"
Write-Host "PROJECT_REF=$($manifest.project_ref)"
Write-Host "BRANCH=$($manifest.branch)"
Write-Host "COMMIT=$($manifest.commit)"
Write-Host "VALIDATED_FILES=$validatedFiles"
Write-Host "============================================================"
Write-Host ""
Write-Host "Integridade comprovada."
Write-Host "A classificacao dos findings permanece uma decisao de gate separada."
