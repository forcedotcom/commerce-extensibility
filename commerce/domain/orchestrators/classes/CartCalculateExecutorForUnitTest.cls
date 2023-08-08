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

        if (cart.getStatus() == CartExtension.CartStatusEnum.CHECKOUT) {
            cart.setName(cart.getName() + ', CartRepricedWithExternalCallout');
        } else {
            cart.setName(cart.getName() + ', CartRepricedWithEstimate');
        }
    }

    global override void promotions(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        cart.setName(cart.getName() + ', PromotionsRecalculated');
    }

    global override void inventory(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        cart.setName(cart.getName() + ', InventoryChecked');
    }

    global override void shipping(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        cart.setName(cart.getName() + ', ShippingRecalculated');
    }

    global override void tax(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        cart.setName(cart.getName() + ', TaxesRecalculated');
    }

    global override void postShipping(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        cart.setName(cart.getName() + ', PostShippingCompleted');
    }
}