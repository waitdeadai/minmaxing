# Metacognition Harness Moat Research

Date: 2026-05-03
Repo: `/home/fer/Music/ultimateminimax`
Mode: `/deepresearch` comprehensive, research artifact only

## Collaborative Research Plan

### Deliverable

Produce a research-backed thesis for adding a model-agnostic metacognition layer
to the minmaxing harness inside Claude Code: what frontier labs are doing, what
is actually supported by evidence, where naive self-reflection fails, and which
minimal harness upgrades could create a defensible effectiveness moat.

### Branches

- Frontier lab patterns: OpenAI, Anthropic, Google DeepMind, Meta/FAIR, and
  DeepSeek where public evidence is strong.
- Failure evidence: cases where self-correction or introspection is weak,
  confabulated, brittle, or safety-sensitive.
- Harness mapping: how the repo's current `/introspect`, `/deepresearch`,
  `SPEC.md`, evals, run metrics, trace ledger, and effectiveness gates can
  absorb metacognition without speculative architecture.
- Moat design: how to make the harness improve any model that runs inside it,
  independent of provider-native reasoning features.

### Source Classes

- Official model/system cards and product docs.
- Official research blogs from major labs.
- Peer-reviewed or preprint papers for self-correction, self-rewarding, and
  reasoning RL.
- Local repo contracts: `AGENTS.md`, `README.md`, `.claude/skills/introspect`,
  `.claude/skills/deepresearch`, `scripts/test-harness.sh`, and current state.

### Stop Condition

Research is sufficient when it can distinguish:

- native model metacognition from harness-level metacognition,
- useful reflection from placebo reflection,
- trace monitoring from hidden chain-of-thought exposure,
- and a first implementation slice from a larger research program.

## Executive Thesis

The biggest labs are converging on a simple truth: raw next-token completion is
not enough for hard work. The frontier pattern is to surround or train the model
with mechanisms that allocate more thought, inspect intermediate reasoning,
reason over policies, self-correct, compare hypotheses, and preserve oversight.

The moat for minmaxing is not to copy a lab's hidden chain-of-thought system.
That would be provider-dependent and fragile. The moat is a harness-level
metacognition protocol that makes any model behave more like an effective
operator:

1. Know what kind of task it is doing.
2. Decide how much reasoning budget and independent checking it deserves.
3. Externalize auditable summaries, assumptions, source ledgers, risks, and
   verification claims.
4. Run targeted self-critique before irreversible decisions.
5. Learn from verified outcomes, not from vibes or unverified self-reports.

In other words: model companies are building metacognition into the model.
Minmaxing can build metacognition around the model, with evidence gates.

## What The Frontier Labs Are Doing

### OpenAI: Routed Reasoning, Deliberative Alignment, And CoT Monitoring

OpenAI's GPT-5 system card describes a unified system with a fast model, deeper
reasoning models, and a real-time router that selects the right path based on
conversation type, complexity, tool needs, and user intent. It also names
parallel test-time compute for the "pro" thinking variant. This is a direct
productization of metacognitive routing: the system decides when normal
responding is enough and when deeper reasoning should be invoked.

OpenAI's o3/o4-mini system card says the o-series models are trained with
large-scale reinforcement learning on chains of thought, can use tools during
their reasoning, and can reason over safety policies through deliberative
alignment. That matters for minmaxing because policy reasoning should not be a
last-minute refusal filter; it should happen inside the planning loop.

OpenAI's late-2025 and 2026 safety research puts chain-of-thought monitorability
at the center of scalable oversight. Their position is not "thinking is always
truthful"; it is "reasoning traces can provide monitoring signal, but that signal
must be measured, preserved, and protected from optimization pressure." The most
useful harness lesson is to monitor the agent's auditable process artifacts and
behavior, not to overtrust the model's private thought.

Harness implication:

- Add metacognitive routing before work starts: shallow response, webresearch,
  deepresearch, workflow, parallel, agentfactory, or blocked.
- Preserve monitorable artifacts: research ledger, assumptions, critique,
  verification command evidence, changed-line trace, and outcome.
- Avoid applying optimization pressure to hidden CoT. Score visible process
  artifacts and verified behavior instead.

### Anthropic: Extended Thinking, Adaptive Reasoning, And Real Introspection Research

Anthropic exposes extended/adaptive thinking as an API feature with explicit
thinking controls, evolving toward adaptive effort on newer Claude models. The
docs also make the operational tradeoffs visible: thinking consumes tokens,
thinking summaries can be generated by another model, and thinking blocks may or
may not persist across turns depending on model/version.

