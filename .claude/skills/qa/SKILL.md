# /qa

Browser-based E2E QA with Playwright. Pass/Fail only — no "mostly works", no "looks okay".

**Use when:** User says "QA this", "test this feature", "browser test", "E2E test", "verify this works".

**Prerequisites:** `npx playwright test` must work in the project.

---

## Playwright E2E Protocol

### Step 1: Ensure Playwright is Available

```bash
npx playwright --version || npm install -D @playwright/test && npx playwright install chromium
```

### Step 2: Create/Run Test

For UI verification, write a Playwright test:

```javascript
// e2e/qa-[feature].spec.js
const { test, expect } = require('@playwright/test');

test('feature works', async ({ page }) => {
  await page.goto('http://localhost:3000');
  // ... test steps
  await expect(page.locator('.result')).toHaveText('expected');
});
```

Run with:
```bash
npx playwright test e2e/qa-[feature].spec.js --reporter=line
```

### Step 3: Pass/Fail Verification

- **PASS** = test exits with code 0
- **FAIL** = test exits with non-zero OR assertion error

### Step 4: Atomic Bug Fix

If test fails, fix the bug (not the test) and re-run.

---

## QA Output Format

```
## QA Results: [Feature]
- Result: PASS | FAIL
- Evidence: npx playwright test output
- Fix: [file:line] if failed
```

---

## Anti-Patterns

- Modifying tests to pass instead of fixing code → BLOCK
- Skipping E2E when UI involved → BLOCK
- "Looks okay" without running test → BLOCK
