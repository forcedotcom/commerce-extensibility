/**
* Sample extension provider for updating addresses
* This corresponds to the endpoint /commerce/webstores/${webstoreId}/accounts/${accountId}/addresses
* and is identified by the EPN Commerce_Endpoint_Account_Addresses for registration/mapping
*/
public with sharing class AddressExtensionProviderSample extends ConnectApi.BaseEndpointExtension {

    /*
     * Cleanses the US zip on address update
     */
    public override ConnectApi.EndpointExtensionRequest beforePatch(ConnectApi.EndpointExtensionRequest request) {
        System.debug('We are in the beforePatch entry method of of Commerce_Endpoint_Account_Address extension');

        /*
         * Get the address for zip cleansing. This is a deep copy. 
         * The parameter name can be found in the documentation: https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/extensions.html
        */ 
        ConnectApi.CommerceAddressInput address = (ConnectApi.CommerceAddressInput)request.getParam('addressInput');

        // Will update the address to a valid zip format or throw an error.
        if (UsZipCleansingSample.cleanseUsZip(address)) {
            // The request needs to be set on the "before" methods since what is returned is a deep copy.
            request.setParam('addressInput', address);
        }

        return request;
    }

}