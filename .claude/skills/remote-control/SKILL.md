---
name: remote-control
description: Use Claude Code native Remote Control (/remote-control, /rc, claude --remote-control, claude remote-control) safely inside the minmaxing harness without custom network control planes, API-key auth, or static runtime overclaims.
argument-hint: [name/status/troubleshoot]
disable-model-invocation: true
---

# /remote-control

Use Claude Code's native Remote Control. This route exists to keep the harness
compatible with the official Claude Code and Claude Code CLI feature, not to
build a separate remote-control server.

## Native Commands

Claude Code exposes the same native Remote Control surface in three useful
modes:

- Existing interactive session: `/remote-control` or `/rc`
- Interactive CLI launch with RC enabled: `claude --remote-control` or `claude --rc`
- CLI server mode waiting for browser/mobile connections: `claude remote-control`

The remote surface is `claude.ai/code` or the Claude mobile app. The Claude Code
process keeps running locally on this machine, with the same filesystem, tools,
MCP servers, project settings, hooks, and permissions as the local session.

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

From inside an existing Claude Code session:

```text
/remote-control
/rc
```

From a shell in the project root:

```bash
claude --remote-control
claude remote-control
```

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
