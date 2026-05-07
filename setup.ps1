# minmaxing Windows Setup
# Bash/Git Bash remains the recommended installer. This PowerShell helper keeps
# the same default: opusworkflow, with split ignored local profiles.
# Optional suggested Claude-only mode: -Mode opussonnet.

param(
    [Parameter(Position=0)]
    [string]$ApiKey = $env:MINIMAX_TOKEN_KEY,

    [ValidateSet("minimax", "opusworkflow", "opusminimax", "opussonnet")]
    [string]$Mode = "opusworkflow",

    [string]$PlannerModel = "claude-opus-4-7",
    [string]$ExecutorModel = ""
)

$ErrorActionPreference = "Stop"

if (-not $ExecutorModel) {
    if ($Mode -eq "opussonnet") {
        $ExecutorModel = "claude-sonnet-4-6"
    } else {
        $ExecutorModel = "MiniMax-M2.7-highspeed"
    }
}

function Write-Step($Text) {
    Write-Host $Text -ForegroundColor Yellow
}

function Ensure-ObjectProperty($Object, $Name, $Value) {
    if (-not ($Object.PSObject.Properties.Name -contains $Name)) {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Read-JsonOrDefault($Path, $DefaultJson) {
    if (Test-Path $Path) {
        return Get-Content $Path -Raw | ConvertFrom-Json
    }
    return $DefaultJson | ConvertFrom-Json
}

function Write-Json($Path, $Data) {
    $Data | ConvertTo-Json -Depth 32 | Set-Content -Path $Path -Encoding UTF8
}

function Configure-ExecutorProfile($Path, $Key, $Model) {
    $default = '{"profile":"minimax-executor","env":{},"permissions":{"defaultMode":"acceptEdits"}}'
    $data = Read-JsonOrDefault $Path $default
    Ensure-ObjectProperty $data "env" ([pscustomobject]@{})

    $envObj = $data.env
    $values = @{
        "ANTHROPIC_BASE_URL" = "https://api.minimax.io/anthropic"
        "ANTHROPIC_AUTH_TOKEN" = $Key
        "MINIMAX_API_KEY" = $Key
        "MINIMAX_API_HOST" = "https://api.minimax.io"
        "ANTHROPIC_MODEL" = $Model
        "ANTHROPIC_SMALL_FAST_MODEL" = $Model
        "ANTHROPIC_DEFAULT_SONNET_MODEL" = $Model
        "ANTHROPIC_DEFAULT_HAIKU_MODEL" = $Model
        "CLAUDE_CODE_SUBAGENT_MODEL" = $Model
    }

    foreach ($name in $values.Keys) {
        if ($envObj.PSObject.Properties.Name -contains $name) {
            $envObj.$name = $values[$name]
        } else {
            $envObj | Add-Member -NotePropertyName $name -NotePropertyValue $values[$name]
        }
    }

    Write-Json $Path $data
}

function Configure-PlannerProfile($Path, $Model) {
    $default = '{"profile":"opusminimax-planner","env":{},"permissions":{"defaultMode":"acceptEdits"}}'
    $data = Read-JsonOrDefault $Path $default
    Ensure-ObjectProperty $data "env" ([pscustomobject]@{})

    if ($data.env.PSObject.Properties.Name -contains "ANTHROPIC_BASE_URL") {
        $data.env.PSObject.Properties.Remove("ANTHROPIC_BASE_URL")
    }
    if ($data.env.PSObject.Properties.Name -contains "ANTHROPIC_AUTH_TOKEN") {
        $data.env.PSObject.Properties.Remove("ANTHROPIC_AUTH_TOKEN")
    }
    if ($data.env.PSObject.Properties.Name -contains "MINIMAX_API_KEY") {
        $data.env.PSObject.Properties.Remove("MINIMAX_API_KEY")
    }

    if ($data.env.PSObject.Properties.Name -contains "ANTHROPIC_DEFAULT_OPUS_MODEL") {
        $data.env.ANTHROPIC_DEFAULT_OPUS_MODEL = $Model
    } else {
        $data.env | Add-Member -NotePropertyName "ANTHROPIC_DEFAULT_OPUS_MODEL" -NotePropertyValue $Model
    }
    if ($data.env.PSObject.Properties.Name -contains "CLAUDE_CODE_EFFORT_LEVEL") {
        $data.env.CLAUDE_CODE_EFFORT_LEVEL = "xhigh"
    } else {
        $data.env | Add-Member -NotePropertyName "CLAUDE_CODE_EFFORT_LEVEL" -NotePropertyValue "xhigh"
    }

    Write-Json $Path $data
}

function Configure-OpusSonnetProfile($Path, $PlannerModel, $ExecutorModel) {
    $default = '{"profile":"opussonnet","model":"opusplan","env":{},"permissions":{"defaultMode":"bypassPermissions"}}'
    $data = Read-JsonOrDefault $Path $default
    Ensure-ObjectProperty $data "env" ([pscustomobject]@{})
    $data.profile = "opussonnet"
    Ensure-ObjectProperty $data "model" "opusplan"
    $data.model = "opusplan"

    foreach ($name in @("ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "MINIMAX_API_KEY", "MINIMAX_API_HOST")) {
        if ($data.env.PSObject.Properties.Name -contains $name) {
            $data.env.PSObject.Properties.Remove($name)
        }
    }

    $values = @{
        "ANTHROPIC_MODEL" = "opusplan"
        "ANTHROPIC_DEFAULT_OPUS_MODEL" = $PlannerModel
        "ANTHROPIC_DEFAULT_SONNET_MODEL" = $ExecutorModel
        "CLAUDE_CODE_SUBAGENT_MODEL" = $ExecutorModel
        "CLAUDE_CODE_EFFORT_LEVEL" = "xhigh"
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "1"
        "DISABLE_AUTO_COMPACT" = "0"
        "CLAUDE_CODE_NO_FLICKER" = "1"
    }

    foreach ($name in $values.Keys) {
        if ($data.env.PSObject.Properties.Name -contains $name) {
            $data.env.$name = $values[$name]
        } else {
            $data.env | Add-Member -NotePropertyName $name -NotePropertyValue $values[$name]
        }
    }

    Write-Json $Path $data
}

function Configure-SonnetExecutorProfile($Path, $Model) {
    $default = '{"profile":"sonnet-executor","model":"claude-sonnet-4-6","env":{},"permissions":{"defaultMode":"bypassPermissions"}}'
    $data = Read-JsonOrDefault $Path $default
    Ensure-ObjectProperty $data "env" ([pscustomobject]@{})
    $data.profile = "sonnet-executor"
    Ensure-ObjectProperty $data "model" $Model
    $data.model = $Model

    foreach ($name in @("ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "MINIMAX_API_KEY", "MINIMAX_API_HOST")) {
        if ($data.env.PSObject.Properties.Name -contains $name) {
            $data.env.PSObject.Properties.Remove($name)
        }
    }

    $values = @{
        "ANTHROPIC_MODEL" = $Model
        "ANTHROPIC_DEFAULT_SONNET_MODEL" = $Model
        "CLAUDE_CODE_SUBAGENT_MODEL" = $Model
        "CLAUDE_CODE_EFFORT_LEVEL" = "high"
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "1"
        "DISABLE_AUTO_COMPACT" = "0"
        "CLAUDE_CODE_NO_FLICKER" = "1"
    }

    foreach ($name in $values.Keys) {
        if ($data.env.PSObject.Properties.Name -contains $name) {
            $data.env.$name = $values[$name]
        } else {
            $data.env | Add-Member -NotePropertyName $name -NotePropertyValue $values[$name]
        }
    }

    Write-Json $Path $data
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  minmaxing Setup (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Mode: $Mode" -ForegroundColor White
if ($Mode -eq "opusworkflow") {
    Write-Host "Default route: /opusworkflow (Claude/Opus judgment + MiniMax execution)" -ForegroundColor White
} elseif ($Mode -eq "opussonnet") {
    Write-Host "Suggested route: /opusworkflow with Claude opusplan (Opus planning + Sonnet execution)" -ForegroundColor White
}
Write-Host ""

Write-Step "[1/5] Checking Python..."
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] $(python3 --version)" -ForegroundColor Green
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] $(python --version)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Python not found. Install Python 3.11+ first." -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Step "[2/5] Checking Claude Code..."
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  [PASS] Claude Code installed" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Claude Code not found. Install it, then rerun setup." -ForegroundColor Yellow
}
Write-Host ""

Write-Step "[3/5] Preparing local provider profiles..."
New-Item -ItemType Directory -Force -Path ".claude" | Out-Null

$splitMode = ($Mode -eq "opusworkflow" -or $Mode -eq "opusminimax" -or $Mode -eq "opussonnet")

if ($Mode -eq "opussonnet") {
    $opussonnetPath = ".claude\settings.opussonnet.local.json"
    $sonnetPath = ".claude\settings.sonnet-executor.local.json"
    $plannerPath = ".claude\settings.opusminimax-planner.local.json"

    if ((-not (Test-Path $opussonnetPath)) -and (Test-Path ".claude\settings.opussonnet.example.json")) {
        Copy-Item ".claude\settings.opussonnet.example.json" $opussonnetPath
    }
    if ((-not (Test-Path $sonnetPath)) -and (Test-Path ".claude\settings.sonnet-executor.example.json")) {
        Copy-Item ".claude\settings.sonnet-executor.example.json" $sonnetPath
    }
    if ((-not (Test-Path $plannerPath)) -and (Test-Path ".claude\settings.opusminimax-planner.example.json")) {
        Copy-Item ".claude\settings.opusminimax-planner.example.json" $plannerPath
    }

    Configure-OpusSonnetProfile $opussonnetPath $PlannerModel $ExecutorModel
    Configure-SonnetExecutorProfile $sonnetPath $ExecutorModel
    Configure-PlannerProfile $plannerPath $PlannerModel

    if (-not (Test-Path ".claude\settings.local.json")) {
        Copy-Item $opussonnetPath ".claude\settings.local.json"
        Write-Host "  [PASS] Claude Code default local profile set to opusplan" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Preserved existing .claude\settings.local.json" -ForegroundColor Gray
        Write-Host "  [INFO] To launch explicitly: claude --settings .claude/settings.opussonnet.local.json" -ForegroundColor Gray
    }
    Write-Host "  [PASS] Opus planner pinned to $PlannerModel" -ForegroundColor Green
    Write-Host "  [PASS] Sonnet executor pinned to $ExecutorModel" -ForegroundColor Green
} elseif ($ApiKey -and $ApiKey -ne "YOUR_TOKEN_PLAN_KEY") {
    if ($splitMode) {
        $executorPath = ".claude\settings.minimax-executor.local.json"
        $plannerPath = ".claude\settings.opusminimax-planner.local.json"

        if ((-not (Test-Path $executorPath)) -and (Test-Path ".claude\settings.minimax-executor.example.json")) {
            Copy-Item ".claude\settings.minimax-executor.example.json" $executorPath
        }
        if ((-not (Test-Path $plannerPath)) -and (Test-Path ".claude\settings.opusminimax-planner.example.json")) {
            Copy-Item ".claude\settings.opusminimax-planner.example.json" $plannerPath
        }

        Configure-ExecutorProfile $executorPath $ApiKey $ExecutorModel
        Configure-PlannerProfile $plannerPath $PlannerModel

        Write-Host "  [PASS] MiniMax token written to ignored executor profile" -ForegroundColor Green
        Write-Host "  [PASS] Planner profile kept provider-clean" -ForegroundColor Green
        Write-Host "  [INFO] Split mode does not mutate user-scope MCP automatically" -ForegroundColor Gray
    } else {
        $localPath = ".claude\settings.local.json"
        if ((-not (Test-Path $localPath)) -and (Test-Path ".claude\settings.minimax-executor.example.json")) {
            Copy-Item ".claude\settings.minimax-executor.example.json" $localPath
        }
        Configure-ExecutorProfile $localPath $ApiKey $ExecutorModel
        Write-Host "  [PASS] Legacy MiniMax-only local settings prepared" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] MiniMax token not provided; local executor profile was not credentialed" -ForegroundColor Yellow
    Write-Host "  Use the default Bash/Git Bash command:" -ForegroundColor Gray
    Write-Host "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --minimax-key 'YOUR_TOKEN_PLAN_KEY'" -ForegroundColor Cyan
}
Write-Host ""

Write-Step "[4/5] Initializing state directories..."
@(
    "obsidian\Memory\Decisions",
    "obsidian\Memory\Patterns",
    "obsidian\Memory\Errors",
    "obsidian\Memory\Stories",
    "obsidian\Memory\Dashboard",
    ".taste\sessions",
    ".taste\workflow-runs",
    ".taste\specs",
    ".minimaxing\state\events",
    ".minimaxing\state\snapshots"
) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
Write-Host "  [PASS] State directories ready" -ForegroundColor Green
Write-Host ""

Write-Step "[5/5] Static reminder..."
Write-Host "  [INFO] Windows native setup is a helper. Git Bash/WSL setup.sh is the canonical installer." -ForegroundColor Gray
Write-Host "  [INFO] Claude subscription auth is still separate: claude auth login" -ForegroundColor Gray
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run: claude" -ForegroundColor Gray
Write-Host "  2. If this is a fresh repo, run: /tastebootstrap" -ForegroundColor Gray
if ($Mode -eq "opusminimax") {
    Write-Host "  3. Then try: /opusminimax 'build a REST API'" -ForegroundColor Gray
} elseif ($Mode -eq "minimax") {
    Write-Host "  3. Legacy MiniMax-only override: /workflow 'build a REST API'" -ForegroundColor Gray
} elseif ($Mode -eq "opussonnet") {
    Write-Host "  3. Then try: /opussonnet 'build a REST API'" -ForegroundColor Gray
} else {
    Write-Host "  3. Then try: /opusworkflow 'build a REST API'" -ForegroundColor Gray
}
