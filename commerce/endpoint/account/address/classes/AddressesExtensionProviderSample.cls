// This corresponds to /commerce/webstores/${webstoreId}/accounts/${accountId}/addresses and Commerce_Endpoint_Account_Addresses
public with sharing class AddressesExtensionProviderSample extends ConnectApi.BaseEndpointExtension {

    public override ConnectApi.EndpointExtensionResponse afterGet(ConnectApi.EndpointExtensionResponse response, 
            ConnectApi.EndpointExtensionRequest request) {

        System.debug('We are in the afterGet entry method of Commerce_Endpoint_Account_Addresses extension');

        // Get the response object, the list of addresses. 
        ConnectApi.CommerceAddressCollection output = (ConnectApi.CommerceAddressCollection)response.getResponseObject();

        // Iterate through the addresses, set the name name for each address to a concatenation of the first and last name, if it hasn't been populated. Note: The change to the name field is not persisted, this means if the name field was not set but a value is returned through an endpoint using this extension, a SOQL lookup will NOT return a value for the name field.
        // The "after" methods have access to direct manipulation on the objects. 
        List<ConnectApi.CommerceAddressOutput> addresses = output.getItems();
        for (ConnectApi.CommerceAddressOutput address : addresses) {
            if (String.isEmpty(address.getName())) {
                address.setName(address.getFirstName() + ' ' + address.getLastName());
            }
        }

        return response;
    }

     public override ConnectApi.EndpointExtensionRequest beforePost(ConnectApi.EndpointExtensionRequest request) {
        
        System.debug('We are in the beforePost entry method of of Commerce_Endpoint_Account_Addresses extension');
        
        // Get the address for zip cleansing. This is a deep copy.
        ConnectApi.CommerceAddressInput address = (ConnectApi.CommerceAddressInput)request.getParam('addressInput');

        // Will update the address to a valid zip format or throw an error.        
        if (UsZipCleansingSample.cleanseUsZip(address)) {
            // Since the address is a deep copy, the request needs to be updated.
            request.setParam('addressInput', address);
        }

        return request;
    }
}