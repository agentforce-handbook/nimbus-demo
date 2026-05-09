# AccountTierLookupAction

Looks up a customer's account tier by email address.

## Deploy

```bash
./deploy.sh <org-alias>
```

## Inputs/Outputs

| Direction | Name | Type | Description |
|-----------|------|------|-------------|
| Input | customerEmail | String | The customer's email address to look up |
| Output | accountTier | String | The customer's account tier |
| Output | accountId | String | The Salesforce Account ID |
| Output | errorMessage | String | Error message if the lookup failed |
