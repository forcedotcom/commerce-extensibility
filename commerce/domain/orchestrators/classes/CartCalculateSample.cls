/**
* @description This is a sample orchestrator that calls the inventory, pricing, promotions, shipping and tax calculators.
* This class must extend CartExtension.CartCalculate and must be linked to the orchestrator extension point (Commerce_Domain_Cart_Calculate).
* Calculates pricing and promotions for operations: Add product to cart, remove product from cart, edit cart item quantity.
* Calculates promotions for operations: add coupon to cart, remove coupon from cart.
* Calculates pricing, promotions, inventory for start checkout operation (without shipping address available).
* Calculates pricing, promotions, inventory, shipping, post shipping and taxes for start checkout operation (with shipping address available).
* Calculates shipping, post shipping and taxes for update shipping address operation.
* Calculates taxes for select delivery method operation.
*/
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
        boolean isCouponAppliedInCheckout = isCouponAppliedInCheckout(buyerActions, cart);

        boolean runPricing = buyerActions.isRecalculationRequested() ||
                            buyerActions.isCheckoutStarted() ||
                            buyerActions.isCartItemChanged();

        boolean runPromotions = buyerActions.isRecalculationRequested() ||
                                buyerActions.isCheckoutStarted() ||
                                buyerActions.isCouponChanged() ||
                                buyerActions.isCartItemChanged() ||
                                isCouponAppliedInCheckout;

        boolean runInventory = isRecalculationRequestedInCheckout(buyerActions, cart) ||
                                buyerActions.isCheckoutStarted() ||
                                (buyerActions.isCartItemChanged() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus());

        boolean runShipping =  buyerActions.isEvaluateShippingRequested() ||
                                (isRecalculationRequestedInCheckout(buyerActions, cart) && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                                isCouponAppliedInCheckout ||
                                (buyerActions.isDeliveryGroupChanged() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus());

        boolean runPostShipping = buyerActions.isEvaluateShippingRequested() ||
                                    (isRecalculationRequestedInCheckout(buyerActions, cart) && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                                    (buyerActions.isDeliveryGroupChanged() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                                    (buyerActions.isDeliveryMethodSelected() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                                    isCouponAppliedInCheckout;

        boolean runTaxes = buyerActions.isEvaluateTaxesRequested() ||
                            (isRecalculationRequestedInCheckout(buyerActions, cart) && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                            (buyerActions.isDeliveryGroupChanged() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                            (buyerActions.isDeliveryMethodSelected() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus()) ||
                            isCouponAppliedInCheckout;


        // OptionalBuyerActionDetails can be used to optimize the various calculators that are invoked
        CartExtension.CartCalculateCalculatorRequest calculatorRequest = new CartExtension.CartCalculateCalculatorRequest(cart, request.getOptionalBuyerActionDetails());

        if (runPricing) {
            prices(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cart.getCartValidationOutputs(), CartExtension.CartValidationOutputTypeEnum.PRICING)) {
                return;
            }
        }

        if (runPromotions) {
            promotions(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cart.getCartValidationOutputs(), CartExtension.CartValidationOutputTypeEnum.PROMOTIONS)) {
                return;
            }
        }

        if (runInventory) {
            inventory(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cart.getCartValidationOutputs(), CartExtension.CartValidationOutputTypeEnum.INVENTORY)) {
                return;
            }
        }

        if (runShipping) {
            shipping(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cart.getCartValidationOutputs(), CartExtension.CartValidationOutputTypeEnum.SHIPPING)) {
                return;
            }
        }

        if (runPostShipping) {
            postShipping(calculatorRequest);

            if (hasErrorLevelCartValidationOutput(cart.getCartValidationOutputs(), CartExtension.CartValidationOutputTypeEnum.SYSTEM_ERROR)) {
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

    private Boolean isCouponAppliedInCheckout(CartExtension.BuyerActions buyerActions, CartExtension.Cart cart) {
        return cart.getStatus() == CartExtension.CartStatusEnum.CHECKOUT && buyerActions.isCouponChanged();
    }

    private Boolean isRecalculationRequestedInCheckout(CartExtension.BuyerActions buyerActions, CartExtension.Cart cart) {
        return buyerActions.isRecalculationRequested() && CartExtension.CartStatusEnum.CHECKOUT == cart.getStatus();
    }
}