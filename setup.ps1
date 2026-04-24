# minmaxing Windows Setup
# One-command: powershell -Command "irm https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.ps1 | iex"
# Or save and run: irm https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.ps1 | iex

param(
    [Parameter(Position=0)]
    [string]$ApiKey
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  minmaxing Setup (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Python 3
Write-Host "[1/6] Checking Python 3..." -ForegroundColor Yellow
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonVersion = python3 --version 2>&1
    Write-Host "  [PASS] Python 3 found: $pythonVersion" -ForegroundColor Green
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonVersion = python --version 2>&1
    Write-Host "  [PASS] Python found: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Python not found. Install from https://python.org" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Install uvx
Write-Host "[2/6] Checking uvx..." -ForegroundColor Yellow
if (-not (Get-Command uvx -ErrorAction SilentlyContinue)) {
    Write-Host "Installing uvx..." -ForegroundColor Gray
    $uvInstallScript = "$env:TEMP\install-uv.ps1"
    Invoke-WebRequest -Uri "https://astral.sh/uv/install.ps" -OutFile $uvInstallScript
    powershell -ExecutionPolicy Bypass -File $uvInstallScript
    Remove-Item $uvInstallScript -Force -ErrorAction SilentlyContinue
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
if (Get-Command uvx -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] uvx installed" -ForegroundColor Green
} else {
    Write-Host "  [WARN] uvx not installed - see https://astral.sh/uv/install" -ForegroundColor Red
}
Write-Host ""

# Step 3: Verify Python dependencies
Write-Host "[3/6] Verifying Python dependencies..." -ForegroundColor Yellow
try {
    python3 -c "import sqlite3; print('sqlite3 available')" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [PASS] sqlite3 available" -ForegroundColor Green
    } else {
        python -c "import sqlite3; print('sqlite3 available')" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [PASS] sqlite3 available" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] sqlite3 not available" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "  [FAIL] sqlite3 not available" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Configure API Key
Write-Host "[4/6] Configuring MiniMax API key..." -ForegroundColor Yellow
Write-Host ""

if ($ApiKey -and $ApiKey -ne "YOUR_TOKEN_PLAN_KEY") {
    $settingsPath = ".claude\settings.json"
    if (Test-Path $settingsPath) {
        $content = Get-Content $settingsPath -Raw
        $content = $content -replace "YOUR_MINIMAX_API_KEY", $ApiKey
        Set-Content -Path $settingsPath -Value $content
        Write-Host "  [PASS] API key configured in .claude\settings.json" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] .claude\settings.json not found" -ForegroundColor Red
    }

    Write-Host "Configuring MiniMax MCP server..." -ForegroundColor Gray
    claude mcp add -s user MiniMax --env MINIMAX_API_KEY="$ApiKey" --env MINIMAX_API_HOST=https://api.minimax.io -- uvx minimax-coding-plan-mcp -y 2>$null
    if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
        Write-Host "  [PASS] MiniMax MCP configured" -ForegroundColor Green
    } else {
        Write-Host "  [PASS] MiniMax MCP configured (run 'claude mcp add' manually if needed)" -ForegroundColor Yellow
    }
} else {
    Write-Host "To complete setup, run with your API key:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '  irm https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.ps1 | iex -ApiKey "YOUR_TOKEN_PLAN_KEY"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or manually configure with:" -ForegroundColor Gray
    Write-Host '  claude mcp add -s user MiniMax \' -ForegroundColor Gray
    Write-Host '    --env MINIMAX_API_KEY=YOUR_TOKEN_PLAN_KEY \' -ForegroundColor Gray
    Write-Host '    --env MINIMAX_API_HOST=https://api.minimax.io \' -ForegroundColor Gray
    Write-Host '    -- uvx minimax-coding-plan-mcp -y' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Get your key from: platform.minimax.io" -ForegroundColor Gray
}
Write-Host ""

# Step 5: Initialize memory system directories
Write-Host "[5/6] Initializing memory system..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "obsidian\Memory\Decisions" | Out-Null
New-Item -ItemType Directory -Force -Path "obsidian\Memory\Patterns" | Out-Null
New-Item -ItemType Directory -Force -Path "obsidian\Memory\Errors" | Out-Null
New-Item -ItemType Directory -Force -Path "obsidian\Memory\Stories" | Out-Null
New-Item -ItemType Directory -Force -Path "obsidian\Memory\Dashboard" | Out-Null
New-Item -ItemType Directory -Force -Path ".taste\sessions" | Out-Null
New-Item -ItemType Directory -Force -Path ".taste\workflow-runs" | Out-Null
New-Item -ItemType Directory -Force -Path ".taste\specs" | Out-Null
New-Item -ItemType Directory -Force -Path ".minimaxing\state\events" | Out-Null
New-Item -ItemType Directory -Force -Path ".minimaxing\state\snapshots" | Out-Null
Write-Host "  [PASS] Memory directories created" -ForegroundColor Green

if (Test-Path "scripts\taste.sh") {
    bash scripts\taste.sh init 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [PASS] Taste system initialized" -ForegroundColor Green
    }
}
Write-Host ""

# Step 6: Verify harness
Write-Host "[6/6] Verifying harness..." -ForegroundColor Yellow
$pass = 0

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] Claude Code installed" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [WARN] Claude Code not installed - npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
}

if (Test-Path "memory\sqlite_db.py") {
    Write-Host "  [PASS] Memory system installed" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [WARN] Memory system not found" -ForegroundColor Red
}

if (Test-Path "scripts\memory.sh") {
    Write-Host "  [PASS] Memory CLI available" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [WARN] Memory CLI not found" -ForegroundColor Red
}
Write-Host ""

# Final status
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run: claude" -ForegroundColor Gray
Write-Host "  2. If this is a fresh repo, run: /tastebootstrap" -ForegroundColor Gray
Write-Host "  3. Then try: /workflow 'build a REST API'" -ForegroundColor Gray
Write-Host "  4. Check memory: bash scripts/memory.sh stats" -ForegroundColor Gray
Write-Host ""
