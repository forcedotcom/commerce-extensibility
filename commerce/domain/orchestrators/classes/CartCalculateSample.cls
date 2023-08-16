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
     * @description Constructor used by unit tests only. See <<CartCalculateSampleUnitTest>>.
     * @param apexExecutor Executor which executes various calculators. Can be used to stub calculation results or delegate calculations to actual Calculator. See <<CartCalculateExecutorMock>>.
     */
    global CartCalculateSample(final CartExtension.CartCalculateExecutorMock apexExecutor) {
        // Must call super constructor in order for provided Executor to be used for calculations
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

            if (hasErrorLevelCartValidationOutput(cvoList, CartExtension.CartValidationOutputTypeEnum.PRICING)) {
                return;
            }
        }

        if (runPromotions) {
            promotions(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cvoList, CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {
                return;
            }
        }

        if (runInventory) {
            inventory(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cvoList, CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {
                return;
            }
        }

        if (runShipping) {
            shipping(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cvoList, CartExtension.CartValidationOutputTypeEnum.SHIPPING)) {
                return;
            }
        }

        if (runPostShipping) {
            postShipping(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cvoList, CartExtension.CartValidationOutputTypeEnum.SYSTEM_ERROR)) {
                return;
            }
        }

        if (runTaxes) {
            taxes(calculatorRequest);
        }
    }

    // This function evaluates whether there are errors in the CVO of a specific calculator type.
    private Boolean hasErrorLevelCartValidationOutput(CartExtension.CartValidationOutputList cartValidationOutputs,
                                                      CartExtension.CartValidationOutputTypeEnum cartValidationOutputType) {
        Iterator<CartExtension.CartValidationOutput> iterator = cartValidationOutputs.iterator();

        while (iterator.hasNext()) {
            CartExtension.CartValidationOutput cvo = iterator.next();

            Boolean cvoContainsCalculatorError = cvo.getType() == cartValidationOutputType
                    && cvo.getLevel() == CartExtension.CartValidationOutputLevelEnum.ERROR;

            if (cvoContainsCalculatorError) {
                return true;
            }
        }

        return false;
    }
}
