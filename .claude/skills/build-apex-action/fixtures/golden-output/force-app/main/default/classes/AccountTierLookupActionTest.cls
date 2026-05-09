@IsTest
private class AccountTierLookupActionTest {

    @TestSetup
    static void setupData() {
        Account testAccount = new Account(Name = 'Test Corp', Tier__c = 'Gold');
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }

    @IsTest
    static void testHappyPath() {
        AccountTierLookupAction.ActionRequest req = new AccountTierLookupAction.ActionRequest();
        req.customerEmail = 'test@example.com';

        List<AccountTierLookupAction.ActionResponse> results =
            AccountTierLookupAction.execute(new List<AccountTierLookupAction.ActionRequest>{ req });

        Assert.areEqual(1, results.size());
        Assert.areEqual('Gold', results[0].accountTier);
        Assert.isNotNull(results[0].accountId);
        Assert.isNull(results[0].errorMessage);
    }

    @IsTest
    static void testNotFound() {
        AccountTierLookupAction.ActionRequest req = new AccountTierLookupAction.ActionRequest();
        req.customerEmail = 'nobody@example.com';

        List<AccountTierLookupAction.ActionResponse> results =
            AccountTierLookupAction.execute(new List<AccountTierLookupAction.ActionRequest>{ req });

        Assert.areEqual(1, results.size());
        Assert.isNull(results[0].accountTier);
        Assert.isTrue(results[0].errorMessage.contains('No account found'));
    }

    @IsTest
    static void testBulkExecution() {
        AccountTierLookupAction.ActionRequest req1 = new AccountTierLookupAction.ActionRequest();
        req1.customerEmail = 'test@example.com';

        AccountTierLookupAction.ActionRequest req2 = new AccountTierLookupAction.ActionRequest();
        req2.customerEmail = 'nobody@example.com';

        List<AccountTierLookupAction.ActionResponse> results =
            AccountTierLookupAction.execute(new List<AccountTierLookupAction.ActionRequest>{ req1, req2 });

        Assert.areEqual(2, results.size());
    }
}
