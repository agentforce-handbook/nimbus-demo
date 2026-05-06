/**
 * Test class for NimbusWarrantyCheckAction
 */
@isTest
private class NimbusWarrantyCheckActionTest {

    @TestSetup
    static void setup() {
        Nimbus_Device_Registration__c reg = new Nimbus_Device_Registration__c(
            Serial_Number__c = 'NIM-SN-001',
            Product_Name__c = 'NimbusPad Pro 12',
            Customer_Email__c = 'test@example.com',
            Purchase_Date__c = Date.today().addMonths(-6),
            Warranty_End_Date__c = Date.today().addMonths(18),
            Coverage_Type__c = 'Standard'
        );
        insert reg;

        Nimbus_Device_Registration__c expiredReg = new Nimbus_Device_Registration__c(
            Serial_Number__c = 'NIM-SN-002',
            Product_Name__c = 'NimbusWatch Series 1',
            Customer_Email__c = 'test@example.com',
            Purchase_Date__c = Date.today().addYears(-3),
            Warranty_End_Date__c = Date.today().addDays(-30),
            Coverage_Type__c = 'Standard'
        );
        insert expiredReg;
    }

    @isTest
    static void testActiveWarranty() {
        NimbusWarrantyCheckAction.WarrantyRequest req = new NimbusWarrantyCheckAction.WarrantyRequest();
        req.serialNumber = 'NIM-SN-001';
        req.customerEmail = 'test@example.com';

        List<NimbusWarrantyCheckAction.WarrantyResponse> results =
            NimbusWarrantyCheckAction.checkWarranty(new List<NimbusWarrantyCheckAction.WarrantyRequest>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isUnderWarranty);
        System.assertEquals('NimbusPad Pro 12', results[0].productName);
        System.assertEquals('Standard', results[0].coverageType);
    }

    @isTest
    static void testExpiredWarranty() {
        NimbusWarrantyCheckAction.WarrantyRequest req = new NimbusWarrantyCheckAction.WarrantyRequest();
        req.serialNumber = 'NIM-SN-002';
        req.customerEmail = 'test@example.com';

        List<NimbusWarrantyCheckAction.WarrantyResponse> results =
            NimbusWarrantyCheckAction.checkWarranty(new List<NimbusWarrantyCheckAction.WarrantyRequest>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isUnderWarranty);
    }

    @isTest
    static void testNotFound() {
        NimbusWarrantyCheckAction.WarrantyRequest req = new NimbusWarrantyCheckAction.WarrantyRequest();
        req.serialNumber = 'NONEXISTENT';
        req.customerEmail = 'test@example.com';

        List<NimbusWarrantyCheckAction.WarrantyResponse> results =
            NimbusWarrantyCheckAction.checkWarranty(new List<NimbusWarrantyCheckAction.WarrantyRequest>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isUnderWarranty);
        System.assert(results[0].errorMessage != null);
    }
}
