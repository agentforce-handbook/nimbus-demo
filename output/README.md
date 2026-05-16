# NimbusServiceAgent Eval Suite

This directory contains a complete evaluation suite for the NimbusServiceAgent, generated using the methodology from *The Agentforce Handbook* Chapter 11.

---

## What Was Generated

| File | Purpose |
|------|---------|
| `eval-suite.yaml` | All test cases (functional tests organized by subagent) |
| `eval-suite.md` | Human-readable test plan — start here to understand what's being tested |
| `eval-suite.json` | Machine-readable version for tooling and automation |
| `custom-scorers.yaml` | Custom scorer definitions for evaluating response quality |
| `red-team-tests.yaml` | Safety tests (hallucination, data leakage, prompt injection) |
| `smoke-test.yaml` | CI/CD subset — 13 high-priority cases to run on every change |
| `agent-eval-gate.yml` | GitHub Actions workflow that gates deployments on test results |
| `README.md` | This file — setup instructions |

---

## How to Import Test Cases into Testing Center

1. **Open Testing Center** in Salesforce Setup:
   - Go to Setup > AI > Agents > Testing Center

2. **Create a new test suite:**
   - Click "New Test Suite"
   - Name it `NimbusServiceAgent_Regression`
   - Set the target agent to `NimbusServiceAgent`

3. **Add test cases from eval-suite.yaml:**
   - For each test case in the YAML file, click "Add Test Case"
   - Set the **Utterance** to the `input` field value
   - Set the **Expected Topic** to `expected_behavior.topic_routed`
   - Set the **Expected Actions** to the actions listed in `expected_behavior.actions_invoked`
   - Add expected outcome assertions based on `response_must_include`

4. **Create the smoke test suite:**
   - Create another suite named `NimbusServiceAgent_SmokeTest`
   - Add only the 13 test cases listed in `smoke-test.yaml`

5. **Create the safety suite:**
   - Create a suite named `NimbusServiceAgent_RedTeam`
   - Add all test cases from `red-team-tests.yaml`

---

## How to Set Up CI/CD (GitHub Actions)

1. **Copy the workflow file:**
   ```bash
   cp output/agent-eval-gate.yml .github/workflows/agent-eval-gate.yml
   ```

2. **Add the required GitHub secret:**
   - Go to your repository Settings > Secrets and Variables > Actions
   - Click "New repository secret"
   - Name: `SFDX_AUTH_URL`
   - Value: Your staging org's SFDX auth URL

   To get your SFDX auth URL:
   ```bash
   sf org display --target-org your-staging-org --verbose
   ```
   Copy the "Sfdx Auth Url" value.

3. **How it works:**
   - On every pull request that changes agent files, the smoke test suite runs automatically
   - If the pass rate drops below 90%, the PR is blocked
   - On merge to main, the full regression suite AND safety suite run
   - Safety tests have a 95% pass threshold (stricter because safety failures are critical)

---

## How to Run the Smoke Test from the Command Line

```bash
# Authenticate to your org (if not already)
sf org login web --alias staging-org

# Deploy latest agent metadata
sf project deploy start --target-org staging-org

# Run the smoke test suite
sf agent test run \
  --api-name NimbusServiceAgent_SmokeTest \
  --target-org staging-org \
  --wait 15 \
  --output-dir ./eval-results \
  --result-format json

# Check results
cat eval-results/*.json | jq '.summary'
```

---

## How to Add Custom Scorers in Testing Center

Custom scorers let you evaluate response quality beyond just "did the right action fire?"

1. Go to Testing Center > Scorers > New Custom Scorer
2. For each scorer in `custom-scorers.yaml`:
   - Set the **Name** to the `name` field
   - Set the **Evaluation Criteria** to the `criteria` field (copy the full text)
   - Set the **Scale** to 0-5
   - Set the **Pass Threshold** to the `pass_threshold` value (3 for all scorers)
3. Assign scorers to your test suites:
   - `Brand Voice Compliance` — all suites
   - `Escalation Quality` — assign to tests with `resolution: correctly_escalated`
   - `Warranty Regulation Compliance` — warranty_service tests only
   - `Return Policy Accuracy` — general_faq tests that involve returns
   - `Identity Verification Enforcement` — order_inquiries and account_management tests

---

## How Much It Costs

| What | Flex Credits | USD (at $0.10/action) |
|------|-------------|----------------------|
| Full suite run (all tests) | ~2,490 | ~$12.45 |
| Smoke test only (CI/CD) | ~390 | ~$1.95 |

**Recommendation:** Run the smoke test on every PR (~$1.95). Run the full suite nightly or before releases (~$12.45). That's roughly $50-70/month for continuous quality assurance on your agent.

---

## Methodology

This eval suite follows the testing framework from *The Agentforce Handbook* Chapter 11 by Abhi Rathna. Key principles:

- **Test behaviors, not exact words.** Assertions check what the agent communicates, not specific phrasing.
- **Three utterance variations per test.** Polite, frustrated, and terse phrasings must all route correctly.
- **Negative assertions on every test.** What the agent must NOT say catches hallucination and data leaks.
- **Groundedness is the highest bar (0.9).** Confidently wrong answers are the most dangerous failure mode.
- **Safety tests are not optional.** Every eval run includes adversarial inputs.

For the full methodology, see Chapter 11 of *The Agentforce Handbook*.
