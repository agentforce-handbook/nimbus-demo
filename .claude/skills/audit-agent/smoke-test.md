# Smoke Test: audit-agent

## Prerequisites
- An agent-design.json file (from design-agent) or an SFDX project with .agent files

## Test Protocol

### Test 1: Clean Agent (Expected Score: A)
1. Use fixtures/input_simple.json agent design (well-formed, all rules pass)
2. Save the agent_design field as `output/agent-design.json`
3. Run `/agentforce:audit-agent` pointing at that file
4. Verify score is A (0 FAIL, 0 WARN)
5. Verify all three output files exist (JSON, MD, HTML)
6. Run `./validate.sh output/` — should pass
7. Open audit-report.html in browser — verify it renders correctly

### Test 2: Flawed Agent (Expected Score: F)
1. Use fixtures/input_complex.json agent design (multiple violations)
2. Run `/agentforce:audit-agent`
3. Verify it catches:
   - action-count (7 actions, limit 6)
   - action-description (empty description on action3)
   - input-description (empty description on action4 input)
   - escalation-defined (empty escalation triggers)
   - classification-specificity (vague descriptions)
   - classification-overlap (both describe "everything")
   - instruction-no-always (repeated "always" usage)
4. Verify score is D or F
5. Verify fix suggestions reference specific chapters
6. Run `./validate.sh output/` — should pass (the report itself is valid even if the agent isn't)

### Test 3: Audit NimbusServiceAgent (Real Agent)
1. Run `/agentforce:audit-agent` pointing at the nimbus-demo repo's NimbusServiceAgent.agent
2. Verify it parses the Agent Script format correctly
3. Review the scorecard — NimbusServiceAgent should score well (it follows the handbook patterns)
4. Verify any UNKNOWN results are clearly marked (fields not present in .agent format)

### Test 4: Auto-detect (No Path Given)
1. Run design-agent first to generate output/agent-design.json
2. Then run `/agentforce:audit-agent` without specifying a path
3. Verify it auto-detects and audits the output/agent-design.json

### Test 5: No Agent Found
1. Run `/agentforce:audit-agent` in an empty directory
2. Verify it asks for a path instead of producing garbage

### Pass Criteria
- All three output files generated (JSON, MD, HTML)
- validate.sh passes
- Score matches expected (A for clean, D/F for flawed)
- JSON report has correct counts (passed + failed + warnings = total)
- Every FAIL has a fix suggestion
- Every rule has a chapter reference
- HTML is self-contained (no external resources)
- Composability works (reads design-agent output automatically)
- .agent file parsing produces reasonable results
