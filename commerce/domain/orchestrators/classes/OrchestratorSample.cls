// This is a sample orchestrator that calls the  inventory, pricing and promotions and tax calculators
// at a step level. This class must be linked to the orchestrator extension point and then the
// integration must be linked to the webstore via appropriate setup

public class OrchestratorSample extends CartExtension.CartSummary {

    //Each orchestrator must override this calculate method
    public virtual override void calculate(CartExtension.CartSummaryCalculationRequest request) {

        CartExtension.Cart cart = request.getCart();

        //We might want to determine the calculator we call based on the state of the cart.
        if(cartStatus == CartExtension.CartStatusEnum.ACTIVE) {
            //Order matters, so the inventory calculator will finish executing before the pricing calculator starts
            //If the inventory calculator writes to the CVO, however, we will finish execution early instead of calling the other calculators
            inventory(new CartExtension.CartCalculationRequest(cart));
            if(hasErrorsInCVO(cvoCollection, CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {return};
            prices(new CartExtension.CartCalculationRequest(cart));
            if(hasErrorsInCVO(cvoCollection, CartExtension.CartValidationOutputTypeEnum.PRICING)) {return};
            promotions(new CartExtension.CartCalculationRequest(cart));
            if(hasErrorsInCVO(cvoCollection, CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {return};
        }

        if(cartStatus == CartExtension.CartStatusEnum.CHECKOUT) {
            taxes(new CartExtension.CartCalculationRequest(cart));
        }

    }

    public void hasErrorsInCVO(CartExtension.CartValidationOutputCollection cvoCollection, CartExtension.CartValidationOutputTypeEnum calculatorType) {
        for (Integer i = (cvoCollection.size()-1) ; i>= 0 ; i--) {
            CartExtension.CartValidationOutput current_cvo =  cvoCollection.get(i);
            if(current_cvo.getType() == calculatorType) {
                return true;
            }
        }
        return false;
    }

}