Anthropic's introspection research is especially relevant to your idea. They
tested whether Claude models can report on internal states rather than merely
act introspective. The result is important but modest: they found evidence of
some functional introspective awareness, with Claude Opus 4/4.1 strongest in
their tests, but the best injection protocol only worked around 20% of the time
and could produce hallucinations when concept strength was wrong.

Harness implication:

- Treat model self-reports as evidence candidates, not ground truth.
- Build a "metacognition record" that asks the model to report uncertainty,
  assumptions, attention gaps, and likely mistakes, then verifies those claims
  against repo state, sources, and tests.
- Do not require every model to expose thinking blocks. The harness should work
  with hidden-reasoning providers by requesting concise reasoning summaries and
  checking artifacts externally.

### Google DeepMind: Thinking Modes, Deep Think, And Self-Correction RL

Google's Gemini 3.1 Deep Think page frames Deep Think as a specialized reasoning
mode for science, research, engineering, mathematical rigor, logical-error
identification, experimental-data evaluation, and complex design optimization.
The public product message is that harder domains deserve a different
reasoning mode, not merely a bigger single answer.

DeepMind's older paper "Large Language Models Cannot Self-Correct Reasoning Yet"
is a critical counterweight: intrinsic self-correction, where a model revises
based only on its own capabilities and no external feedback, can fail or even
degrade reasoning performance. DeepMind later introduced SCoRe, a multi-turn RL
method trained under the model's own distribution of self-generated correction
traces, to make self-correction actually work better at test time.

Harness implication:

- Naive "review your answer and improve it" is not enough.
- Reflection should be grounded in external discriminators: tests, source
  ledger, repo diff, specs, static evals, runtime evidence, and explicit
  contradiction checks.
- Minmaxing can approximate SCoRe at the harness level by logging
  generate -> critique -> verify -> outcome traces and using them as eval
  fixtures or prompt-contract upgrades only when the outcome is verified.

### Meta/FAIR: Self-Rewarding And Meta-Judging

Meta/FAIR work on meta-rewarding language models focuses on the model judging
its own judgments, not only judging answers. Their reported result is that a
self-improvement loop can improve both judgment and instruction following.

Harness implication:

- The harness should not only ask "was the answer good?" It should ask "was the
  review/evaluation itself good?"
- Add second-order evals for minmaxing: did `/introspect` catch the real risk,
  did `/verify` cite actual evidence, did the estimate include blockers, did
  the source ledger contain real sources, did the closeout avoid unsupported
  confidence?

### DeepSeek: RL-Induced Reflection And Strategy Adaptation

DeepSeek-R1's paper reports that pure RL can incentivize reasoning patterns
including self-reflection, verification, and dynamic strategy adaptation without
human-labeled reasoning trajectories. This supports the broader thesis that
metacognitive behavior can be learned or elicited when the training/evaluation
loop rewards correct process, not only fluent answers.

Harness implication:

- A model-agnostic harness can create its own outer-loop reward structure:
  artifacts that pass tests, claims tied to evidence, risks caught before
  damage, and reusable lessons promoted only after verification.
- This is the path to making smaller or cheaper models more effective inside
  minmaxing than they are raw.

## Conflicting Evidence And Resolution

### Claim: LLMs Can Self-Correct

Evidence for:

- SCoRe shows self-correction can improve when trained with multi-turn RL under
  the model's own correction distribution.
- DeepSeek-R1 reports RL-induced self-reflection, verification, and strategy
  adaptation.
- Meta-rewarding suggests self-judgment can improve when the model also judges
  its judgments.

Evidence against:

- DeepMind's "Cannot Self-Correct Reasoning Yet" paper found intrinsic
  self-correction often fails or degrades performance in reasoning tasks.
- Anthropic introspection results are real but unreliable and prompt-sensitive.
- OpenAI emphasizes monitorability and control layers, not blind trust in
  self-reported reasoning.

Resolution:

The useful capability is not generic self-reflection. The useful capability is
reflection plus ground truth, verification, and process scoring. Minmaxing
should not add a vague "think about your thinking" step; it should add a
structured metacognition loop whose claims are checked.

### Claim: Exposing Reasoning Traces Improves Safety

Evidence for:

- OpenAI's monitorability work says reasoning traces can provide better signal
  than actions/final answers alone.
- Anthropic and Claude docs expose thinking summaries or blocks in some modes.

Evidence against:

- CoT monitorability can be fragile under training changes and optimization
  pressure.
- Newer provider APIs increasingly summarize, encrypt, omit, or adapt thinking
  rather than exposing raw reasoning uniformly.

