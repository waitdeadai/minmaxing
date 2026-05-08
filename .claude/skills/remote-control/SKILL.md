---
name: remote-control
description: Diagnose Claude Code native Remote Control safely inside the minmaxing harness. In this project, /remote-control is a readiness/troubleshooting skill; start the live native Remote Control server from a shell with claude remote-control.
argument-hint: [name/status/troubleshoot]
disable-model-invocation: true
---

# /remote-control

Use Claude Code's native Remote Control. This project route is a readiness and
troubleshooting skill; in other words, a readiness and troubleshooting skill
only. It does not start a live Remote Control session.

In this harness, typing `/remote-control` runs this skill, so it can shadow any
native slash command with the same name. To actually activate live Remote
Control, run the native CLI server command from a shell:

```bash
claude remote-control
```

Then open `https://claude.ai/code` or the Claude mobile app and connect to the
local session.

## Native Commands

Claude Code exposes the native Remote Control server from the CLI:

- Live server waiting for browser/mobile connections: `claude remote-control`
- Useful options: `--name`, `--permission-mode`, `--spawn`, and `--capacity`
- Local readiness/troubleshooting in this harness: `/remote-control`

The remote surface is `claude.ai/code` or the Claude mobile app. The Claude Code
process keeps running locally on this machine, with the same filesystem, tools,
MCP servers, project settings, hooks, and permissions as the local session.

Do not rely on `claude --remote-control` or `claude --rc` unless your local
`claude --help` explicitly lists those flags. Claude Code 2.1.118 exposes
`claude remote-control` as the native live server command.

## Native-Only Boundary

Do not implement a custom remote server, websocket bridge, HTTP tunnel, or MCP control plane.
Do not add a browser automation backdoor for this route. Native Remote Control
uses outbound HTTPS through Anthropic and does not require inbound ports from
this harness.

Do not confuse this with `claude --remote` or Claude Code on the web. Remote
Control drives a local Claude Code process from another device; cloud sessions
run elsewhere and do not automatically inherit this local harness environment.

## Prerequisites

- Claude Code must be current enough for Remote Control.
- Authentication must be a claude.ai subscription login from `claude auth login`
  or `/login`.
- API-key and inference-only token auth do not satisfy Remote Control:
  `ANTHROPIC_API_KEY`, Console/API-key auth, `claude setup-token`, and
  `CLAUDE_CODE_OAUTH_TOKEN` are blockers for this feature.
- Shared project settings must not set `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`,
  `DISABLE_TELEMETRY`, `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`,
  `CLAUDE_CODE_USE_FOUNDRY`, or `disableRemoteControl`.
- Team and Enterprise organizations may require an admin-side Remote Control
  toggle before the feature is eligible.
- Run `claude` in the project at least once and accept workspace trust before
  expecting a remote session to attach cleanly.

## Checks

Run the static doctor before blaming the harness:

```bash
bash scripts/remote-control-doctor.sh --static --json
```

Run the no-secret contract gate before release:

```bash
bash scripts/remote-control-smoke.sh --fixtures
```

These checks never start a live Remote Control session and must not claim
runtime proof. They only verify that committed project settings, docs, scripts,
fixtures, and eval metadata do not block or misrepresent native RC.

## Runtime Use

From inside this harness session, `/remote-control` is diagnostic only:

```text
/remote-control
```

To start live Remote Control, run this from a shell in the project root:

```bash
claude remote-control
```

For this trusted-local workspace, a typical explicit launch is:

```bash
claude remote-control --name ultimateminimax --permission-mode bypassPermissions
```

Keep that command running, then connect from `https://claude.ai/code`.

Use `claude --version` and `/status` locally when troubleshooting account,
organization, or auth state. If Claude reports API-key, Console, third-party
provider, inference-only token, stale organization, or disabled-policy status,
fix that auth state first.

## Security Notes

This workspace defaults to trusted-local `bypassPermissions` for the operator's
solo workflow. Remote Control exposes that same local session authority from
web/mobile, so treat an active RC session like sitting at the terminal.

Keep the committed deny rules for:

- `Read(./.env)`
- `Read(./.env.*)`
- `Read(./.claude/settings.local.json)`
- `Read(./.claude/*.local.json)`
- `Read(./secrets/**)`

Never paste Remote Control URLs, QR tokens, credentials, `.env` contents, or
local profile secrets into artifacts, logs, PRs, or chats. Static harness evidence is compatibility evidence, not proof that a live browser or mobile session connected.

## Troubleshooting

- `Remote Control requires a claude.ai subscription`: log in with
  `claude auth login` and choose the claude.ai path; unset `ANTHROPIC_API_KEY`
  for the session.
- `Remote Control requires a full-scope login token`: do not use
  `CLAUDE_CODE_OAUTH_TOKEN` or `claude setup-token`; refresh with full
  claude.ai login.
- `Remote Control is not yet enabled for your account`: unset
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, `DISABLE_TELEMETRY`,
  `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, and
  `CLAUDE_CODE_USE_FOUNDRY`, then log out and back in if needed.
- `Remote Control is disabled by your organization's policy`: check `/status`
  and the Team/Enterprise admin toggle. A managed `disableRemoteControl`
  setting is a policy decision, not a harness bug.
- `Remote credentials fetch failed`: rerun with `claude remote-control --verbose`
  after confirming claude.ai login, active subscription, and outbound HTTPS
  access to Anthropic on port 443.
