# Smoke Test: build-custom-connection

## Purpose
Verify that `/agentforce:build-custom-connection` produces deployable custom connection metadata from a user's requirements.

## Prerequisites
- Claude Code with the skill installed
- No Salesforce org needed (metadata generation only)

## Test Cases

### 1. Simple Connection (text choices only)

**Input:**
```
/agentforce:build-custom-connection
```

**Conversation flow:**
1. When asked "What is your client called?" → answer: `UniversalContainers`
2. When asked about response formats → answer: `Text choices`
3. When asked about special instructions → answer: `Keep responses under 160 characters`

**Expected output directory:**
```
output/
├── unpackaged/
│   ├── package.xml
│   ├── aiResponseFormats/
│   │   └── UniversalContainersChoices_UC01.aiResponseFormat
│   └── aiSurfaces/
│       └── UniversalContainers_UC01.aiSurface
├── sfdx-project.json
├── deploy.sh
└── README.md
```

**Verify:**
- [ ] Surface ID auto-generated as UC01
- [ ] package.xml has AiSurface and AiResponseFormat types
- [ ] .aiResponseFormat input field is valid JSON (single line)
- [ ] .aiSurface has surfaceType=Custom
- [ ] .aiSurface references the response format
- [ ] deploy.sh uses --metadata-dir (not --manifest)
- [ ] deploy.sh is executable
- [ ] Run `./validate.sh output` — all checks pass

### 2. Multi-format Connection

**Input:**
```
/agentforce:build-custom-connection
```

**Conversation flow:**
1. Client name: `AcmePortal`
2. Response formats: `Text choices, Choices with images, Time picker`
3. Special instructions: `Always use formal tone. Never show more than 5 choices.`

**Expected output:**
- 3 .aiResponseFormat files (Choices, ChoicesWithImages, TimePicker)
- 1 .aiSurface file referencing all 3 formats
- Surface ID: ACME01

**Verify:**
- [ ] All 3 response format files present
- [ ] Each has valid JSON in the input field
- [ ] AiSurface lists all 3 in responseFormats
- [ ] Special instructions appear in AiSurface instructions block
- [ ] Run `./validate.sh output` — all checks pass

### 3. Invalid Input Handling

**Input:**
```
/agentforce:build-custom-connection
```

**Conversation flow:**
1. Client name: (empty or just spaces)

**Expected behavior:**
- Skill should ask again, not proceed with empty name
- Should not generate files with empty/broken names

## Structural Validation

After each test, run:
```bash
cd .claude/skills/build-custom-connection && ./validate.sh /path/to/output
```

All checks should pass for valid inputs.
