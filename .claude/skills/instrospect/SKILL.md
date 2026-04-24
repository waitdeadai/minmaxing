# /instrospect

Compatibility alias for `/introspect`.

The canonical command is `/introspect`. This alias exists because the original request used `/instrospect`, and older muscle memory should still reach the same hard-gate self-audit protocol.

---

## Routing Rule

Always route `/instrospect` to `/introspect` with the same arguments and trigger mode.

Examples:
- `/instrospect pre-plan` -> `/introspect pre-plan`
- `/instrospect post-implementation` -> `/introspect post-implementation`
- `/instrospect after-test-failure` -> `/introspect after-test-failure`
- `/instrospect pre-push` -> `/introspect pre-push`
- `/instrospect` -> `/introspect manual`

## Required Behavior

Preserve the `/introspect` hard-gate contract:
- name concrete likely mistakes
- cite evidence checked
- audit assumptions
- look for counterexamples
- compare implementation against `SPEC.md`
- identify missing verification
- downgrade confidence when warranted
- block closeout when unresolved findings remain

## Compatibility Note

Prefer `/introspect` in new docs, prompts, and workflow artifacts. Keep `/instrospect` working as an alias, not as a separate mode with separate semantics.
