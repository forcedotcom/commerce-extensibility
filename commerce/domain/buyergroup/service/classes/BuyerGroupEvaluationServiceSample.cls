/**
 * BuyerGroupEvaluationServiceSample is a sample implementation of the BuyerGroupEvaluationService used to determine buyer group IDs for a user (guest or logged-in).
 * The use case for this sample implementation is as follows:
 * - Out-of-the-box buyer groups based on account, market, and data cloud segment should be returned for both logged-in and guest users.
 * - In addition, if the user is a guest or logged-in, then the buyer groups associated with the active postal code stored using deviceId should also be returned.
 * - For logged-in users, the buyer groups associated with the BillingPostalCode and ShippingPostalCode of the Account linked to the user are also returned.
 * 
 * Data model changes to support the sample code are as follows:
 * - PostalCode__c: Stores the supported postal codes in the PostalCode field.
 * - Active_PostalCode__c: Stores the association between deviceId (Guest UUID cookie value) and PostalCode__c. 
 *                          This can typically be populated via a custom LWC component where a customer chooses a postal code from a list of available postal codes.
 * - Postal_Code_Buyer_Group__c: A junction entity that stores a static mapping between PostalCode__c and the buyer groups associated with it.
 * 
 * Important considerations in the code below:
 * - Buyer group responses should be cached using Org Cache to support low latency. 
 * - No more than MAX_BUYER_GROUPS should be returned by the code. 
 */
public without sharing class BuyerGroupEvaluationServiceSample extends commercebuygrp.BuyerGroupEvaluationService {

    private static Integer MAX_BUYER_GROUPS = 30;

    public override commercebuygrp.BuyerGroupResponse getBuyerGroupIds(commercebuygrp.BuyerGroupRequest request) {
        String currentUserId = UserInfo.getUserId(); // Gets the current user ID; could be a logged-in or guest user
        String webstoreId = request.getStoreId(); // Gets the webstore record ID
        String accountId = request.getAccountId(); // Gets the account ID of the user
        String siteId = ((String) [SELECT SiteId FROM WebstoreNetwork WHERE WebstoreId = :webstoreId][0].get('SiteId')).substring(0, 15); // Gets the network site ID
        Map<String, Object> requestParameters = request.getRequestContextParameters();
        Boolean isGuestUser = (Boolean) requestParameters.get('isGuestUser');
        String guestUUIDKey = 'guest_uuid_essential_' + siteId; // Gets the guest UUID cookie key for the current webstore
        String deviceId  = (String) requestParameters.get(guestUUIDKey); // Gets the guest UUID cookie value for the current user and webstore
        
        String cachePartition = 'local.BuyerGroup';
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(cachePartition); // Gets the buyer group org cache partition

        // Cache key must be alphanumeric; converting currentUserId and deviceId to a hashed key
        String cacheKey = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(isGuestUser ? deviceId : currentUserId)));
        if (orgPartition.contains(cacheKey)) {
            // Cache hit — return cached buyer groups
            return new commercebuygrp.BuyerGroupResponse((Set<String>) orgPartition.get(cacheKey));  
        }

        // Getting default out-of-the-box buyer groups based on existing logic: account, market, and data cloud segment-based buyer groups
        commercebuygrp.BuyerGroupResponse defaultBuyerGroupResponse = super.getBuyerGroupIds(request);
        Set<String> buyerGroupIds = new Set<String>(defaultBuyerGroupResponse.getBuyerGroupIds());

        Set<String> activePostalCodes = new Set<String>();

        // If the user is logged in, get the BillingPostalCode and ShippingPostalCode
        if (!isGuestUser) {
            SObject currentAccount = [SELECT BillingPostalCode, ShippingPostalCode FROM Account WHERE Id = :accountId][0];
            String billingPostalCode = (String) currentAccount.get('BillingPostalCode');
            String shippingPostalCode = (String) currentAccount.get('ShippingPostalCode');
            if (billingPostalCode != null) {
                activePostalCodes.add(billingPostalCode);
            }
            if (shippingPostalCode != null) {
                activePostalCodes.add(shippingPostalCode);
            }
        }

        // Get active postal codes for both logged-in and guest users based on their device ID
        for (Active_PostalCode__c activePostalCode : [SELECT PostalCode__r.PostalCode__c FROM Active_PostalCode__c WHERE DeviceId__c = :deviceId]) {
            if (activePostalCode.PostalCode__c != null) {
                activePostalCodes.add(activePostalCode.PostalCode__r.PostalCode__c);
            }
        }

        // Get the buyer groups associated with the postal codes
        for (Postal_Code_Buyer_Group__c buyerGroup : [SELECT Buyer_Group__c FROM Postal_Code_Buyer_Group__c WHERE PostalCode__r.PostalCode__c IN :activePostalCodes]) {
            buyerGroupIds.add(buyerGroup.Buyer_Group__c);
        }
        
        // Buyer group extensibility supports only up to MAX_BUYER_GROUPS buyer groups
        if (buyerGroupIds.size() > MAX_BUYER_GROUPS) {
            commercebuygrp.BuyerGroupResponse response = new commercebuygrp.BuyerGroupResponse();
            String errorMessage = 'More than ' + MAX_BUYER_GROUPS + ' buyer groups retrieved for the user. Contact Store Administrator.';
            response.setError(errorMessage, errorMessage);
            return response;
        }

        orgPartition.put(cacheKey, buyerGroupIds);
        return new commercebuygrp.BuyerGroupResponse(buyerGroupIds);
    }
}