Resolution:

Minmaxing should not depend on raw CoT access. It should define a stable
observable process layer: summaries, source ledgers, assumptions, verification
evidence, risk tables, and audit sidecars. That layer can be monitored across
OpenAI, Claude, Gemini, local models, and future providers.

## Harness Opportunity

The existing repo already has many pieces of the moat:

- `/deepresearch` requires a collaborative plan, iterative search/read/refine,
  source ledger, conflicting evidence, follow-up research, and pre-plan
  introspection.
- `/introspect` requires likely mistakes, evidence checked, assumption audit,
  counterexamples, missing verification, confidence downgrades, changed-line
  trace, and blocker decisions.
- `scripts/harness-eval.sh --json` provides local no-network static evals.
- `scripts/run-metrics.sh`, `scripts/session-insights.sh`, and
  `scripts/learning-loop.sh` already separate real evidence from insufficient
  data.
- `scripts/memory-eval.sh` already prevents stale memory promotion without
  verified evidence.
- `SPEC.md` is the active contract; `.taste/specs/` archives history.

What is missing is a first-class metacognition layer that unifies those pieces
into a loop the harness can measure.

## Proposed Moat: Metacognitive Control Plane

### 1. Metacognitive Router

Before work starts, classify the task:

- `answer`: direct answer, no artifact.
- `webresearch`: current fact lookup with citations.
- `deepresearch`: landscape/strategy/architecture research.
- `workflow`: repo-changing implementation.
- `parallel`: independent packet DAG with verified aggregation.
- `agentfactory`: governed runtime-bound agent.
- `blocked`: missing credentials, unsafe external action, or insufficient
  source truth.

Record:

- task class,
- why this class was chosen,
- expected evidence,
- reasoning budget,
- verification budget,
- and confidence threshold for closeout.

### 2. Reflection With Ground Truth

Replace generic self-critique with typed reflection prompts:

- Assumption audit: what am I assuming that could be false?
- Source audit: which claims lack source or repo evidence?
- Scope audit: am I overbuilding beyond the request or `SPEC.md`?
- Verification audit: what would prove this actually works?
- Risk audit: what can harm the user, repo, security, or production state?
- Estimate audit: is the estimate agent-native and critical-path based?

Each reflection item must resolve to:

- `verified`,
- `fixed`,
- `accepted risk`,
- `blocked`,
- or `rejected as unsupported`.

### 3. Monitorable Process Artifacts

Create minimal sidecars only where machine checks help:

- `.taste/metacognition/{run_id}/router.json`
- `.taste/metacognition/{run_id}/reflection.json`
- `.taste/metacognition/{run_id}/verification.json`
- `.taste/metacognition/{run_id}/outcome.json`

Keep Markdown as the human contract, but let scripts lint whether the model
actually did what it claimed.

### 4. Second-Order Evals

Add evals that judge the quality of the model's self-judgment:

- Did introspection find the seeded scope creep?
- Did it block after a failed test instead of closing out positively?
- Did it downgrade confidence when sources were weak?
- Did it reject unverified worker claims?
- Did it preserve `SPEC.md` lifecycle rules?
- Did it identify stale memory as stale?
- Did it avoid "more agents equals linear speedup" claims?

This is the harness-level analog of meta-rewarding.

### 5. Verified Learning Loop

Promote only verified metacognitive lessons:

- observation,
- failed or successful prediction,
- evidence command/source,
- artifact path,
- future guardrail,
- eval fixture if generalizable.

Do not promote raw self-reflection. Promote reflection that predicted or
prevented a real failure.

## First Implementation Slice

Smallest useful slice:

1. Add a `metacognition` research/design doc and keep `SPEC.md` untouched until
   implementation is requested.
2. Add one local static eval fixture that tests `/introspect` for metacognitive
   quality, not just presence of headings.
3. Add a small `scripts/metacognition-scorecard.sh --fixtures --json` that
   checks artifacts for:
   - task classification,
   - explicit assumptions,
   - evidence mapping,
   - confidence downgrade rules,
   - unresolved blocker behavior,
   - verified outcome requirement.
4. Wire the scorecard into `scripts/test-harness.sh` and
   `scripts/release-check.sh --static-only`.
5. Update `.claude/skills/introspect/SKILL.md`, `.claude/skills/workflow`, and
   README only enough to name the new metacognitive contract.

Out of scope for first slice:

- changing provider model settings,
- exposing hidden CoT,
- building a new agent runtime,
- training/fine-tuning models,
- replacing existing `/introspect`,
- broad memory-system refactors.

