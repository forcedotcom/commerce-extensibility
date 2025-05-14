/**
 * BuyerGroupEvaluationServiceSample is a sample implementation of the BuyerGroupEvaluationService used to determine buyer group IDs for a user (guest or logged-in)
 * Usecase for the sample implementation is as follows :
 * - Out of the box Buyer groups based on account, market and data cloud segment should be returned for both logged in and guest users.
 * - In addition if the user is a guest/logged in user then the buyer groups associated to active postal code stored based on deviceId should be returned.
 * - For logged in user, the Buyer Groups associated to the BillingPostalCode and ShippingPostalCode of the Account associated to logged in user are also returned.
 * 
 * Data Model changes to support the below sample code is as follows:
 * - PostalCode__c : Stores the supported Postal Codes in the PostalCode field
 * - Active_PostalCode__c : Stores the association between deviceId(Guest UUID Cookie value) and PostalCode__c. 
 *                          This can typically be populated via a custom lwc component where customer chooses a postal code from list of available Postal codes.
 * - Postal_code_Buyer_Group__c : Junction entity that stores a static mapping between PostalCode__c and Buyer Groups associated to it.
 * 
 * Important Considerations in the below code:
 * - Buyer Group Responses should be cached using Org Cache to support low latency. 
 * - More than MAX_BUYER_GROUPS should not be retuned by the code. 
 */
public without sharing class BuyerGroupEvaluationServiceSample extends commercebuygrp.BuyerGroupEvaluationService {

    private static Integer MAX_BUYER_GROUPS = 30;

    public override commercebuygrp.BuyerGroupResponse getBuyerGroupIds(commercebuygrp.BuyerGroupRequest request) {
        String currentUserId = UserInfo.getUserId(); //Gets the current userId, could be logged in or guest userId
        String webstoreId = request.getStoreId();  //Gets the webstore recordId
        String accountId = request.getAccountId(); //Gets the accountId of the user
        String siteId = ((String) [select SiteId from WebstoreNetwork where WebstoreId = :webstoreId][0].get('SiteId')).substring(0, 15); //Gets the network SiteId
        Map<String, Object> requestParameters = request.getRequestContextParameters();
        Boolean isGuestUser = (Boolean) requestParameters.get('isGuestUser');
        String guestUUIDKey = 'guest_uuid_essential_'+siteId; //Gets the guest uuid cookie key for the current webstore
        String deviceId  = (String) requestParameters.get(guestUUIDKey);   //Gets the guest uuid cookie value for the current user for the webstore
        
        String cachePartition = 'local.BuyerGroup';
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(cachePartition); //Gets the buyer group org cache partition

        //Cache key needs to be alphanumeric, converting currentUserId and deviceId to hashed cache key
        String cacheKey = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(isGuestUser ? deviceId : currentUserId)));
        if(orgPartition.contains(cacheKey)) {
            //Cache Hit, return cached buyer groups
            return new commercebuygrp.BuyerGroupResponse((Set<String>)orgPartition.get(cacheKey));  
        }

        //Getting default out of the box buyer groups based on existing logic of account, markets and data cloud segment based buyer groups.
        commercebuygrp.BuyerGroupResponse defaultBuyerGroupResponse = super.getBuyerGroupIds(request);
        Set<String> buyerGroupIds = new Set<String>(defaultBuyerGroupResponse.getBuyerGroupIds());

        Set<String> activePostalCodes = new Set<String>();

        //If the user is logged in user, then get the BillingPostalCode and ShippingPostalCode
        if(!isGuestUser) {
            SObject currentAccount = [SELECT BillingPostalCode, ShippingPostalCode FROM Account WHERE Id=:accountId][0];
            String billingPostalCode = (String)currentAccount.get('BillingPostalCode');
            String shippingPostalCode = (String)currentAccount.get('ShippingPostalCode');
            if(billingPostalCode != null ) {
                activePostalCodes.add(billingPostalCode);
            }
            if(shippingPostalCode != null ) {
                activePostalCodes.add(shippingPostalCode);
            }
        }

        //Get Active Postal Code for both logged in and guest user based on their Device Id
        for(Active_PostalCode__c activePostalCode : [SELECT PostalCode__r.PostalCode__c FROM Active_PostalCode__c WHERE DeviceId__c=:deviceId]) {
            if(activePostalCode.PostalCode__c != null) {
                activePostalCodes.add(activePostalCode.PostalCode__r.PostalCode__c);
            }
        }

        //Get the Buyer Groups associated to the Postal Codes
        for(Postal_Code_Buyer_Group__c buyerGroup : [SELECT Buyer_Group__c FROM Postal_Code_Buyer_Group__c WHERE PostalCode__r.PostalCode__c in :activePostalCodes]) {
            buyerGroupIds.add(buyerGroup.Buyer_Group__c);
        }
        
        //Buyer Group Extensibility only supports upto MAX_BUYER_GROUPS buyer groups
        if(buyerGroupIds.size() > MAX_BUYER_GROUPS) {
            commercebuygrp.BuyerGroupResponse response = new commercebuygrp.BuyerGroupResponse();
            String errorMessage = 'More than '+ MAX_BUYER_GROUPS +' buyer groups retrieved for the user. Contact Store Administrator.';
            response.setError(errorMessage, errorMessage);
            return response;
        }

        orgPartition.put(cacheKey, buyerGroupIds);
        return new commercebuygrp.BuyerGroupResponse(buyerGroupIds);
      }
}