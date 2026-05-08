# Smoke Test: build-apex-action

## Prerequisites
- Salesforce CLI (`sf`) installed and authenticated
- A scratch org or sandbox
- API version 66.0+

## Test Protocol

### Test 1: Simple SOQL Action (Happy Path)
1. Run `/agentforce:build-apex-action`
2. Describe: "Look up a customer's account tier by email address"
3. Inputs: customerEmail (String, required)
4. Outputs: accountTier (String), accountId (String), errorMessage (String)
5. Data source: SOQL on Account via Contact email
6. Verify output/ directory has: .cls, .cls-meta.xml, Test.cls, Test.cls-meta.xml, deploy.sh, README.md
7. Run `./validate.sh output/` — should pass with 0 errors
8. Deploy: `./output/deploy.sh my-scratch-org`
9. Verify tests pass: check the test run output for 90%+ coverage

### Test 2: External API Action
1. Run `/agentforce:build-apex-action`
2. Describe: "Check real-time inventory for a product SKU via warehouse API"
3. Provide inputs/outputs with external API details
4. Verify Named Credential pattern is used (callout:NamedCred/endpoint)
5. Verify HttpCalloutMock is used in the test class
6. Run `./validate.sh output/` — should pass
7. Deploy and verify (note: external callout won't work without Named Credential setup)

### Test 3: Vague Input (Clarification)
1. Run `/agentforce:build-apex-action`
2. Describe: "Get some data"
3. Verify the skill asks clarifying questions
4. Verify it does NOT generate code from vague input

### Pass Criteria
- All files generated (.cls, .cls-meta.xml, Test.cls, Test.cls-meta.xml, deploy.sh, README.md)
- validate.sh passes with 0 errors
- Every @InvocableVariable has a description
- Uses `with sharing`
- Has errorMessage output
- Uses try/catch, never throws to caller
- Test class has 2+ test methods with real assertions
- Deploys to scratch org on first try
- Tests pass with 90%+ coverage
- Follows NimbusWarrantyCheckAction pattern exactly
