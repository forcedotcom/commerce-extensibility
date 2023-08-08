/**
 * @description Sample mock executor for unit testing a custom orchestrator within Cart Calculate API.
 */
global class CartCalculateExecutorForUnitTest extends CartExtension.CartCalculateExecutorMock {

    /**
     * @description All classes extending CartExtension.CartCalculateExecutorMock must have a default constructor defined
     */
    global CartCalculateExecutorForUnitTest() {}

    global override void prices(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();

        String nameToAppend = shouldCallExternalPricingService(cart)
            ? ', CartRepricedWithExternalCallout'
            : ', CartRepricedWithEstimate';

        appendToCartName(cart, nameToAppend);
    }

    global override void promotions(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        appendToCartName(cart, ', PromotionsRecalculated');
    }

    global override void inventory(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        appendToCartName(cart, ', InventoryChecked');
    }

    global override void shipping(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        appendToCartName(cart, ', ShippingRecalculated');
    }

    global override void tax(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        appendToCartName(cart, ', TaxesRecalculated');
    }

    global override void postShipping(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        appendToCartName(cart, ', PostShippingCompleted');
    }

    /**
     * @description Checks whether or not to call the external Pricing Service
     * @param CartExtension.Cart The Cart object
     */
    private Boolean shouldCallExternalPricingService(CartExtension.Cart cart) {
        // We only need to call the external Pricing Service if the Cart is in Checkout
        return cart.getStatus() == CartExtension.CartStatusEnum.CHECKOUT;
    }

    /**
     * @description Appends to the Cart name
     * @param CartExtension.Cart The cart object
     * @param String The name to append to the cart
     */
    private void appendToCartName(CartExtension.Cart cart, String nameToAppend) {
        cart.setName(cart.getName() + nameToAppend);
    }
}