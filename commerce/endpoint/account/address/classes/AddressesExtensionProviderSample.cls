/**
* Sample extension provider for creating/retriving addresses, covering before and after entry methods
* This corresponds to the endpoint /commerce/webstores/${webstoreId}/accounts/${accountId}/addresses
* and is identified by the EPN Commerce_Endpoint_Account_Addresses for registration/mapping
*/
public with sharing class AddressesExtensionProviderSample extends ConnectApi.BaseEndpointExtension {

    public override ConnectApi.EndpointExtensionResponse afterGet(ConnectApi.EndpointExtensionResponse response, ConnectApi.EndpointExtensionRequest request) {

        System.debug('We are in the afterGet entry method of Commerce_Endpoint_Account_Addresses extension');

        // Get the response object, the list of addresses. 
        ConnectApi.CommerceAddressCollection output = (ConnectApi.CommerceAddressCollection)response.getResponseObject();

        // Iterate on the addresses and set the name to the first name plus last name if it does not exist.
        // The "after" methods have access to direct manipulation on the objects. 
        List<ConnectApi.CommerceAddressOutput> items = output.getItems();
        for (ConnectApi.CommerceAddressOutput address : items) {
            if (String.isEmpty(address.getName())) {
                address.setName(address.getFirstName() + ' ' + address.getLastName());
            }
        }

        return response;
    }

     public override ConnectApi.EndpointExtensionRequest beforePost(ConnectApi.EndpointExtensionRequest request) {
        
        System.debug('We are in the beforePost entry method of of Commerce_Endpoint_Account_Addresses extension');

        /*
         * Get the address for zip cleansing. This is a deep copy. 
         * The parameter name can be found in the documentation: https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/extensions.html
        */ 
        ConnectApi.CommerceAddressInput address = (ConnectApi.CommerceAddressInput)request.getParam('addressInput');

        // Will update the address to a valid zip format or throw an error.        
        if (UsZipCleansingSample.cleanseUsZip(address)) {
            // Since the address is a deep copy, the request needs to be updated.
            request.setParam('addressInput', address);
        }

        return request;
    }
}