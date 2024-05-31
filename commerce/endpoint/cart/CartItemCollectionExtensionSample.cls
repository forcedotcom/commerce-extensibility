/**
 * Sample extension for enforcing quantity constraints on a cart item while adding an item to the cart.
 * This corresponds to the endpoint /commerce/webstores/${webstoreId}/carts/${activeCartOrId}/cart-items
 * and is identified by the EPN Commerce_Endpoint_Cart_ItemCollection for registration/mapping.
 */
public with sharing class CartItemCollectionExtensionSample extends ConnectApi.BaseEndpointExtension {

    // Define a constant for the maximum quantity allowed
    private static final Integer MAX_QUANTITY = 100;

    /**
     * Overrides the beforePost method to enforce a maximum quantity of a cart item.
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
            String quantityStr = cartItemInput.getQuantity();

            // Check if quantity is not null
            if (quantityStr != null) {
                try {
                    // Convert quantity from String to Integer
                    Integer quantity = Integer.valueOf(quantityStr);

                    // Enforce the maximum quantity
                    if (quantity > MAX_QUANTITY) {
                        quantity = MAX_QUANTITY;
                        // Set the enforced quantity back to the cart item input
                        cartItemInput.setQuantity(quantity.toString());
                    }
                } catch (Exception e) {
                    throw new InvalidFormatException('Invalid quantity format: ' + quantityStr);
                }
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