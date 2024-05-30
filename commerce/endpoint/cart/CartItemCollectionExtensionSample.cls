/**
 * Sample extension for updating the quantity of a cart item while adding an item to the cart.
 * This corresponds to the endpoint /commerce/webstores/${webstoreId}/carts/${activeCartOrId}/cart-items
 * and is identified by the EPN Commerce_Endpoint_Cart_ItemCollection for registration/mapping.
 */
public with sharing class CartItemCollectionExtensionSample extends ConnectApi.BaseEndpointExtension {

    /**
     * Overrides the beforePost method to update the quantity of a cart item.
     *
     * @param request The endpoint extension request containing cart item data.
     * @return The modified endpoint extension request with updated quantity.
     */
    public override ConnectApi.EndpointExtensionRequest beforePost(ConnectApi.EndpointExtensionRequest request) {
        System.debug('We are in the beforePost entry method of Commerce_Endpoint_Cart_ItemCollection extension');

        /**
         * Retrieve the cart item input from the request. This is a deep copy.
         * The parameter name can be found in the documentation:
         * https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/extensions.html
         */
        ConnectApi.CartItemInput cartItemInput = (ConnectApi.CartItemInput) request.getParam('cartItemInput');

        // Check if cartItemInput is not null
        if (cartItemInput != null) {
            // Retrieve the quantity from the cart item input
            String quantity = cartItemInput.getQuantity();

            // Check if quantity is not null
            if (quantity != null) {
                // Set the quantity to 5
                cartItemInput.setQuantity('5');
            }

            /**
             * Update the cart item input parameter in the request.
             * The request needs to be set in the "before" methods since what is returned is a deep copy.
             */
            request.setParam('cartItemInput', cartItemInput);
        }

        // Return the modified request
        return request;
    }
}