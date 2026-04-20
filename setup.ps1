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

# Step 1: Install ForgeGod
Write-Host "[1/4] Installing ForgeGod memory system..." -ForegroundColor Yellow
pip install forgegod --break-system-packages 2>$null
if ($LASTEXITCODE -ne 0) {
    pip3 install forgegod --break-system-packages 2>$null
}
Write-Host ""

# Step 2: Install uvx
Write-Host "[2/4] Checking uvx..." -ForegroundColor Yellow
if (-not (Get-Command uvx -ErrorAction SilentlyContinue)) {
    Write-Host "Installing uvx..." -ForegroundColor Gray
    # PowerShell-native uv installation
    $uvInstallScript = "$env:TEMP\install-uv.ps1"
    Invoke-WebRequest -Uri "https://astral.sh/uv/install.ps" -OutFile $uvInstallScript
    powershell -ExecutionPolicy Bypass -File $uvInstallScript
    Remove-Item $uvInstallScript -Force -ErrorAction SilentlyContinue
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
Write-Host ""

# Step 3: Verify installation
Write-Host "[3/4] Verifying installation..." -ForegroundColor Yellow
$pass = 0

if (Get-Command forgegod -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] ForgeGod installed" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [WARN] ForgeGod not installed - run: pip install forgegod --break-system-packages" -ForegroundColor Red
}

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] Claude Code installed" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [WARN] Claude Code not installed - npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
}

if (Get-Command uvx -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] uvx installed" -ForegroundColor Green
    $pass++
} else {
    Write-Host "  [WARN] uvx not installed - see https://astral.sh/uv/install" -ForegroundColor Red
}
Write-Host ""

# Step 4: Configure API Key
Write-Host "[4/4] Configuring MiniMax API key..." -ForegroundColor Yellow
Write-Host ""

if ($ApiKey -and $ApiKey -ne "YOUR_TOKEN_PLAN_KEY") {
    $settingsPath = ".claude\settings.json"
    if (Test-Path $settingsPath) {
        $content = Get-Content $settingsPath -Raw
        $content = $content -replace "YOUR_TOKEN_PLAN_KEY", $ApiKey
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

# Final status
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run: .\scripts\test-harness.sh (or test-harness.ps1 if exists)" -ForegroundColor Gray
Write-Host "  2. Start coding with: claude" -ForegroundColor Gray
Write-Host ""
