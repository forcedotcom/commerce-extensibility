/*
 * This is a sample orchestrator that calls the inventory, pricing, promotions, shipping and tax calculators
 * at a step level. This class must be linked to the orchestrator extension point (Commerce_Domain_Cart_Summary)
 * for orchestrators and then the extension must be linked to the webstore via the appropriate setup.
 */

public class CartSummarySample extends CartExtension.CartSummary {

    /*
     * Each orchestrator must override this calculate method.
    */
    public virtual override void calculate(CartExtension.CartSummaryCalculationRequest request) {

        CartExtension.Cart cart = request.getCart();
        CartExtension.CartStatusEnum cartStatus = cart.getStatus();
        CartExtension.CartValidationOutputCollection cvoCollection  = cart.getCartValidationOutputs();

       /*
        * We might want to determine which calculator we call based on the state of the cart.
        * This block is executed when starting or modifying checkout.
        */
        if(cartStatus == CartExtension.CartStatusEnum.CHECKOUT) {
           /*
            * Order matters. If the promotions calculator returns an error, we will finish execution early instead of calling the other calculators
           */
            promotions(new CartExtension.CartCalculationRequest(cart));
            if(hasErrorsInCVO(cvoCollection, CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {return;}
            inventory(new CartExtension.CartCalculationRequest(cart));
            if(hasErrorsInCVO(cvoCollection, CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {return;}
            /*
            * In order to be able to successfully place an order, each Delivery Group must have associated Delivery Method.
            */
            for (Integer i = 0; i < cart.getCartDeliveryGroups().size(); i++) {
                    CartExtension.CartDeliveryGroup cartDeliveryGroup = cart.getCartDeliveryGroups().get(i);
                    if (cartDeliveryGroup.getDeliverToAddress() != null) {
                        /*
                         * If you don't register the Commerce_Domain_Shipping_CartCalculator extension point -
                         * this creates a free ($0) shipping option (CartDeliveryGroupMethod).
                         * If you register custom implementation of Commerce_Domain_Shipping_CartCalculator,
                         * please make sure it always assigns at least one shipping option (CartDeliveryGroupMethod) to CartDeliveryGroup.
                         */
                        shipping(new CartExtension.CartCalculationRequest(cart));
                        if(hasErrorsInCVO(cvoCollection, CartExtension.CartValidationOutputTypeEnum.SHIPPING)) {return;}
                        /*
                         * This example takes the first available shipping option (CartDeliveryGroupMethod)
                         * and uses it as DeliveryMethod for given CartDeliveryGroup.
                         */
                        if (cartDeliveryGroup.getCartDeliveryGroupMethods().size() > 0) {
                            String firstCartDeliveryGroupId = cartDeliveryGroup.getCartDeliveryGroupMethods().get(0).getDeliveryMethodId();
                            cartDeliveryGroup.setDeliveryMethodId(firstCartDeliveryGroupId);
                        }
                        /*
                         * Once Delivery Method is selected - calculate taxes.
                         */
                        taxes(new CartExtension.CartCalculationRequest(cart));
                    }
                }

        }

        /*
         * This block is only executed during cart level operations: add To Cart,
         * edit cart item quantity, and delete from cart.
         */
        if(cartStatus == CartExtension.CartStatusEnum.ACTIVE) {
            /* We might only want to compute pricing data during add to cart*/
            prices(new CartExtension.CartCalculationRequest(cart));
        }

    }

    /*
     * This function evaluates whether there are errors in the CVO of a specific calculator type.
     */
    public Boolean hasErrorsInCVO(CartExtension.CartValidationOutputCollection cvoCollection, CartExtension.CartValidationOutputTypeEnum calculatorType) {
        for (Integer i = (cvoCollection.size()-1) ; i>= 0 ; i--) {
            CartExtension.CartValidationOutput current_cvo =  cvoCollection.get(i);
            if(current_cvo.getType() == calculatorType && current_cvo.getLevel() == CartExtension.CartValidationOutputLevelEnum.ERROR) {
                return true;
            }
        }
        return false;
    }

}