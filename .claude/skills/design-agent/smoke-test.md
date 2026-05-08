# Smoke Test: design-agent

## Prerequisites
- Salesforce CLI (`sf`) installed and authenticated
- A scratch org or sandbox with Agentforce enabled
- API version 66.0+

## Test Protocol

### Test 1: Simple Agent (Happy Path)
1. Run `/agentforce:design-agent`
2. When asked about the business process, answer: "Customer support for a SaaS company. Billing questions, account access issues, and feature requests."
3. Answer the remaining 3 questions with reasonable detail
4. Verify output/ directory is created with all expected files
5. Run `./validate.sh output/` — should pass with 0 errors
6. Deploy to scratch org: `./output/deploy.sh my-scratch-org`
7. Open Agent Builder — verify the agent appears with correct subagents

### Test 2: Complex Agent (Multi-subagent)
1. Run `/agentforce:design-agent`
2. Describe a complex process: "Insurance claims — filing, status checks, document uploads, dispute resolution"
3. Provide detailed actors, systems, and failure modes
4. Verify 4+ subagents are generated
5. Verify no subagent exceeds 1000 words in instructions
6. Verify no subagent has more than 6 actions
7. Verify classification descriptions are mutually exclusive
8. Run `./validate.sh output/` — should pass
9. Deploy and verify in Agent Builder

### Test 3: Vague Input (Clarification)
1. Run `/agentforce:design-agent`
2. When asked about business process, answer: "Help customers"
3. Verify the skill asks a follow-up question rather than generating output
4. Provide a more specific answer
5. Verify the rest of the flow continues normally

### Pass Criteria
- All files generated (agent script, bundle XML, agent-design.json, deploy.sh, README.md)
- validate.sh passes with 0 errors
- Agent deploys to scratch org on first try without errors
- Agent appears in Agent Builder with correct structure
- No hallucinated actions (all targets are either real or marked TODO)
- Vague input triggers clarification, not garbage output
