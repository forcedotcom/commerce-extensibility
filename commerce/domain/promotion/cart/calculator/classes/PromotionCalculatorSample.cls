/**
  * @description This sample is for the situations where Promotion Calculation needs to be extended or overridden via the
  * extension point for the Promotion Calculator. You are expected to refer this and write your own implementation.
  * This class must extend the CartExtension.PromotionsCartCalculator class to be processed.
  *
  * In this example cart items are evaluated against a BOGO (Buy X, Get Y) promotion > Buy 5 items of qualifying product X,
  * get $2 off a unit of target Y.
  */
public with sharing class PromotionCalculatorSample extends CartExtension.PromotionsCartCalculator {

    // You MUST change following to be a valid promotion, product ids.
    public static final String DUMMY_PROMOTION_ID = '0c8xx00000004JlAAI';
    private static final String QUALIFIER_PRODUCT_ID = '01txx0000006lmmAAA';
    private static final String TARGET_PRODUCT_ID = '01txx0000006lmuAAA';
    private static final Integer PROMOTION_ADJUSTMENT = -2;
    private static final Integer QUALIFIER_QUANTITY = 5;

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        validateBuyerActionDetailsAndEvaluatePromotion(request.getCart(), request.getOptionalBuyerActionDetails());
    }

	/**
	 * @description Evaluate promotion for cart when OptionalBuyerActionDetails not present or
	 * OptionalBuyerActionDetails includes qualifying/target product.
	 * @param cart In memory representation of the Cart
     * @param optionalBuyerActionDetails The latest set of changes applied to the Cart by the Buyer
	 */
    private void validateBuyerActionDetailsAndEvaluatePromotion(cartextension.Cart cart, cartextension.OptionalBuyerActionDetails optionalBuyerActionDetails) {
        if (!optionalBuyerActionDetails.isPresent() || optionalBuyerActionDetails.get().isCheckoutStarted()) {
            resetAllAdjustments(cart);
            evaluatePromotionForCartItems(cart);
            return;
        }

        List<CartExtension.CartItemChange> cartItemChanges = optionalBuyerActionDetails.get().getCartItemChanges();
        for (CartExtension.CartItemChange cartItemChange : cartItemChanges) {
             CartExtension.OptionalCartItem optionalCartItem = cartItemChange.getChangedItem();
               	if (optionalCartItem.isPresent()) {
                    CartExtension.CartItem cartItem = optionalCartItem.get();
                       	if (cartItem.getProduct2Id() == ID.valueOf(QUALIFIER_PRODUCT_ID) ||
                          	cartItem.getProduct2Id() == ID.valueOf(TARGET_PRODUCT_ID)) {
                        		resetAllAdjustments(cart);
                              	evaluatePromotionForCartItems(cart);
                               	break;
                       	}
                }
        }
    }

    /**
     * @description Remove cart & cart-item level adjustments, cart validation outputs.
     * @param cart Holds details about cart
     */
    private static void resetAllAdjustments(cartextension.Cart cart) {

        // Remove all cart-level adjustments
        Iterator<CartExtension.CartAdjustmentGroup> cagIter = cart.getCartAdjustmentGroups().iterator();
        List<CartExtension.CartAdjustmentGroup> cagToRemove= new List<cartextension.CartAdjustmentGroup>();
        while(cagIter.hasNext()) {
            cagToRemove.add(cagIter.next());
        }
        // Remove CartItemAdjustments
        for(CartExtension.CartAdjustmentGroup cag : cagToRemove) {
            cart.getCartAdjustmentGroups().remove(cag);
        }

        // Remove all cart-item level adjustments
        Iterator<CartExtension.CartItem> cartItemIterator = cart.getCartItems().iterator();
        while(cartItemIterator.hasNext()) {

            // For every cart item, cursor through adjustments
            CartExtension.CartItem ci = cartItemIterator.next();
            Iterator<CartExtension.CartItemPriceAdjustment> ciaIter = ci.getCartItemPriceAdjustments().iterator();
            List<CartExtension.CartItemPriceAdjustment> ciaToRemove= new List<CartExtension.CartItemPriceAdjustment>();

            // For every adjustment, look for a matching external adjustment
            while(ciaIter.hasNext()) {
                ciaToRemove.add(ciaIter.next());
            }
            for(CartExtension.CartItemPriceAdjustment cia : ciaToRemove) {
                 ci.getCartItemPriceAdjustments().remove(cia);
            }
        }

        // Remove promotion cart validation output
        Iterator<CartExtension.CartValidationOutput> cvoIter = cart.getCartValidationOutputs().iterator();
        List<CartExtension.CartValidationOutput> cvoToRemove = new List<CartExtension.CartValidationOutput>();
        while(cvoIter.hasNext()) {
            cvoToRemove.add(cvoIter.next());
        }
        for(CartExtension.CartValidationOutput cvo : cvoToRemove) {
            if (CartExtension.CartValidationOutputTypeEnum.PROMOTIONS == cvo.getType()) {
                cart.getCartValidationOutputs().remove(cvo);
            }
        }
    }



    /**
     * @description Evaluate BOGO promotion (Buy 5 items of qualifying product, get $2 off a unit of target product,
     * for cart items and apply adjustments.
     * @param cart Holds details about cart
     */
    private static void evaluatePromotionForCartItems(CartExtension.Cart cart) {
		Integer targetCount = 0;
        Integer qualifierCount = 0;
    	Integer adjustmentCount = 0;
        Iterator<CartExtension.CartItem> cartItemIterator = cart.getCartItems().iterator();

		// If cartItems size is greater than 0, get qualifier, target count & apply adjustments
    	if(cartItemIterator.hasNext()) {
    		qualifierCount = getProductCount(cart, QUALIFIER_PRODUCT_ID);
    		targetCount = getProductCount(cart, TARGET_PRODUCT_ID);
    		adjustmentCount = qualifierCount / QUALIFIER_QUANTITY;
    		adjustmentCount = Math.min(adjustmentCount, targetCount);
    		applyAdjustments(cart, adjustmentCount);
    	}
    }

    /**
     * @description Helper method to get count of given product in cart.
     * @param cart Holds details about cart
     * @param productId Product Id
     */
    private static Integer getProductCount(CartExtension.Cart cart, String productId) {
		Iterator<CartExtension.CartItem> cartItemIterator = cart.getCartItems().iterator();
        while(cartItemIterator.hasNext()) {
            CartExtension.CartItem ci = cartItemIterator.next();
        	if (ci.getProduct2Id() == ID.valueOf(productId)) {
    			return ci.getQuantity().intValue();
			}
        }
        return 0;
    }

    /**
     * @description Apply $2 off discount on given number of target units
     * @param cart Holds details about cart
     * @param adjustmentCount Number of target units the discount applies to
     */
    private static void applyAdjustments(CartExtension.Cart cart, Integer adjustmentCount) {

        Iterator<CartExtension.CartItem> cartItemIterator = cart.getCartItems().iterator();
        while(cartItemIterator.hasNext() && adjustmentCount > 0) {

            CartExtension.CartItem ci = cartItemIterator.next();
            if(ci.getProduct2Id().equals(TARGET_PRODUCT_ID)) {
                Decimal totalPromotionAdjustment = adjustmentCount * PROMOTION_ADJUSTMENT;
                CartExtension.CartItemPriceAdjustment cia = new
                               CartExtension.CartItemPriceAdjustment(cartextension.CartAdjustmentTargetTypeEnum.ITEM, // AdjustmentTargetType
                                                                     totalPromotionAdjustment, // TotalAmount
                                                                     cartextension.PriceAdjustmentSourceEnum.PROMOTION, // AdjustmentSource
                                                                     cartextension.AdjustmentTypeEnum.ADJUSTMENT_AMOUNT, // AdjustmentType
                                                                     PROMOTION_ADJUSTMENT, // AdjustmentValue
                                                                     DUMMY_PROMOTION_ID); // PriceAdjustmentCauseId
                Decimal totalLineAmount = (ci.getTotalLineAmount() == null) ?
                                            (ci.getSalesPrice() * ci.getQuantity()) : ci.getTotalLineAmount();

                cia.setPriority(1);
                cia.setAdjustmentAmountScope(cartextension.AdjustmentAmountScopeEnum.TOTAL);
                cia.setDescription('PromotionCalculator');
                ci.getCartItemPriceAdjustments().add(cia);

                // Populate TotalPromoAdjustmentAmount for cart-item & update totals based on promotion adjustment
                ci.setTotalPromoAdjustmentAmount(totalPromotionAdjustment);
                ci.setTotalAdjustmentAmount(totalPromotionAdjustment);
                ci.setTotalPriceAfterAllAdjustments(totalLineAmount + totalPromotionAdjustment);
            } else {
            	continue;
            }
        }
    }
}