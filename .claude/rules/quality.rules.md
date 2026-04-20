# Quality Rules

## Hard Gates (No Exceptions)

These always block progression:

- **ESLint error-mode**: warnings are failures, must be fixed
- **Tests must pass**: 100% pass rate, no skipped tests
- **No silent failures**: always report status explicitly
- **Pre-commit hooks must pass**: before any commit
- **Circuit breakers**: if quality gate fails, block progression
- **Never bypass validation**: never use --no-verify

## Validation Rules

### Pre-Edit Validation
- Type check passes
- Basic lint check passes
- File path is within workspace
- Change is not destructive without confirmation

### Post-Edit Validation
- Verify change matches intent
- Run relevant tests
- Verify no regressions in affected files

## Failure Protocol

When a quality gate fails:

1. **Report what failed** — specific, not vague
   - "ESLint error: unused variable 'x' at line 42"
   - NOT "there's a lint issue"

2. **Explain why it failed**
   - "The variable 'x' is declared but never used"
   - NOT "it's wrong"

3. **Provide exact fix needed**
   - "Remove the unused variable declaration"
   - NOT "fix this"

4. **Do not proceed** until fixed
   - Block the edit
   - Do not accept "I'll fix it later"

## Validation Enforcement

| Gate | Blocking? | Exception? |
|------|-----------|------------|
| ESLint error | YES | Never |
| Test failure | YES | Never |
| Type error | YES | Never |
| Missing tests (new code) | YES | Never |
| Security issue | YES | Never |
| Silent failure | YES | Never |

## Anti-Patterns

- "It works, ship it" without tests → BLOCK
- Warnings as acceptable → BLOCK
- Silent failures → BLOCK
- Skipped tests for convenience → BLOCK
- Bypassing hooks with --no-verify → BLOCK
- "Good enough" mentality → BLOCK
