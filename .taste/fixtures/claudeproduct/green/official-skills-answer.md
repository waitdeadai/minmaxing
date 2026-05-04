<!-- scorecard: green -->

## Claude Product Question
- Question Class: howto
- User Question: How do we create a Claude Code skill?

## Source Policy
- Primary sources: official Anthropic/Claude docs
- Docs index checked: yes
- Freshness requirement: current

## Source Ledger
- Cited:
  - https://code.claude.com/docs/en/skills - says Claude Code skills live under `.claude/skills/<skill-name>/SKILL.md` and can be invoked with slash syntax.
  - https://claude.com/docs/skills/how-to - documents custom skill structure, frontmatter, references, assets, and scripts.
- Reviewed But Not Cited:
  - https://code.claude.com/docs/llms.txt - used only to discover the current docs page.
- Rejected:
  - Community snippets - useful leads but not authority for product behavior.

## Answer
Create `.claude/skills/my-skill/SKILL.md`, add `name` and `description`
frontmatter, then write the procedure. Use supporting files for detailed
references or scripts. Invoke it with `/my-skill` after Claude Code detects it.

## Harness Implication
- Route: /webresearch
- Repo impact: docs
- Follow-up gate: none

## Confidence
- Level: high
- Downgrade: none
