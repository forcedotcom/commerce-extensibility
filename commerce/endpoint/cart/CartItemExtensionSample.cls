/**
 * Sample extension for handling the edit operation on a cart item.
 * This corresponds to an endpoint /commerce/webstores/${webstoreId}/carts/${activeCartOrId}/cart-items/${cartItemId}
 * and is identified by the EPN Commerce_Endpoint_Cart_Item for registration/mapping.
 */
public with sharing class CartItemExtensionSample extends ConnectApi.BaseEndpointExtension {

    /**
     * Overrides the afterPatch method to update the currency ISO code of a cart item.
     *
     * @param response The endpoint extension response containing cart item data.
     * @param request The endpoint extension request.
     * @return The modified endpoint extension response with updated currency ISO code.
     */
    public override ConnectApi.EndpointExtensionResponse afterPatch(ConnectApi.EndpointExtensionResponse response, ConnectApi.EndpointExtensionRequest request) {
        System.debug('Entering the afterPatch method of Commerce_Endpoint_Cart_Item extension');

        /**
         * Retrieve the cart item from the response object
         * More details on the response object can be found in the documentation:
         * https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/extensions.html#connectapiendpointextensionresponse
         * */
        ConnectApi.CartItem cartItem = (ConnectApi.CartItem)response.getResponseObject();

        // Check if cartItem is not null
        if (cartItem != null) {
            // Set the currency ISO code to AED
            cartItem.setCurrencyIsoCode('AED');
        }

        // Return the modified response
        return response;
    }
}