// This corresponds to /commerce/webstores/${webstoreId}/accounts/${accountId}/addresses/${addressId} and Commerce_Endpoint_Account_Address
public with sharing class AddressExtensionProviderSample extends ConnectApi.BaseEndpointExtension {

    public override ConnectApi.EndpointExtensionRequest beforePatch(ConnectApi.EndpointExtensionRequest request) {
        System.debug('We are in the beforePatch entry method of of Commerce_Endpoint_Account_Address extension');

        // Get the address for zip cleansing. This is a deep copy.
        ConnectApi.CommerceAddressInput address = (ConnectApi.CommerceAddressInput)request.getParam('addressInput');

        // Will update the address to a valid zip format or throw an error.
        if (UsZipCleansingSample.cleanseUsZip(address)) {
            // The request needs to be set on the "before" methods since what is returned is a deep copy.
            request.setParam('addressInput', address);
        }

        return request;
    }

}