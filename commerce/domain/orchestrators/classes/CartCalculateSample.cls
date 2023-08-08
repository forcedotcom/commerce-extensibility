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
        // Call super to set up `CartCalculateExecutorMock` within CartExtension.CartCalculate. This will allow you to
        // test how each calculator is invoked in unit tests
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
        CartExtension.CartValidationOutputList cvoList = cart.getCartValidationOutputs();

        if (runPricing) {
            prices(calculatorRequest);

            if (hasSpecifiedCalculatorTypeErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.PRICING)) {
                return;
            }
        }

        if (runPromotions) {
            promotions(calculatorRequest);

            if (hasSpecifiedCalculatorTypeErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {
                return;
            }
        }

        if (runInventory) {
            inventory(calculatorRequest);

            if (hasSpecifiedCalculatorTypeErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {
                return;
            }
        }

        if (runShipping) {
            shipping(calculatorRequest);

            if (hasSpecifiedCalculatorTypeErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.SHIPPING)) {
                return;
            }
        }

        if (runPostShipping) {
            postShipping(calculatorRequest);

            if (hasSpecifiedCalculatorTypeErrorsInCVO(cvoList, CartExtension.CartValidationOutputTypeEnum.SYSTEM_ERROR)) {
                return;
            }
        }

        if (runTaxes) {
            taxes(calculatorRequest);
        }
    }

    // This function evaluates whether there are CVO errors of a specific calculator type.
    private Boolean hasSpecifiedCalculatorTypeErrorsInCVO(CartExtension.CartValidationOutputList cartValidationOutputs,
                                                          CartExtension.CartValidationOutputTypeEnum calculatorType) {
        Iterator<CartExtension.CartValidationOutput> iterator = cartValidationOutputs.iterator();

        while (iterator.hasNext()) {
            CartExtension.CartValidationOutput cvo = iterator.next();

            if (cvo.getType() == calculatorType && cvo.getLevel() == CartExtension.CartValidationOutputLevelEnum.ERROR) {
                return true;
            }
        }

        return false;
    }
}