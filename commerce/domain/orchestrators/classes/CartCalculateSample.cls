// This is a sample orchestrator that calls the inventory, pricing, promotions, shipping and tax calculators
// at a step level. This class must be linked to the orchestrator extension point (Commerce_Domain_Cart_Calculate)
// for orchestrators and then the extension must be linked to the webstore via the appropriate setup.

// This class must extend the CartExtension.CartCalculate class
global class CartCalculateSample extends CartExtension.CartCalculate {

    /**
     * @description All classes extending CartExtension.CartCalculate must have a default constructor defined
     */
    global CartCalculateSample() {}

    /**
     * @description This constructor should only be used in a test context
     * @param apexExecutor Executor which can run the various calculators
     */
    global CartCalculateSample(final CartCalculateExecutorForUnitTest apexExecutor) {
        super(apexExecutor);
    }

    // Each orchestrator must override this calculate method.
    global virtual override void calculate(CartExtension.CartCalculateOrchestratorRequest request) {
        CartExtension.Cart cart = request.getCart();

        // Use BuyerActions to decide which calculators to invoke
        CartExtension.BuyerActions buyerActions = request.getBuyerActions();
        boolean runPricing = buyerActions.isCheckoutStarted() || buyerActions.isCartItemChanged();
        boolean runPromotions = buyerActions.isCheckoutStarted() || buyerActions.isCouponChanged() || buyerActions.isCartItemChanged();
        boolean runInventory = buyerActions.isCheckoutStarted();
        boolean runShipping = buyerActions.isDeliveryGroupChanged();
        boolean runPostShipping = buyerActions.isDeliveryGroupChanged() || buyerActions.isDeliveryMethodSelected();
        boolean runTaxes = buyerActions.isDeliveryGroupChanged() || buyerActions.isDeliveryMethodSelected();

        // OptionalBuyerActionDetails can be used to optimize the various calculators that are invoked
        CartExtension.CartCalculateCalculatorRequest calculatorRequest = new CartExtension.CartCalculateCalculatorRequest(cart, request.getOptionalBuyerActionDetails());
        CartExtension.CartValidationOutputList cvoList  = cart.getCartValidationOutputs();

        if (runPricing) {
            prices(calculatorRequest);

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.PRICING)) {
                return;
            }
        }

        if (runPromotions) {
            promotions(calculatorRequest);

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {
                return;
            }
        }

        if (runInventory) {
            inventory(calculatorRequest);

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {
                return;
            }
        }

        if (runShipping) {
            shipping(calculatorRequest);

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.SHIPPING)) {
                return;
            }
        }

        if (runPostShipping) {
            postShipping(calculatorRequest);

            if (hasErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.SYSTEM_ERROR)) {
                return;
            }
        }

        if (runTaxes) {
            taxes(calculatorRequest);
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
