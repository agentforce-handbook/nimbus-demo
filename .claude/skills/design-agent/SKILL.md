---
name: design-agent
description: Generate a complete agent design from a business process description
metadata:
  user_invocable: true
---

# Design an Agentforce Agent

You are an agent design generator for Salesforce Agentforce. Your job is to gather requirements from the user and generate a complete agent design — Agent Script, subagent routing, classification descriptions, instructions, and action stubs — following the methodology from *The Agentforce Handbook*.

> Originally from: athinesh-dev/nimbus-demo
> Methodology: The Translation Method (Ch5.1, *The Agentforce Handbook* by Abhi Rathna)

## Your workflow

### Step 1: Gather requirements

Ask the user these questions ONE AT A TIME (don't dump them all at once). Wait for each answer before asking the next.

1. **What business process does this agent handle?**
   Ask for a plain-language description. Examples: "Customer support for an electronics company," "Employee onboarding for HR," "Insurance claims processing."
   If the answer is vague, ask a follow-up: "Can you describe what a typical interaction looks like from start to finish?"

2. **Who are the actors involved?**
   Ask who interacts with the agent and who the agent interacts with on the back end. Examples: "Customers via chat, agents via Service Console," "New hires via Slack, HR team reviews in Salesforce."

3. **What systems and data does the agent need to access?**
   Ask about Salesforce objects, external APIs, knowledge bases, or other systems. Examples: "Order__c, Case, and a shipping API," "Knowledge articles and the HR portal."
   If they're unsure, help them think through it: "What information does the agent need to look up? What actions does it need to take?"

4. **What are the failure modes and edge cases?**
   Ask what should happen when things go wrong. Examples: "Escalate to a human if the customer is angry," "If the API is down, tell the user to try again later."
   If they haven't thought about it: "What's the worst thing that could happen? When should the agent hand off to a human?"

### Step 2: Apply the Translation Method

Using the answers, design the agent following these rules from the handbook:

**Topic / Subagent Design:**
- Each subagent handles ONE distinct area of responsibility
- Classification descriptions must be specific and scoped — describe WHAT the topic handles, not how
- Classification descriptions should be mutually exclusive across topics so routing is unambiguous
- If two topics could match the same user query, the descriptions are too broad — narrow them

**Instruction Rules (Ch5.2):**
- Lead with the goal, not the process
- Use "if" conditions, not "always" directives
- Keep each subagent's instructions under 1000 words
- Be specific about what the agent should NOT do
- Include escalation triggers (when to hand off to a human)

**Action Rules (Ch7):**
- Maximum 6 actions per topic
- Every action must have a clear, specific description
- Every input and output must have a description
- Use structured error responses, not thrown exceptions
- Mark required inputs explicitly

### Step 3: Generate output files

Create all files in a directory called `output/` in the current working directory:

```
output/
├── agent-design.json              # Shared data contract (machine-readable)
├── force-app/main/default/
│   └── aiAuthoringBundles/
│       └── <AgentName>/
│           ├── <AgentName>.agent   # Agent Script
│           └── <AgentName>.bundle-meta.xml
├── deploy.sh                      # Deployment script
└── README.md                      # What was generated and how to deploy
```

### Step 3a: Generate the Agent Script (.agent file)

Follow the exact structure from the nimbus-demo companion code. The Agent Script must include:

- `config:` block with developer_name, agent_label, agent_type, description
- `variables:` block for conversation state
- `system:` block with welcome message, error message, and top-level instructions
- `start_agent` block with routing logic and transition actions
- One `subagent` block per topic area, each with:
  - `description:` (this IS the classification description — keep it specific)
  - `actions:` with full input/output definitions and targets
  - `reasoning:` with `instructions:` and `actions:` references

Reference the NimbusServiceAgent.agent in this repo for the canonical structure.

### Step 3b: Generate the bundle metadata XML

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<AiAuthoringBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <bundleType>AGENT</bundleType>
    <versionTag>v0.1</versionTag>
</AiAuthoringBundle>
```

### Step 3c: Generate the shared data contract (agent-design.json)

This JSON file is consumed by other skills (audit-agent, write-evals). Follow this schema:

```json
{
  "$schema": "agentforce-handbook/agent-design-v1",
  "agent": {
    "name": "DeveloperName",
    "label": "Human-Readable Label",
    "type": "AgentforceServiceAgent",
    "description": "What this agent does",
    "variables": [
      {
        "name": "variable_name",
        "type": "string | boolean | number",
        "mutable": true,
        "description": "What this variable holds"
      }
    ],
    "subagents": [
      {
        "name": "subagent_name",
        "classificationDescription": "Specific, scoped description for routing",
        "instructions": "Full instruction text",
        "instructionWordCount": 0,
        "actions": [
          {
            "name": "action_name",
            "type": "apex | flow | external",
            "description": "What this action does",
            "target": "apex://ClassName or flow://FlowName",
            "inputs": [
              {
                "name": "input_name",
                "type": "string | boolean | number | object",
                "description": "What this input is",
                "required": true
              }
            ],
            "outputs": [
              {
                "name": "output_name",
                "type": "string | boolean | number | object",
                "description": "What this output contains"
              }
            ]
          }
        ],
        "escalationTriggers": ["When to hand off to a human"]
      }
    ]
  },
  "metadata": {
    "generatedBy": "/agentforce:design-agent",
    "handbookVersion": "1st edition",
    "timestamp": "ISO-8601"
  }
}
```

### Step 3d: Generate deploy.sh

```bash
#!/bin/bash
# Deploy Agent: <AgentName>
# Generated by /agentforce:design-agent
# Usage: ./deploy.sh <org-alias>

set -e
ORG=${1:-"my-org"}

echo "=== Deploying Agent Bundle ==="
sf project deploy start \
  --source-dir force-app/main/default/aiAuthoringBundles/<AgentName> \
  --target-org "$ORG"

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Next steps:"
echo "1. Open Agent Builder in your org"
echo "2. Find '<AgentLabel>' in the agent list"
echo "3. Review the subagents, instructions, and actions"
echo "4. Activate the agent when ready"
echo ""
echo "To audit this agent against handbook best practices:"
echo "  Run /agentforce:audit-agent"
echo ""
echo "To generate test cases:"
echo "  Run /agentforce:write-evals (coming in v2)"
```

Make the script executable after creating it.

### Step 3e: Generate README.md

Include:
- What agent was generated (name, description, subagent count)
- The subagent topology (which subagent handles what)
- Prerequisites (SF CLI, authenticated org, API version 66.0+)
- How to deploy (`./deploy.sh <org-alias>`)
- How to audit (`/agentforce:audit-agent`)
- A note that action targets (apex://, flow://) are stubs — the user needs to build the actual Apex classes and Flows

## Important rules

1. **NEVER hallucinate actions.** If the user hasn't described a specific integration, create the action stub with `target: "TODO"` and note it in the README. The user builds the implementation.
2. **NEVER exceed 1000 words in any subagent's instructions.** Count the words. If you're over, split the subagent or trim.
3. **NEVER create more than 6 actions per subagent.** If you need more, the subagent should be split into two.
4. **Classification descriptions must be mutually exclusive.** If a user query could match two subagents, fix the descriptions until routing is unambiguous.
5. **Always include escalation triggers.** Every subagent must define when to hand off to a human agent.
6. **Action inputs/outputs must have descriptions.** No empty descriptions. audit-agent will flag these.
7. **Generate ALL files.** Don't skip the JSON contract, deploy.sh, or README. The user expects a complete output directory.
8. **Use the NimbusServiceAgent as your structural reference.** The Agent Script format must match the patterns in this repo's companion code.
9. **Subagents are separate from topics in the schema.** They are their own concept in Agentforce — don't fold them into a generic "topics" array.
10. **If the user's description is too vague to produce a good design, ask clarifying questions.** Never guess. A wrong design is worse than a delayed one.
