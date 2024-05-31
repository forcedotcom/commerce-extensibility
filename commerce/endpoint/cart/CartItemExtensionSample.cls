/**
 * Sample extension for updating the listPrice of a cart item based on the currencyIsoCode during edit operations.
 * This corresponds to an endpoint /commerce/webstores/${webstoreId}/carts/${activeCartOrId}/cart-items/${cartItemId}
 * and is identified by the EPN Commerce_Endpoint_Cart_Item for registration/mapping.
 */
public with sharing class CartItemExtensionSample extends ConnectApi.BaseEndpointExtension {

    // Define a constant for the USD currencyIsoCode
    private static final String USD_CURRENCY_ISO_CODE = 'USD';

    // Define a constant for the AED currencyIsoCode
    private static final String AED_CURRENCY_ISO_CODE = 'AED';

    // Define a constant for the adjustment when the currencyIsoCode is USD
    private static final Decimal USD_ADJUSTMENT = 10;

    // Define a constant for the adjustment when the currencyIsoCode is AED
    private static final Decimal AED_ADJUSTMENT = 5;

    // Define a constant for the adjustment for currencyIsoCodes other than USD and AED
    private static final Decimal ADJUSTMENT = 2;


    /**
     * Overrides the afterPatch method to update the listPrice of a cart item based on the currencyIsoCode.
     *
     * @param response The endpoint extension response containing cart item data.
     * @param request The endpoint extension request.
     * @return The modified endpoint extension response with updated listPrice.
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
            // Check if listPrice and currencyIsoCode are not null
            if (cartItem.getListPrice() != null && cartItem.getCurrencyIsoCode() != null) {
                
                // Retrieve the currencyIsoCode from the cart item
                String currencyCode = cartItem.getCurrencyIsoCode();

                // Retrieve the listPrice from the cart item  
                String listPriceStr = cartItem.getListPrice();

                try {
                    // Convert listPrice from String to Decimal
                    Decimal listPrice = Decimal.valueOf(listPriceStr);

                    // Adjust the listPrice based on the currencyIsoCode
                    switch on currencyCode {
                        when USD_CURRENCY_ISO_CODE {
                            listPrice += USD_ADJUSTMENT;
                        }
                        when AED_CURRENCY_ISO_CODE {
                            listPrice += AED_ADJUSTMENT;
                        }
                        when else {
                            listPrice += ADJUSTMENT;
                        }
                    }

                    // Set the adjusted listPrice back to the cart item
                    cartItem.setListPrice(String.valueOf(listPrice));
                } catch (Exception e) {
                    throw new InvalidFormatException('Invalid listPrice format: ' + listPriceStr);
                }
            }
        }

        // Return the modified response
        return response;
    }
}