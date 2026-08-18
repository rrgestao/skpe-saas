param(
    [string]$GateCode = "17-B.3B",
    [string]$ExpectedProjectRef = "vumbfpbcozjebomcthdw",
    [string]$ExpectedBranch = "feature/formulacao-estrategica-operacional",
    [string]$ExpectedCliVersion = "2.110.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-ExitCode {
    param(
        [string]$Message
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$Message ExitCode=$LASTEXITCODE"
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Value |
        ConvertTo-Json -Depth 20 |
        Set-Content -Path $Path -Encoding UTF8
}

function Assert-JsonEvidence {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Evidencia JSON ausente: $Path"
    }

    $item = Get-Item $Path

    if ($item.Length -eq 0) {
        throw "Evidencia JSON vazia: $Path"
    }

    try {
        Get-Content $Path -Raw |
            ConvertFrom-Json |
            Out-Null
    }
    catch {
        throw "Evidencia JSON ilegivel: $Path. $($_.Exception.Message)"
    }
}

function Invoke-SupabaseCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $true)]
        [string]$StdoutFile,

        [Parameter(Mandatory = $true)]
        [string]$StderrFile
    )

    $stdoutPath = Join-Path $OutputDirectory $StdoutFile
    $stderrPath = Join-Path $OutputDirectory $StderrFile

    $npxCommand = Get-Command "npx.cmd" -ErrorAction Stop

    try {
        $process = Start-Process `
            -FilePath $npxCommand.Source `
            -ArgumentList $Arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        $exitCode = $process.ExitCode
    }
    catch {
        $message = @(
            "Falha ao iniciar processo nativo."
            "Comando: npx $($Arguments -join ' ')"
            "Erro: $($_.Exception.Message)"
        ) -join [Environment]::NewLine

        Set-Content `
            -Path $stderrPath `
            -Value $message `
            -Encoding UTF8

        if (-not (Test-Path $stdoutPath)) {
            New-Item `
                -ItemType File `
                -Path $stdoutPath `
                -Force |
                Out-Null
        }

        $exitCode = 9001
    }

    return [PSCustomObject]@{
        name        = $Name
        command     = "npx " + ($Arguments -join " ")
        exit_code   = $exitCode
        stdout_file = $StdoutFile
        stderr_file = $StderrFile
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "SPARKs - PIPELINE CANONICO DE EVIDENCIAS TECNICAS"
Write-Host "Gate: $GateCode"
Write-Host "============================================================"
Write-Host ""

# ---------------------------------------------------------------------------
# A. REPOSITORIO
# ---------------------------------------------------------------------------

$repoRoot = (git rev-parse --show-toplevel).Trim()
Assert-ExitCode "Nao foi possivel localizar o repositorio Git."

Set-Location $repoRoot

$branch = (git branch --show-current).Trim()
Assert-ExitCode "Nao foi possivel identificar a branch."

if ($branch -ne $ExpectedBranch) {
    throw "Branch incorreta. Esperado=$ExpectedBranch Atual=$branch"
}

$worktree = @(git status --porcelain)

if ($worktree.Count -ne 0) {
    Write-Host "WORKTREE=DIRTY"
    $worktree | ForEach-Object { Write-Host $_ }
    throw "Coleta bloqueada. O worktree deve estar limpo."
}

git fetch origin | Out-Null
Assert-ExitCode "Falha no git fetch origin."

$head = (git rev-parse HEAD).Trim()
Assert-ExitCode "Falha ao obter HEAD."

$originHead = (git rev-parse "origin/$ExpectedBranch").Trim()
Assert-ExitCode "Falha ao obter origin/$ExpectedBranch."

$remoteLine = (
    git ls-remote origin "refs/heads/$ExpectedBranch"
)

Assert-ExitCode "Falha ao consultar a branch remota."

if ([string]::IsNullOrWhiteSpace($remoteLine)) {
    throw "Branch remota nao localizada."
}

$remoteHead = (($remoteLine -split "\s+")[0]).Trim()

if (
    $head -ne $originHead -or
    $head -ne $remoteHead
) {
    throw "Repositorio nao sincronizado. LOCAL=$head ORIGIN=$originHead REMOTE=$remoteHead"
}

# ---------------------------------------------------------------------------
# B. PROJETO SUPABASE
# ---------------------------------------------------------------------------

$projectRefFile = Join-Path $repoRoot "supabase\.temp\project-ref"

if (-not (Test-Path $projectRefFile)) {
    throw "Arquivo de vinculacao Supabase nao encontrado: $projectRefFile"
}

$projectRef = (Get-Content $projectRefFile -Raw).Trim()

if ($projectRef -ne $ExpectedProjectRef) {
    throw "Projeto Supabase incorreto. Esperado=$ExpectedProjectRef Atual=$projectRef"
}

# ---------------------------------------------------------------------------
# C. VERSAO DA CLI
# ---------------------------------------------------------------------------

$cliVersion = (& npx --no-install supabase --version).Trim()
Assert-ExitCode "Falha ao executar Supabase CLI."

if ($cliVersion -ne $ExpectedCliVersion) {
    throw "Versao da Supabase CLI divergente. Esperado=$ExpectedCliVersion Atual=$cliVersion"
}

$nodeVersion = (& node --version).Trim()
Assert-ExitCode "Falha ao consultar Node.js."

$npmVersion = (& npm --version).Trim()
Assert-ExitCode "Falha ao consultar npm."

# ---------------------------------------------------------------------------
# D. DIRETORIO DE EVIDENCIAS
# ---------------------------------------------------------------------------

$timestampUtc = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")

$safeGateCode = $GateCode -replace '[^A-Za-z0-9._-]', '_'

$outputDirectory = Join-Path `
    $repoRoot `
    "_audit\supabase\$safeGateCode\$timestampUtc"

New-Item `
    -ItemType Directory `
    -Path $outputDirectory `
    -Force |
    Out-Null

Write-Host "OUTPUT=$outputDirectory"

# ---------------------------------------------------------------------------
# E. ESTADO GIT
# ---------------------------------------------------------------------------

$gitState = [ordered]@{
    repository_root = $repoRoot
    branch          = $branch
    head            = $head
    origin_head     = $originHead
    remote_head     = $remoteHead
    synchronized    = (
        $head -eq $originHead -and
        $head -eq $remoteHead
    )
    worktree_clean  = $true
}

Write-JsonFile `
    -Value $gitState `
    -Path (Join-Path $outputDirectory "git-state.json")

# ---------------------------------------------------------------------------
# F. AMBIENTE
# ---------------------------------------------------------------------------

$environment = [ordered]@{
    gate_code             = $GateCode
    project_ref           = $projectRef
    supabase_cli_version  = $cliVersion
    node_version          = $nodeVersion
    npm_version           = $npmVersion
    powershell_version    = $PSVersionTable.PSVersion.ToString()
    os                    = [Environment]::OSVersion.VersionString
    captured_at_utc       = [DateTime]::UtcNow.ToString("o")
}

Write-JsonFile `
    -Value $environment `
    -Path (Join-Path $outputDirectory "environment.json")

# ---------------------------------------------------------------------------
# G. SECURITY ADVISOR
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "Executando Security Advisor..."

$security = Invoke-SupabaseCapture `
    -Name "security_advisor" `
    -Arguments @(
        "--no-install",
        "supabase",
        "db",
        "advisors",
        "--linked",
        "--type",
        "security",
        "--level",
        "info",
        "--fail-on",
        "none",
        "--output-format",
        "json"
    ) `
    -OutputDirectory $outputDirectory `
    -StdoutFile "security.json" `
    -StderrFile "security.stderr.txt"

# ---------------------------------------------------------------------------
# H. PERFORMANCE ADVISOR
# ---------------------------------------------------------------------------

Write-Host "Executando Performance Advisor..."

$performance = Invoke-SupabaseCapture `
    -Name "performance_advisor" `
    -Arguments @(
        "--no-install",
        "supabase",
        "db",
        "advisors",
        "--linked",
        "--type",
        "performance",
        "--level",
        "info",
        "--fail-on",
        "none",
        "--output-format",
        "json"
    ) `
    -OutputDirectory $outputDirectory `
    -StdoutFile "performance.json" `
    -StderrFile "performance.stderr.txt"

# ---------------------------------------------------------------------------
# I. DB LINT
# ---------------------------------------------------------------------------

Write-Host "Executando DB Lint remoto..."

$dbLint = Invoke-SupabaseCapture `
    -Name "db_lint" `
    -Arguments @(
        "--no-install",
        "supabase",
        "db",
        "lint",
        "--linked",
        "--level",
        "warning",
        "--fail-on",
        "none"
    ) `
    -OutputDirectory $outputDirectory `
    -StdoutFile "db-lint.txt" `
    -StderrFile "db-lint.stderr.txt"

# ---------------------------------------------------------------------------
# J. MIGRATIONS
# ---------------------------------------------------------------------------

Write-Host "Coletando historico de migrations..."

$migrations = Invoke-SupabaseCapture `
    -Name "migration_list" `
    -Arguments @(
        "--no-install",
        "supabase",
        "migration",
        "list"
    ) `
    -OutputDirectory $outputDirectory `
    -StdoutFile "migrations.txt" `
    -StderrFile "migrations.stderr.txt"

$commands = @(
    $security,
    $performance,
    $dbLint,
    $migrations
)

# ---------------------------------------------------------------------------
# K. VALIDACAO PRIMARIA
# ---------------------------------------------------------------------------

$commandFailures = @(
    $commands |
        Where-Object { $_.exit_code -ne 0 }
)

if ($security.exit_code -eq 0) {
    Assert-JsonEvidence `
        -Path (Join-Path $outputDirectory "security.json")
}

