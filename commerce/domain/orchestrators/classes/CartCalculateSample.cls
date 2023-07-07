// This is a sample orchestrator that calls the inventory, pricing, promotions, shipping and tax calculators
// at a step level. This class must be linked to the orchestrator extension point (Commerce_Domain_Cart_Calculate)
// for orchestrators and then the extension must be linked to the webstore via the appropriate setup.

// This class must extend the CartExtension.CartCalculate class
public class CartCalculateSample extends CartExtension.CartCalculate {

    // Each orchestrator must override this calculate method.
    public virtual override void calculate(CartExtension.CartCalculateOrchestratorRequest request) {
        CartExtension.Cart cart = request.getCart();
        CartExtension.CartStatusEnum cartStatus = cart.getStatus();
        CartExtension.CartValidationOutputList cvoList  = cart.getCartValidationOutputs();

        // We might want to determine which calculator we call based on the state of the cart.
        // This block is executed when starting or modifying checkout.
        if (cartStatus == CartExtension.CartStatusEnum.CHECKOUT) {
            // Order matters. If the promotions calculator returns an error, we will finish execution early instead of
            // calling the other calculators
            promotions(new CartExtension.CartCalculateCalculatorRequest(cart));

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {
                return;
            }

            inventory(new CartExtension.CartCalculateCalculatorRequest(cart));

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {
                return;
            }

            // To successfully place an order, each Delivery Group must have an associated Delivery Method.
            for (Integer i = 0; i < cart.getCartDeliveryGroups().size(); i++) {
                CartExtension.CartDeliveryGroup cartDeliveryGroup = cart.getCartDeliveryGroups().get(i);

                if (cartDeliveryGroup.getDeliverToAddress() != null) {
                    // If you don't register the Commerce_Domain_Shipping_CartCalculator extension point -
                    // this creates a free ($0) shipping option (CartDeliveryGroupMethod).
                    // If you register custom implementation of Commerce_Domain_Shipping_CartCalculator,
                    // please make sure it always assigns at least one shipping option (CartDeliveryGroupMethod)
                    // to CartDeliveryGroup.
                    shipping(new CartExtension.CartCalculateCalculatorRequest(cart));

                    if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.SHIPPING)) {
                        return;
                    }

                    // This example takes the first available shipping option (CartDeliveryGroupMethod) and uses it as a
                    // DeliveryMethod for the given CartDeliveryGroup.
                    if (cartDeliveryGroup.getCartDeliveryGroupMethods().size() > 0) {
                        String firstCartDeliveryGroupId = cartDeliveryGroup.getCartDeliveryGroupMethods().get(0).getDeliveryMethodId();
                        cartDeliveryGroup.setDeliveryMethodId(firstCartDeliveryGroupId);
                    }

                    // Once Delivery Method is selected - calculate taxes.
                    taxes(new CartExtension.CartCalculateCalculatorRequest(cart));
                }
            }
        }

        // This block is only executed during cart level operations: add item to cart, edit cart item quantity, and
        // delete from cart.
        if (cartStatus == CartExtension.CartStatusEnum.ACTIVE) {
            // We might only want to compute pricing data during add to cart
            prices(new CartExtension.CartCalculateCalculatorRequest(cart));
        }
    }

    // This function evaluates whether there are errors in the CVO of a specific calculator type.
    private Boolean hasErrorsInCVO(CartExtension.CartValidationOutputList cvoList,
                                   CartExtension.CartValidationOutputTypeEnum calculatorType) {
        for (Integer i = (cvoList.size()-1) ; i>= 0 ; i--) {
            CartExtension.CartValidationOutput current_cvo = cvoList.get(i);

            if (current_cvo.getType() == calculatorType && current_cvo.getLevel() == CartExtension.CartValidationOutputLevelEnum.ERROR) {
                return true;
            }
        }

        return false;
    }
}