## Agent-Native Estimate For First Slice

- Estimate type: agent-native wall-clock.
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` on
  2026-05-03 reported `hardware_class=workstation`, `cores=16`, `ram_gb=32`,
  `codex_max_threads=10`, `recommended_ceiling=10`,
  `agent_teams_available=false`. This slice is mostly serial; use 1 lane.
- Agent wall-clock: optimistic 45 minutes / likely 90 minutes / pessimistic
  3 hours.
- Agent-hours: 1.5-3.
- Human touch time: 10-20 minutes to decide whether the metacognitive contract
  should become public README language or stay internal first.
- Calendar blockers: none expected unless pushing or waiting for CI.
- Critical path: freeze `SPEC.md` -> add fixture -> add scorecard -> wire
  harness -> update docs -> run static checks -> introspect -> closeout/archive.
- Confidence: medium-high. The repo already has most primitives; risk is
  overbuilding a second workflow surface instead of strengthening the existing
  `/introspect` contract.

## Pre-Plan Introspection

### Likely Mistakes

| Risk | Evidence Checked | Result |
| --- | --- | --- |
| Overtrusting model introspection | Anthropic reports only partial introspection and hallucination failure modes | Must treat introspection as candidate evidence |
| Adding vague reflection theater | DeepMind shows intrinsic self-correction can fail or degrade reasoning | Reflection must bind to tests/sources/repo evidence |
| Depending on raw CoT | OpenAI warns monitorability can be fragile; Anthropic docs summarize/omit/encrypt thinking in newer modes | Harness must monitor visible artifacts and behavior |
| Overbuilding a new command | Repo already has `/introspect`, `/deepresearch`, evals, and effectiveness gates | First slice should strengthen existing gates |
| Confusing local capacity with production moat | `parallel-capacity.sh` reports local workstation ceiling only | Moat should be model/provider/runtime agnostic |

### Assumption Audit

- Assumption: the user wants research and plan, not immediate implementation.
  Status: likely, because the request asked to deepresearch how companies are
  handling it and how it could benefit the harness.
- Assumption: metacognition should live in existing workflow gates.
  Status: supported by repo history and current contracts.
- Assumption: public source evidence is enough for a design plan.
  Status: medium. Exact proprietary lab internals are unavailable, so conclusions
  must be phrased as public-evidence inferences.

### Blocker Decision

PASS for research synthesis and planning. Implementation should wait for a
fresh `SPEC.md` and explicit approval or a `/workflow` continuation request.

## Source Ledger

### Cited

- OpenAI, "GPT-5 System Card" (2025-08-07):
  https://openai.com/index/gpt-5-system-card/
- OpenAI, "OpenAI o3 and o4-mini System Card" (2025-04-16):
  https://openai.com/index/o3-o4-mini-system-card/
- OpenAI, "Evaluating chain-of-thought monitorability" (2025-12-18):
  https://openai.com/index/evaluating-chain-of-thought-monitorability/
- OpenAI, "Reasoning models struggle to control their chains of thought, and
  that's good" (2026-03-05):
  https://openai.com/index/reasoning-models-chain-of-thought-controllability/
- Anthropic, "Emergent introspective awareness in large language models":
  https://www.anthropic.com/research/introspection
- Anthropic docs, "Building with extended thinking":
  https://platform.claude.com/docs/en/build-with-claude/extended-thinking
- Google DeepMind, "Gemini 3.1 Deep Think":
  https://deepmind.google/models/gemini/deep-think/
- Google DeepMind, "Large Language Models Cannot Self-Correct Reasoning Yet":
  https://deepmind.google/research/publications/48252/
- Kumar et al., "Training Language Models to Self-Correct via Reinforcement
  Learning" / SCoRe:
  https://arxiv.org/abs/2409.12917
- Wu et al., "Meta-Rewarding Language Models":
  https://arxiv.org/abs/2407.19594
- DeepSeek-AI et al., "DeepSeek-R1":
  https://arxiv.org/abs/2501.12948

### Reviewed But Not Cited In Main Thesis

- Google Developers, Gemini thinking API docs and 2.5 thinking updates.
- xAI docs/model pages and secondary reporting about Grok reasoning modes.
- Microsoft AutoGen research page on multi-agent conversation and future
  self-improving agents.

### Downweighted

- Secondary news on Grok/xAI reasoning, because the public technical evidence is
  thinner than for OpenAI, Anthropic, Google DeepMind, Meta/FAIR, and DeepSeek.
- Reddit discussions, because they are useful for practitioner signals but not
  strong enough for the core design claims.