if ($performance.exit_code -eq 0) {
    Assert-JsonEvidence `
        -Path (Join-Path $outputDirectory "performance.json")
}

# ---------------------------------------------------------------------------
# L. RESUMO
# ---------------------------------------------------------------------------

$summaryLines = @(
    "# SPARKs - Pacote de Evidencias Tecnicas"
    ""
    "- Gate: $GateCode"
    "- Projeto Supabase: $projectRef"
    "- Branch: $branch"
    "- Commit: $head"
    "- Supabase CLI: $cliVersion"
    "- Coleta UTC: $timestampUtc"
    ""
    "## Execucoes"
    ""
)

foreach ($command in $commands) {
    $summaryLines += "- $($command.name): exit_code=$($command.exit_code)"
}

$summaryLines += @(
    ""
    "## Regra de governanca"
    ""
    "Este pacote comprova a materializacao das evidencias tecnicas."
    "Ele nao converte automaticamente findings em PASS do gate."
    "Ausencia, falha ou ilegibilidade de evidencia nunca equivale a PASS."
)

$summaryLines |
    Set-Content `
        -Path (Join-Path $outputDirectory "summary.md") `
        -Encoding UTF8

# ---------------------------------------------------------------------------
# M. MANIFESTO SHA-256
# ---------------------------------------------------------------------------

$evidenceFiles = @(
    Get-ChildItem `
        -Path $outputDirectory `
        -File |
        Where-Object { $_.Name -ne "manifest.json" } |
        Sort-Object Name
)

$manifestFiles = @()

foreach ($file in $evidenceFiles) {
    $hash = (
        Get-FileHash `
            -Path $file.FullName `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $manifestFiles += [ordered]@{
        name   = $file.Name
        bytes  = $file.Length
        sha256 = $hash
    }
}

$manifest = [ordered]@{
    schema_version       = "1.0"
    pipeline             = "SPARKs Canonical Technical Evidence Pipeline"
    gate_code            = $GateCode
    project_ref          = $projectRef
    repository           = "rrgestao/skpe-saas"
    branch               = $branch
    commit               = $head
    supabase_cli_version = $cliVersion
    captured_at_utc      = [DateTime]::UtcNow.ToString("o")
    commands             = $commands
    command_failures     = $commandFailures.Count
    files                = $manifestFiles
}

Write-JsonFile `
    -Value $manifest `
    -Path (Join-Path $outputDirectory "manifest.json")

# ---------------------------------------------------------------------------
# N. RESULTADO
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"

if ($commandFailures.Count -gt 0) {
    Write-Host "EVIDENCE_CAPTURE=FAIL"
    Write-Host "COMMAND_FAILURES=$($commandFailures.Count)"
    Write-Host "OUTPUT=$outputDirectory"
    Write-Host "============================================================"
    exit 1
}

Write-Host "EVIDENCE_CAPTURE=PASS"
Write-Host "SECURITY_EVIDENCE=MATERIALIZED"
Write-Host "PERFORMANCE_EVIDENCE=MATERIALIZED"
Write-Host "OUTPUT=$outputDirectory"
Write-Host "============================================================"
Write-Host ""
Write-Host "IMPORTANTE:"
Write-Host "EVIDENCE_CAPTURE=PASS significa apenas que as evidencias foram"
Write-Host "coletadas e sao legiveis. Nao significa que o Gate esta aprovado."
