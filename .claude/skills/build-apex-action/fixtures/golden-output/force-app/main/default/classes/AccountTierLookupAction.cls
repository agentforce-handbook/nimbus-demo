public with sharing class AccountTierLookupAction {

    public class ActionRequest {
        @InvocableVariable(required=true description='The customer email address to look up')
        public String customerEmail;
    }

    public class ActionResponse {
        @InvocableVariable(description='The customer account tier (Bronze, Silver, Gold, Platinum)')
        public String accountTier;

        @InvocableVariable(description='The Salesforce Account ID')
        public String accountId;

        @InvocableVariable(description='Error message if the lookup failed')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Look Up Account Tier'
        description='Look up a customer account tier by email address'
        category='Account Management'
    )
    public static List<ActionResponse> execute(List<ActionRequest> requests) {
        List<ActionResponse> responses = new List<ActionResponse>();
        for (ActionRequest req : requests) {
            ActionResponse resp = new ActionResponse();
            try {
                List<Contact> contacts = [
                    SELECT Account.Id, Account.Tier__c
                    FROM Contact
                    WHERE Email = :req.customerEmail
                    WITH USER_MODE
                    LIMIT 1
                ];

                if (contacts.isEmpty()) {
                    resp.errorMessage = 'No account found for email: ' + req.customerEmail;
                } else {
                    resp.accountId = contacts[0].Account.Id;
                    resp.accountTier = contacts[0].Account.Tier__c;
                }
            } catch (Exception e) {
                resp.errorMessage = 'Error: ' + e.getMessage();
            }
            responses.add(resp);
        }
        return responses;
    }
}
