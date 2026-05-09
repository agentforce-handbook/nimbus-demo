/**
 * NimbusWarrantyCheckAction
 * Companion code for "The Agentforce Handbook" Chapter 7
 *
 * Invocable action that checks warranty status for a Nimbus product
 * by serial number. Used by the Warranty Service subagent.
 */
public with sharing class NimbusWarrantyCheckAction {

    public class WarrantyRequest {
        @InvocableVariable(required=true description='Product serial number')
        public String serialNumber;

        @InvocableVariable(required=true description='Customer email for verification')
        public String customerEmail;
    }

    public class WarrantyResponse {
        @InvocableVariable(description='Whether the product is under warranty')
        public Boolean isUnderWarranty;

        @InvocableVariable(description='Warranty expiration date')
        public String warrantyExpiry;

        @InvocableVariable(description='Type of warranty coverage')
        public String coverageType;

        @InvocableVariable(description='Name of the registered product')
        public String productName;

        @InvocableVariable(description='Error message if lookup failed')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Check Nimbus Warranty'
        description='Checks warranty status for a Nimbus product by serial number'
        category='Nimbus Service'
    )
    public static List<WarrantyResponse> checkWarranty(List<WarrantyRequest> requests) {
        List<WarrantyResponse> responses = new List<WarrantyResponse>();

        for (WarrantyRequest req : requests) {
            WarrantyResponse resp = new WarrantyResponse();

            try {
                // Look up device registration by serial number.
                // WITH USER_MODE enforces field-level security and object CRUD
                // for the running user. `with sharing` alone only enforces
                // record-level sharing rules.
                List<Nimbus_Device_Registration__c> registrations = [
                    SELECT Id, Serial_Number__c, Product_Name__c,
                           Purchase_Date__c, Warranty_End_Date__c,
                           Coverage_Type__c, Customer_Email__c
                    FROM Nimbus_Device_Registration__c
                    WHERE Serial_Number__c = :req.serialNumber
                    AND Customer_Email__c = :req.customerEmail
                    WITH USER_MODE
                    LIMIT 1
                ];

                if (registrations.isEmpty()) {
                    resp.isUnderWarranty = false;
                    resp.errorMessage = 'No device registration found for serial number '
                                       + req.serialNumber + ' with the provided email.';
                } else {
                    Nimbus_Device_Registration__c reg = registrations[0];
                    resp.productName = reg.Product_Name__c;
                    resp.coverageType = reg.Coverage_Type__c;
                    resp.warrantyExpiry = String.valueOf(reg.Warranty_End_Date__c);
                    resp.isUnderWarranty = reg.Warranty_End_Date__c >= Date.today();
                }
            } catch (Exception e) {
                resp.isUnderWarranty = false;
                resp.errorMessage = 'Error checking warranty: ' + e.getMessage();
            }

            responses.add(resp);
        }

        return responses;
    }
}
