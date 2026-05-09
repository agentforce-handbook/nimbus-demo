# SampleSaaSAgent

Customer support agent for a small SaaS company. Handles billing, account access, and feature requests.

## Deploy

```bash
./deploy.sh <org-alias>
```

## Subagents

| Subagent | Purpose |
|----------|---------|
| billing_support | Invoice lookup, refunds, payment issues |
| account_access | Password resets, login help, SSO issues |
| feature_requests | Feature requests, product feedback, roadmap questions |
