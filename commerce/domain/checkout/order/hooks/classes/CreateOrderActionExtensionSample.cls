/**
* @description This is a sample implementation of Create Order Action extension for the prepare and submit actions.
*   
*/
public with sharing class CreateOrderActionExtensionSample extends ConnectApi.BaseEndpointExtension {

    public override ConnectApi.EndpointExtensionRequest beforePost(ConnectApi.EndpointExtensionRequest request) {
        
        // pre hook implementation

        return request;
    }

    public override ConnectApi.EndpointExtensionResponse afterPost(ConnectApi.EndpointExtensionResponse response,
        ConnectApi.EndpointExtensionRequest request) {

        ConnectApi.CheckoutOrderActionCollectionRepresentation resp =
        (ConnectApi.CheckoutOrderActionCollectionRepresentation) response.getResponseObject();
        List<ConnectApi.CheckoutOrderActionRepresentation> action = resp.getActions();
        String getActionName = action.get(0).getAction();

        if (getActionName == 'prepare') {

        // prepare post hook implementation

        } else if (getActionName == 'submit') {

        // submit post hook implementation

        }
        return response;
    }
}