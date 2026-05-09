# Agent Audit Report: SampleServiceAgent

**Score: A** (17/17 rules passed, 0 warnings)
**Audited:** 2026-05-08T12:00:00Z
**Source:** agent-design.json

## Summary
| Status | Count |
|--------|-------|
| pass   | 17    |
| fail   | 0     |
| warn   | 0     |

## Results

### fail (fix before shipping)
(none)

### warn (review recommended)
(none)

### pass
- instruction-length: All subagents under 1000 words
- instruction-goal-first: Instructions lead with goals
- instruction-no-always: No excessive 'always' directives
- instruction-has-negatives: Negative constraints specified
- action-count: All subagents have 6 or fewer actions
- action-description: All actions have descriptions
- input-description: All inputs have descriptions
- output-description: All outputs have descriptions
- error-output: All actions have error message outputs
- action-target: All action targets are specified
- classification-specificity: All classifications are specific
- classification-overlap: No overlapping classifications
- escalation-defined: All subagents have escalation triggers
- agent-has-description: Agent description present
- subagent-has-description: All subagents have classification descriptions
- has-welcome-message: Welcome message defined
- has-error-message: Error message defined
