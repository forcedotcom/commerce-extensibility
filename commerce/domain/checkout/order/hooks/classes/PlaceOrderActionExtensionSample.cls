/**
 * @description This is a sample implementation of Place Order Action Extension for prepare and submit actions.
 */
public virtual with sharing class PlaceOrderActionExtensionSample extends ConnectApi.BaseEndpointExtension {

    // Restricted city constant
    private static final String RESTRICTED_CITY = 'New York';

    public override ConnectApi.EndpointExtensionRequest beforePost(ConnectApi.EndpointExtensionRequest request) {
        if (request == null) {
            return null;
        }

        // Validation check: Ensure we do not ship to restricted cities
        // If the delivery DeliverToCity is a restricted city, block the order
        CartDeliveryGroup[] city = [SELECT DeliverToCity FROM CartDeliveryGroup LIMIT 1];
        if (city.size() < 1) {
            throw new IllegalArgumentException('No delivery group found.');
        }

        // Check specific city - cannot ship to a restricted city
        if (city.get(0).toString() == RESTRICTED_CITY) {
            throw new IllegalArgumentException('We cannot ship to ' + RESTRICTED_CITY + '.');
        }
        return request;
    }

    public override ConnectApi.EndpointExtensionResponse afterPost(ConnectApi.EndpointExtensionResponse response,
        ConnectApi.EndpointExtensionRequest request) {
        if (response == null) {
            return null;
        }

        // Example post-hook logic
        ConnectApi.CheckoutOrderActionCollectionRepresentation resp =
            (ConnectApi.CheckoutOrderActionCollectionRepresentation) response.getResponseObject();
        List<ConnectApi.CheckoutOrderActionRepresentation> actions = resp.getActions();

        if (actions != null && actions.size() < 1) {
            throw new IllegalArgumentException('No actions found.');
        }

        String actionName = actions.get(0).getAction();

        if (actionName == 'prepare') {
            // Validation check to ensure PaymentGateway status is not 'Restricted'.
            PaymentGateway[] status = [SELECT Status FROM PaymentGateway LIMIT 1];
            if (status.get(0).toString() == 'Restricted') {
                throw new IllegalArgumentException('Payment Gateway status is Restricted.');
            }
        } else if (actionName == 'submit') {
            // Validation check to ensure the order reference number is not null.
            String orderRef = actions.get(0).getOrderReferenceNumber();
            if (orderRef == null) {
                throw new IllegalArgumentException('Order Reference Number is null.');
            }
        }

        return response;
    }
}